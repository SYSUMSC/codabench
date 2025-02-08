from django.shortcuts import render
from competitions.models import Submission
from django.db.models import Sum
from django.contrib.auth import get_user_model

def leaderboard_list(request):
    # 获取所有已上榜且状态为 Finished 的提交，并计算每个提交的总得分
    submissions = Submission.objects.filter(
        leaderboard__isnull=False,
        status='Finished'
    ).annotate(
        overall_score=Sum('scores__score')
    )

    # 分组：按用户和比赛（通过 leaderboard_id）分组，取每个用户在每个比赛中的最高得分
    best_scores = {}
    for sub in submissions:
        key = (sub.owner_id, sub.leaderboard_id)
        score = sub.overall_score or 0
        if key not in best_scores or score > best_scores[key]:
            best_scores[key] = score

    # 按用户汇总各比赛的得分
    user_totals = {}
    for (owner_id, _), score in best_scores.items():
        user_totals[owner_id] = user_totals.get(owner_id, 0) + score

    # 构造排行榜列表（包含用户对象及总得分）
    User = get_user_model()
    leaderboard_list = []
    for user_id, total in user_totals.items():
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            continue
        leaderboard_list.append({
            'user': user,
            'total_score': total
        })

    # 按总得分降序排序
    leaderboard_list.sort(key=lambda x: x['total_score'], reverse=True)

    context = {'leaderboard_list': leaderboard_list}
    return render(request, 'leaderboards/index.html', context)
