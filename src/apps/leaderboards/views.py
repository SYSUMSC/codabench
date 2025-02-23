from django.shortcuts import render
from django.db.models import Sum
from competitions.models import Submission
from django.apps import apps

def overall_leaderboard(request):
    """
    统计所有排行榜中各队伍获得的积分，并按总积分排名。
    假设：
      - 只统计提交状态为 Finished 且已上榜（leaderboard 非空）的提交
      - 每个排行榜内，按队伍取最佳提交得分进行排名
      - 每个排行榜总积分为 100，按照等差数列分配
    """
    # 筛选出满足条件的提交，且要求提交所属队伍不为空
    submissions = Submission.objects.filter(
        leaderboard__isnull=False,
        status='Finished',
        organization__isnull=False
    ).distinct()

    # 按排行榜和队伍分组，取出每个队伍在每个排行榜的最高得分
    # 结构：{ leaderboard_id: { organization_id: best_score, ... }, ... }
    leaderboard_org_scores = {}
    for sub in submissions:
        lb_id = sub.leaderboard_id
        org_id = sub.organization_id
        # 这里假设每个提交的得分为其所有 SubmissionScore 的 score 之和
        score = sub.scores.aggregate(total=Sum('score'))['total'] or 0
        if lb_id not in leaderboard_org_scores:
            leaderboard_org_scores[lb_id] = {}
        # 如果当前队伍已经存在，则保留更高的得分
        if org_id not in leaderboard_org_scores[lb_id] or score > leaderboard_org_scores[lb_id][org_id]:
            leaderboard_org_scores[lb_id][org_id] = score

    # 根据每个排行榜内队伍的得分进行排名，并分配积分（总积分 100）
    # 最后将各排行榜中的积分累计到各队伍上
    org_total_points = {}  # { organization_id: total_points }
    for lb_id, org_scores in leaderboard_org_scores.items():
        # 按得分降序排序，得分高者排名靠前
        sorted_orgs = sorted(org_scores.items(), key=lambda x: x[1], reverse=True)
        n = len(sorted_orgs)
        if n == 0:
            continue
        total_factor = n * (n + 1) / 2  # 等差数列的分母：1+2+...+n
        for rank, (org_id, _) in enumerate(sorted_orgs, start=1):
            points = (n - rank + 1) / total_factor * 100
            org_total_points[org_id] = org_total_points.get(org_id, 0) + points

    # 获取队伍对象。这里假设队伍模型为 Organization，且在 app "profiles" 下
    Organization = apps.get_model('profiles', 'Organization')
    overall_leaderboard_list = []
    for org_id, points in org_total_points.items():
        try:
            organization = Organization.objects.get(id=org_id)
        except Organization.DoesNotExist:
            continue
        overall_leaderboard_list.append({
            'organization': organization,
            'total_points': points,
        })

    # 按总积分降序排序
    overall_leaderboard_list.sort(key=lambda x: x['total_points'], reverse=True)

    context = {
        'leaderboard_list': overall_leaderboard_list,
    }
    return render(request, 'leaderboards/overall.html', context)
