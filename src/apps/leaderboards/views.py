from django.shortcuts import render
from django.db.models import Sum
from competitions.models import Submission
from django.apps import apps

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
        overall_leaderboard_list.append({
            'organization': organization,
            'total_points': total_score,  # 使用总分作为总积分
        })

    # 按总分降序排序
    overall_leaderboard_list.sort(key=lambda x: x['total_points'], reverse=True)

    context = {
        'leaderboard_list': overall_leaderboard_list,
    }
    return render(request, 'leaderboards/overall.html', context)
