from django.shortcuts import render
from django.db.models import Sum, Max, Avg
from competitions.models import Submission, Competition
from django.apps import apps
from leaderboards.models import Leaderboard
from profiles.models import Membership
from django.core.cache import cache
import json
from datetime import datetime, timedelta
import pytz

def overall_leaderboard(request):
    """
    按组织分组，统计求和每组的每题最高分进行求和，然后按组织排名。
    假设：
      - 只统计提交状态为 Finished 且已上榜（leaderboard 非空）的提交
      - 每个排行榜（题目）内，按组织取最高得分
      - 对每个组织，将其在所有排行榜（题目）中的最高得分求和作为总分
    """
    # 创建缓存键，基于当前时间（精确到分钟）
    # 这样每分钟会生成一个新的缓存键，确保数据每分钟更新一次
    now = datetime.now()
    cache_key = f'overall_leaderboard_{now.strftime("%Y%m%d_%H%M")}'

    # 尝试从缓存中获取数据
    cached_data = cache.get(cache_key)
    if cached_data:
        print(f"Using cached leaderboard data from key: {cache_key}")
        return render(request, 'leaderboards/overall.html', cached_data)

    # 如果缓存中没有数据，则计算新数据
    # 筛选出满足条件的提交，且要求提交所属组织不为空
    submissions = Submission.objects.filter(
        leaderboard__isnull=False,
        status='Finished',
        organization__isnull=False
    ).distinct()

    # 按组织和排行榜（题目）分组，取出每个组织在每个排行榜的最高得分
    # 结构：{ organization_id: { leaderboard_id: best_score, ... }, ... }
    org_leaderboard_scores = {}
    # 记录每个组织在每个排行榜的最佳提交
    # 结构：{ organization_id: { leaderboard_id: submission, ... }, ... }
    org_best_submissions = {}
    # 获取所有排行榜信息，用于后续显示详细得分
    leaderboards = {}

    # 获取所有排行榜及其对应的比赛信息
    for lb in Leaderboard.objects.all():
        # 获取与排行榜相关的阶段
        phase = lb.phases.first()
        competition_title = None
        if phase:
            # 获取阶段所属的比赛标题
            competition_title = phase.competition.title

        leaderboards[lb.id] = {
            'leaderboard': lb,
            'competition_title': competition_title
        }

    for sub in submissions:
        lb_id = sub.leaderboard_id
        org_id = sub.organization_id
        # 这里假设每个提交的得分为其所有 SubmissionScore 的 score 之和
        score = sub.scores.aggregate(total=Sum('score'))['total'] or 0

        # 初始化组织的字典
        if org_id not in org_leaderboard_scores:
            org_leaderboard_scores[org_id] = {}

        # 如果当前排行榜在该组织中不存在，或者当前得分更高，则更新
        if lb_id not in org_leaderboard_scores[org_id] or score > org_leaderboard_scores[org_id][lb_id]:
            org_leaderboard_scores[org_id][lb_id] = score

            # 初始化组织的最佳提交字典
            if org_id not in org_best_submissions:
                org_best_submissions[org_id] = {}

            # 记录该组织在该排行榜的最佳提交
            org_best_submissions[org_id][lb_id] = sub

    # 计算每个组织的总分（所有排行榜最高分的总和）和平均提交时间
    org_total_scores = {}
    org_avg_submission_times = {}

    for org_id, lb_scores in org_leaderboard_scores.items():
        # 对每个组织，将其在所有排行榜中的最高得分求和
        total_score = sum(lb_scores.values())
        org_total_scores[org_id] = total_score

        # 计算该组织的平均提交时间（使用最佳提交的时间）
        if org_id in org_best_submissions:
            best_submissions = org_best_submissions[org_id].values()
            # 提取每个最佳提交的创建时间
            submission_times = [sub.created_when for sub in best_submissions]
            if submission_times:
                # 计算平均提交时间（转换为时间戳以便计算平均值）
                avg_timestamp = sum(dt.timestamp() for dt in submission_times) / len(submission_times)
                # 将平均时间戳转回datetime对象
                org_avg_submission_times[org_id] = datetime.fromtimestamp(avg_timestamp)

    # 获取组织对象
    Organization = apps.get_model('profiles', 'Organization')
    overall_leaderboard_list = []
    for org_id, total_score in org_total_scores.items():
        try:
            organization = Organization.objects.get(id=org_id)
        except Organization.DoesNotExist:
            continue
        # 获取该组织在各个排行榜的得分详情
        detailed_scores = []
        # 获取该组织的所有排行榜得分
        org_scores = org_leaderboard_scores[org_id]
        for lb_id, score in org_scores.items():
            if lb_id in leaderboards:
                lb_info = leaderboards[lb_id]
                # 添加最新提交时间信息
                submission_time = None
                if org_id in org_best_submissions and lb_id in org_best_submissions[org_id]:
                    submission_time = org_best_submissions[org_id][lb_id].created_when

                detailed_scores.append({
                    'leaderboard_id': lb_id,
                    'leaderboard_title': lb_info['leaderboard'].title,
                    'competition_title': lb_info['competition_title'] or '未知比赛',  # 如果没有比赛标题，显示“未知比赛”
                    'score': score,
                    'submission_time': submission_time  # 添加最新提交时间
                })

        # 按排行榜标题排序
        detailed_scores.sort(key=lambda x: x['leaderboard_title'])

        # 获取该组织的活跃成员（排除未接受邀请的）
        active_members = organization.membership_set.filter(
            group__in=Membership.ALL_GROUP  # 排除INVITED状态的成员
        ).select_related('user')

        # 提取成员信息
        members_info = [{
            'name': member.user.name or member.user.username,
            'username': member.user.username,
            'slug': member.user.slug
        } for member in active_members]

        # 获取该组织的平均提交时间
        avg_submission_time = org_avg_submission_times.get(org_id)

        overall_leaderboard_list.append({
            'organization': organization,
            'total_points': total_score,  # 使用总分作为总积分
            'detailed_scores': detailed_scores,  # 添加详细得分信息
            'members': members_info,  # 添加成员信息
            'avg_submission_time': avg_submission_time  # 添加平均提交时间
        })

    # 按总分降序排序，总分相同时按平均提交时间升序排序（越早提交排名越靠前）
    overall_leaderboard_list.sort(key=lambda x: (-x['total_points'], x['avg_submission_time'] if x['avg_submission_time'] else datetime.max))

    # 获取前20名队伍的得分时间线数据
    top_20_orgs = [entry['organization'].id for entry in overall_leaderboard_list[:20]]

    # 设置起始时间：2025年4月18日 12:00
    start_date = datetime(2025, 4, 18, 12, 0, 0)
    # 设置结束时间：2025年4月24日 20:00
    end_date = datetime(2025, 4, 24, 20, 0, 0)
    # 计算实际结束时间（取结束时间和当前时间的较小值）
    actual_end_date = min(end_date, datetime.now())
    # 格式化时间戳
    start_timestamp = start_date.strftime('%Y-%m-%d %H:%M:%S')

    # 获取这些组织的所有已完成且上榜的提交记录，并且只获取起始时间之后、结束时间之前的提交
    timeline_submissions = Submission.objects.filter(
        organization_id__in=top_20_orgs,
        leaderboard__isnull=False,
        status='Finished',
        created_when__gte=start_date,
        created_when__lte=end_date
    ).select_related('organization').order_by('created_when')

    # 按组织和时间分组，记录每个组织随时间的得分变化
    org_timeline_data = {}

    # 初始化每个组织的时间线数据，为每个组织添加起始时间点，初始分数为0
    for org_id in top_20_orgs:
        # 获取该组织的总分，用于调试
        org_entry = next((entry for entry in overall_leaderboard_list if entry['organization'].id == org_id), None)
        org_total_score = org_entry['total_points'] if org_entry else 0

        # 添加起始时间点，初始分数为0
        # 只添加12:00的起始时间点
        org_timeline_data[org_id] = [
            # 起始时间点，分数为0
            {
                'timestamp': start_timestamp,
                'score': 0.0,
                'cumulative_max': 0.0,
                'debug_total_score': float(org_total_score),  # 添加调试信息
                'detailed_scores': [],  # 添加空的小题分数详情
                'is_key_time': False,  # 起始点不是关键时间点
                'total_score': 0.0,  # 起始时总分为0
                'submission_id': None  # 起始时没有提交ID
            }
        ]

    # 为每个组织创建一个字典，用于跟踪每个排行榜（题目）的最高分及其提交时间
    # 结构: {org_id: {leaderboard_id: {'score': score, 'timestamp': timestamp, 'submission_id': sub_id, 'detailed_scores': [...]}}}}
    org_leaderboard_best_scores = {org_id: {} for org_id in top_20_orgs}

    # 按时间排序收集所有提交
    # 为每个组织创建一个列表，用于存储按时间排序的提交记录
    # 结构: {org_id: [{timestamp, submission_id, leaderboard_id, score, detailed_scores}]}
    org_submissions_by_time = {org_id: [] for org_id in top_20_orgs}

    # 收集每个组织的提交时间和得分，使用实际提交时间而不是按小时采样
    for sub in timeline_submissions:
        org_id = sub.organization_id
        leaderboard_id = sub.leaderboard_id
        score = sub.scores.aggregate(total=Sum('score'))['total'] or 0
        # 使用实际提交时间，保留分钟和秒，格式化为 YYYY-MM-DD HH:MM:SS
        timestamp = sub.created_when.strftime('%Y-%m-%d %H:%M:%S')

        # 获取该组织的总分，用于显示在图表中
        org_entry = next((entry for entry in overall_leaderboard_list if entry['organization'].id == org_id), None)
        org_total_score = float(org_entry['total_points']) if org_entry else 0

        # 获取该提交的小题分数详情，用于调试
        detailed_scores = []
        try:
            # 获取所有分数并预加载 column 关系
            all_scores = sub.scores.select_related('column').all()
            print(f"Found {len(all_scores)} scores for submission {sub.id}")

            for score_obj in all_scores:
                try:
                    column_title = score_obj.column.title if hasattr(score_obj.column, 'title') else f'Column {score_obj.column_id}'
                    detailed_scores.append({
                        'column_id': score_obj.column_id,
                        'column_title': column_title,
                        'score': float(score_obj.score)
                    })
                    print(f"Added score for column {column_title}: {float(score_obj.score)}")
                except Exception as e:
                    print(f"Error processing score {score_obj.id}: {str(e)}")
        except Exception as e:
            print(f"Error getting scores for submission {sub.id}: {str(e)}")

        # 计算小题分数之和，确保与总分一致
        submission_score_sum = sum(item['score'] for item in detailed_scores) if detailed_scores else float(score)

        # 将提交记录添加到该组织的时间排序列表中
        org_submissions_by_time[org_id].append({
            'timestamp': timestamp,
            'submission_id': sub.id,
            'leaderboard_id': leaderboard_id,
            'score': float(score),
            'detailed_scores': detailed_scores,
            'total_score': submission_score_sum
        })

        print(f"Submission {sub.id} - Score: {float(score)}, Detailed scores sum: {submission_score_sum}, Org total: {org_total_score}")

    # 为每个组织处理提交记录，按时间排序并计算每个时间点的总分
    for org_id in top_20_orgs:
        # 按时间排序提交记录
        org_submissions_by_time[org_id].sort(key=lambda x: x['timestamp'])

        # 处理每个提交记录，更新最高分并计算总分
        for submission in org_submissions_by_time[org_id]:
            timestamp = submission['timestamp']
            leaderboard_id = submission['leaderboard_id']
            score = submission['score']
            submission_id = submission['submission_id']
            detailed_scores = submission['detailed_scores']

            # 更新该组织在该排行榜的最高分
            if leaderboard_id not in org_leaderboard_best_scores[org_id] or score > org_leaderboard_best_scores[org_id][leaderboard_id]['score']:
                org_leaderboard_best_scores[org_id][leaderboard_id] = {
                    'score': score,
                    'timestamp': timestamp,
                    'submission_id': submission_id,
                    'detailed_scores': detailed_scores
                }

            # 计算当前时间点的总分（所有排行榜最高分的总和）
            total_score = sum(item['score'] for item in org_leaderboard_best_scores[org_id].values())

            # 添加到该组织的时间线数据中
            org_timeline_data[org_id].append({
                'timestamp': timestamp,
                'score': float(score),  # 当前提交的分数，确保是浮点数
                'total_score': float(total_score),  # 所有排行榜最高分的总和，确保是浮点数
                'submission_id': submission_id,  # 添加提交ID以便于追踪
                'detailed_scores': detailed_scores,  # 添加小题分数详情
                'leaderboard_id': leaderboard_id,  # 添加排行榜ID以便于迟踪
                'is_actual_submission': True  # 标记为实际提交点
            })

        # === 补齐所有队伍在所有实际出现过的时间点 ===
        all_actual_timestamps = set()
        for org_id2 in org_timeline_data:
            all_actual_timestamps.update(point['timestamp'] for point in org_timeline_data[org_id2])
        all_actual_timestamps = sorted(all_actual_timestamps)

        for org_id2 in org_timeline_data:
            timeline = org_timeline_data[org_id2]
            time2point = {point['timestamp']: point for point in timeline}
            filled_timeline = []
            last_point = None
            for ts in all_actual_timestamps:
                if ts in time2point:
                    last_point = time2point[ts]
                    filled_timeline.append(last_point)
                elif last_point is not None:
                    clone_point = last_point.copy()
                    clone_point['timestamp'] = ts
                    clone_point['is_actual_submission'] = False
                    filled_timeline.append(clone_point)
            org_timeline_data[org_id2] = filled_timeline
        # === 补齐结束 ===
    # 为每个组织处理时间线数据，按小时插入数据点
    for org_id in org_timeline_data:
        # 按时间排序
        org_timeline_data[org_id].sort(key=lambda x: x['timestamp'])

        processed_data = []

        # 处理每个提交时间点
        for i, point in enumerate(org_timeline_data[org_id]):
            # 如果是起始点（分数为0），直接添加
            if i == 0 and 'debug_total_score' in point:
                processed_data.append(point)
                continue

            # 获取小题分数详情
            detailed_scores = point.get('detailed_scores', [])

            # 使用total_score作为累计最高分
            # total_score已经在前面的处理中计算为所有排行榜最高分的总和
            total_score = point.get('total_score', 0)

            # 添加到处理后的数据中，包含当前提交分数和累计总分
            processed_data.append({
                'timestamp': point['timestamp'],
                'score': point['score'],  # 当前提交的分数
                'cumulative_max': total_score,  # 使用total_score作为累计最高分
                'submission_id': point.get('submission_id', None),
                'detailed_scores': detailed_scores,  # 保留小题分数详情
                'is_key_time': point.get('is_key_time', False),  # 保留关键时间点标记
                'total_score': total_score,  # 使用total_score作为总分
                'leaderboard_id': point.get('leaderboard_id', None)  # 保留排行榜ID
            })

        # 替换原始数据
        org_timeline_data[org_id] = processed_data

        # 确保时间线连续，按小时添加数据点，同时保留所有实际提交时间点
        if len(org_timeline_data[org_id]) > 0:
            filled_data = []

            # 获取第一个点和最后一个点的时间
            first_point = org_timeline_data[org_id][0]
            last_point = org_timeline_data[org_id][-1]

            first_time = datetime.strptime(first_point['timestamp'], '%Y-%m-%d %H:%M:%S')
            last_time = datetime.strptime(last_point['timestamp'], '%Y-%m-%d %H:%M:%S')

            start_time = min(first_time, datetime(2025, 4, 18, 11, 0, 0))
            end_time = max(last_time, min(datetime(2025, 4, 24, 20, 0, 0), datetime.now()))

            start_hour = datetime(start_time.year, start_time.month, start_time.day, start_time.hour, 0, 0)
            if end_time.minute > 0 or end_time.second > 0:
                end_hour = datetime(end_time.year, end_time.month, end_time.day, end_time.hour, 0, 0) + timedelta(hours=1)
            else:
                end_hour = datetime(end_time.year, end_time.month, end_time.day, end_time.hour, 0, 0)

            # 关键时间点
            key_times = [
                datetime(2025, 4, 18, 11, 0, 0),
                datetime(2025, 4, 18, 12, 0, 0),
                datetime(2025, 4, 24, 20, 0, 0)
            ]

            # 构建实际提交点的map
            actual_point_map = {point['timestamp']: point for point in org_timeline_data[org_id]}
            all_actual_timestamps = set(actual_point_map.keys())

            # 先添加起始点
            if 'debug_total_score' in first_point:
                filled_data.append(first_point)

            # 生成每小时插值点
            current_hour = start_hour
            last_point_data = None
            while current_hour <= end_hour:
                current_hour_str = current_hour.strftime('%Y-%m-%d %H:%M:%S')
                # 如果该小时有实际提交点，跳过（实际点后面会统一合并，且优先）
                if current_hour_str in all_actual_timestamps:
                    current_hour += timedelta(hours=1)
                    continue

                # 找到最近的前一个实际点
                prev_time = None
                for ts in sorted(all_actual_timestamps):
                    if ts < current_hour_str:
                        prev_time = ts
                    else:
                        break

                if prev_time:
                    prev_point = actual_point_map[prev_time]
                    detailed_scores = prev_point.get('detailed_scores', [])
                    total_score = prev_point.get('total_score', 0)
                    new_point = {
                        'timestamp': current_hour_str,
                        'score': prev_point.get('score', 0),
                        'cumulative_max': prev_point.get('cumulative_max', 0),
                        'is_key_time': current_hour in key_times,
                        'detailed_scores': detailed_scores,
                        'total_score': total_score,
                        'submission_id': None,
                        'is_hourly_point': True
                    }
                    filled_data.append(new_point)
                    last_point_data = new_point
                elif last_point_data:
                    new_point = {
                        'timestamp': current_hour_str,
                        'score': last_point_data.get('score', 0),
                        'cumulative_max': last_point_data.get('cumulative_max', 0),
                        'is_key_time': current_hour in key_times,
                        'detailed_scores': last_point_data.get('detailed_scores', []),
                        'total_score': last_point_data.get('total_score', 0),
                        'submission_id': None,
                        'is_hourly_point': True
                    }
                    filled_data.append(new_point)
                else:
                    new_point = {
                        'timestamp': current_hour_str,
                        'score': 0,
                        'cumulative_max': 0,
                        'is_key_time': current_hour in key_times,
                        'detailed_scores': [],
                        'total_score': 0,
                        'submission_id': None,
                        'is_hourly_point': True
                    }
                    filled_data.append(new_point)
                    last_point_data = new_point

                current_hour += timedelta(hours=1)

            # 合并所有实际提交点和插值点，实际提交点优先
            all_points_map = {point['timestamp']: point for point in filled_data}
            # 用实际提交点覆盖插值点
            for ts, point in actual_point_map.items():
                all_points_map[ts] = point
            # 按时间排序
            merged_points = [all_points_map[ts] for ts in sorted(all_points_map.keys())]
            org_timeline_data[org_id] = merged_points

        # 确保所有点都有cumulative_max属性
        # 注意：在前面的处理中，我们已经计算了cumulative_max，这里只是确保所有点都有该属性
        for point in org_timeline_data[org_id]:
            if 'cumulative_max' not in point:
                if 'score' in point:
                    point['cumulative_max'] = point['score']
                else:
                    point['cumulative_max'] = 0

        # 确保有足够的数据点来形成连续的线条
        # 如果只有一个数据点，添加关键时间点
        if len(org_timeline_data[org_id]) == 1:
            point = org_timeline_data[org_id][0]
            # 添加比赛结束时间点
            end_time = datetime(2025, 4, 24, 20, 0, 0)

            # 确保结束时间点在当前点之后
            current_time = datetime.strptime(point['timestamp'], '%Y-%m-%d %H:%M:%S')
            if current_time < end_time:
                detailed_scores = point.get('detailed_scores', [])
                # 计算小题分数之和
                total_score = sum(item['score'] for item in detailed_scores) if detailed_scores else point.get('score', 0)

                org_timeline_data[org_id].append({
                    'timestamp': end_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'score': point.get('cumulative_max', point.get('score', 0)),
                    'cumulative_max': point.get('cumulative_max', point.get('score', 0)),
                    'is_key_time': True,
                    'detailed_scores': detailed_scores,  # 保留小题分数详情
                    'total_score': total_score,  # 使用小题分数之和作为总分
                    'submission_id': None  # 关键时间点没有提交ID
                })
            # 如果当前点已经在结束时间之后，添加一个小时后的点
            else:
                new_time = current_time + timedelta(hours=1)
                detailed_scores = point.get('detailed_scores', [])
                # 计算小题分数之和
                total_score = sum(item['score'] for item in detailed_scores) if detailed_scores else point.get('score', 0)

                org_timeline_data[org_id].append({
                    'timestamp': new_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'score': point.get('cumulative_max', point.get('score', 0)),
                    'cumulative_max': point.get('cumulative_max', point.get('score', 0)),
                    'detailed_scores': detailed_scores,  # 保留小题分数详情
                    'is_key_time': False,  # 不是关键时间点
                    'total_score': total_score,  # 使用小题分数之和作为总分
                    'submission_id': None  # 没有提交ID
                })

        # 确保数据包含到结束时间的数据点，使图表显示完整数据
        if len(org_timeline_data[org_id]) > 0:
            # 获取该组织的总分
            org_entry = next((entry for entry in overall_leaderboard_list if entry['organization'].id == org_id), None)
            org_total_score = float(org_entry['total_points']) if org_entry else 0

            # 获取最后一个点的时间
            last_point = org_timeline_data[org_id][-1]
            last_time = datetime.strptime(last_point['timestamp'], '%Y-%m-%d %H:%M:%S')

            # 使用实际结束时间作为图表的结束时间
            chart_end_time = actual_end_date

            # 如果最后一个点的时间早于结束时间，添加结束时间点
            if last_time < chart_end_time:
                # 直接添加结束时间点，不需要每小时填充
                detailed_scores = last_point.get('detailed_scores', [])
                # 计算小题分数之和
                total_score = sum(item['score'] for item in detailed_scores) if detailed_scores else last_point.get('score', 0)

                org_timeline_data[org_id].append({
                    'timestamp': chart_end_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'score': last_point.get('score', 0),
                    'cumulative_max': last_point.get('cumulative_max', 0),
                    'total_score': total_score,  # 使用小题分数之和作为总分
                    'is_key_time': True,  # 标记为关键时间点
                    'detailed_scores': detailed_scores  # 保留前一个点的小题分数详情
                })

    # 准备图表数据
    chart_data = {
        'labels': [],  # 时间标签
        'datasets': []  # 每个组织的数据集
    }

    # 为前20名队伍创建数据集
    for i, entry in enumerate(overall_leaderboard_list[:20]):
        org_id = entry['organization'].id
        org_name = entry['organization'].name

        # 如果该组织有时间线数据
        if org_timeline_data[org_id]:
            # 创建该组织的数据集，增强数据点信息
            dataset = {
                'label': org_name,
                # 增强数据点信息，包含实际得分和累计最高分
                'data': [
                    {
                        'x': point['timestamp'],  # 实际时间点
                        'y': float(point.get('cumulative_max', 0)),  # 使用累计总分作为图表显示值
                        'submission_id': point.get('submission_id', None),  # 提交ID
                        'is_key_time': point.get('is_key_time', False),  # 是否为关键时间点
                        'total_score': float(point.get('total_score', 0)),  # 当前提交的总分（小题分数之和）
                        'detailed_scores': point.get('detailed_scores', [])  # 小题分数数组，用于调试
                    } for point in org_timeline_data[org_id]
                ],
                'borderColor': f'hsl({(i * 36) % 360}, 70%, 50%)',  # 使用HSL颜色空间生成不同颜色
                'backgroundColor': f'hsla({(i * 36) % 360}, 70%, 50%, 0.1)',
                'fill': False,
                'tension': 0.3,  # 线条平滑度
                'showLine': True,  # 显示线条
                'pointRadius': 3,  # 数据点半径
                'pointHoverRadius': 6,  # 鼠标悬停时数据点半径
                'pointStyle': 'circle'  # 数据点样式
            }
            chart_data['datasets'].append(dataset)

    # 将实际结束时间添加到上下文中
    context = {
        'leaderboard_list': overall_leaderboard_list,
        'chart_data': json.dumps(chart_data),
        'actual_end_date': actual_end_date.strftime('%Y-%m-%d %H:%M:%S'),
        'show_avg_submission_time': False  # 添加标志以便模板可以显示平均提交时间
    }

    # 将计算结果缓存60秒
    cache.set(cache_key, context, 60)
    print(f"Cached leaderboard data with key: {cache_key}, TTL: 60 seconds")

    return render(request, 'leaderboards/overall.html', context)