from django.shortcuts import render
from django.db.models import Sum, Max
from competitions.models import Submission, Competition
from django.apps import apps
from leaderboards.models import Leaderboard
from profiles.models import Membership
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
    # 筛选出满足条件的提交，且要求提交所属组织不为空
    submissions = Submission.objects.filter(
        leaderboard__isnull=False,
        status='Finished',
        organization__isnull=False
    ).distinct()

    # 按组织和排行榜（题目）分组，取出每个组织在每个排行榜的最高得分
    # 结构：{ organization_id: { leaderboard_id: best_score, ... }, ... }
    org_leaderboard_scores = {}
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

    # 计算每个组织的总分（所有排行榜最高分的总和）
    org_total_scores = {}
    for org_id, lb_scores in org_leaderboard_scores.items():
        # 对每个组织，将其在所有排行榜中的最高得分求和
        total_score = sum(lb_scores.values())
        org_total_scores[org_id] = total_score

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
                detailed_scores.append({
                    'leaderboard_id': lb_id,
                    'leaderboard_title': lb_info['leaderboard'].title,
                    'competition_title': lb_info['competition_title'] or '未知比赛',  # 如果没有比赛标题，显示“未知比赛”
                    'score': score
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

        overall_leaderboard_list.append({
            'organization': organization,
            'total_points': total_score,  # 使用总分作为总积分
            'detailed_scores': detailed_scores,  # 添加详细得分信息
            'members': members_info  # 添加成员信息
        })

    # 按总分降序排序
    overall_leaderboard_list.sort(key=lambda x: x['total_points'], reverse=True)

    # 获取前10名队伍的得分时间线数据
    top_10_orgs = [entry['organization'].id for entry in overall_leaderboard_list[:10]]

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
        organization_id__in=top_10_orgs,
        leaderboard__isnull=False,
        status='Finished',
        created_when__gte=start_date,
        created_when__lte=end_date
    ).select_related('organization').order_by('created_when')

    # 按组织和时间分组，记录每个组织随时间的得分变化
    org_timeline_data = {}

    # 初始化每个组织的时间线数据，为每个组织添加起始时间点，初始分数为0
    for org_id in top_10_orgs:
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
                'debug_total_score': float(org_total_score)  # 添加调试信息
            }
        ]

    # 收集每个组织的提交时间和得分
    for sub in timeline_submissions:
        org_id = sub.organization_id
        score = sub.scores.aggregate(total=Sum('score'))['total'] or 0
        # 保留小时信息，格式化为 YYYY-MM-DD HH:00:00
        timestamp = sub.created_when.replace(minute=0, second=0, microsecond=0).strftime('%Y-%m-%d %H:%M:%S')

        # 添加到该组织的时间线数据中
        org_timeline_data[org_id].append({
            'timestamp': timestamp,
            'score': float(score)
        })

    # 为每个组织按小时分组并计算每小时的最高分
    for org_id in org_timeline_data:
        # 按时间排序
        org_timeline_data[org_id].sort(key=lambda x: x['timestamp'])

        # 按小时分组并计算每小时的最高分
        hourly_data = {}
        for point in org_timeline_data[org_id]:
            hour_key = point['timestamp']  # 已经格式化为整点小时
            if hour_key not in hourly_data or point['score'] > hourly_data[hour_key]['score']:
                hourly_data[hour_key] = {
                    'timestamp': hour_key,
                    'score': point['score']
                }

        # 将小时数据转换回列表并按时间排序
        org_timeline_data[org_id] = list(hourly_data.values())
        org_timeline_data[org_id].sort(key=lambda x: x['timestamp'])

        # 填充缺失的小时数据点，确保时间线连续
        if len(org_timeline_data[org_id]) > 1:
            filled_data = [org_timeline_data[org_id][0]]  # 从第一个点开始

            for i in range(1, len(org_timeline_data[org_id])):
                current_point = org_timeline_data[org_id][i]
                prev_point = org_timeline_data[org_id][i-1]

                # 计算当前点和前一个点之间的时间差
                current_time = datetime.strptime(current_point['timestamp'], '%Y-%m-%d %H:%M:%S')
                prev_time = datetime.strptime(prev_point['timestamp'], '%Y-%m-%d %H:%M:%S')
                hour_diff = int((current_time - prev_time).total_seconds() / 3600)

                # 如果时间差大于1小时，填充中间的小时数据点
                if hour_diff > 1:
                    for h in range(1, hour_diff):
                        fill_time = prev_time + timedelta(hours=h)
                        fill_timestamp = fill_time.strftime('%Y-%m-%d %H:%M:%S')
                        filled_data.append({
                            'timestamp': fill_timestamp,
                            'score': prev_point['score']  # 使用前一个点的分数
                        })

                filled_data.append(current_point)

            org_timeline_data[org_id] = filled_data

        # 计算累计最高分
        current_max = 0
        for point in org_timeline_data[org_id]:
            if point['score'] > current_max:
                current_max = point['score']
            point['cumulative_max'] = current_max

        # 确保有足够的数据点来形成连续的线条
        # 如果只有一个数据点，复制该点以形成线条
        if len(org_timeline_data[org_id]) == 1:
            point = org_timeline_data[org_id][0]
            # 复制该点，并将时间向后移动一小时
            timestamp = datetime.strptime(point['timestamp'], '%Y-%m-%d %H:%M:%S')
            new_timestamp = (timestamp + timedelta(hours=1)).strftime('%Y-%m-%d %H:%M:%S')

            org_timeline_data[org_id].append({
                'timestamp': new_timestamp,
                'score': point['score'],
                'cumulative_max': point['cumulative_max']
            })

        # 确保数据包含到结束时间的数据点，使图表显示完整数据
        if len(org_timeline_data[org_id]) > 0:
            # 获取该组织的总分，用于添加最终得分点
            org_entry = next((entry for entry in overall_leaderboard_list if entry['organization'].id == org_id), None)
            org_total_score = float(org_entry['total_points']) if org_entry else 0

            # 获取最后一个点的时间和分数
            last_point = org_timeline_data[org_id][-1]
            last_time = datetime.strptime(last_point['timestamp'], '%Y-%m-%d %H:%M:%S')
            last_score = last_point.get('cumulative_max', last_point.get('score', 0))

            # 使用实际结束时间作为图表的结束时间
            chart_end_time = actual_end_date.replace(minute=0, second=0, microsecond=0)

            # 填充从最后一个点到结束时间的所有小时数据点
            current_time = last_time
            while current_time < chart_end_time:
                # 向前移动一小时
                current_time = current_time + timedelta(hours=1)
                # 确保不超过结束时间
                if current_time <= chart_end_time:
                    timestamp = current_time.strftime('%Y-%m-%d %H:%M:%S')
                    org_timeline_data[org_id].append({
                        'timestamp': timestamp,
                        'score': last_score,
                        'cumulative_max': last_score
                    })

            # 确保最后一个点是结束时间点
            if org_timeline_data[org_id][-1]['timestamp'] != chart_end_time.strftime('%Y-%m-%d %H:%M:%S'):
                org_timeline_data[org_id].append({
                    'timestamp': chart_end_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'score': last_score,
                    'cumulative_max': last_score
                })

    # 准备图表数据
    chart_data = {
        'labels': [],  # 时间标签
        'datasets': []  # 每个组织的数据集
    }

    # 为前10名队伍创建数据集
    for i, entry in enumerate(overall_leaderboard_list[:10]):
        org_id = entry['organization'].id
        org_name = entry['organization'].name

        # 如果该组织有时间线数据
        if org_timeline_data[org_id]:
            # 创建该组织的数据集
            dataset = {
                'label': org_name,
                # 确保分数数据是浮点数并且有效
                'data': [{'x': point['timestamp'], 'y': float(point['cumulative_max'] or 0)} for point in org_timeline_data[org_id]],
                'borderColor': f'hsl({(i * 36) % 360}, 70%, 50%)',  # 使用HSL颜色空间生成不同颜色
                'backgroundColor': f'hsla({(i * 36) % 360}, 70%, 50%, 0.1)',
                'fill': False,
                'tension': 0.4,  # 使线条更平滑
                'showLine': True,  # 显示线条
                'pointRadius': 4,  # 数据点半径
                'pointHoverRadius': 6,  # 鼠标悬停时数据点半径
                'lineTension': 0.3  # 线条张力（平滑度）
            }
            chart_data['datasets'].append(dataset)

    # 将实际结束时间添加到上下文中
    context = {
        'leaderboard_list': overall_leaderboard_list,
        'chart_data': json.dumps(chart_data),
        'actual_end_date': actual_end_date.strftime('%Y-%m-%d %H:%M:%S')
    }
    return render(request, 'leaderboards/overall.html', context)
