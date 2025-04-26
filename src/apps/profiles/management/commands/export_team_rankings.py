from django.core.management.base import BaseCommand
from django.db.models import Sum, Q
from django.apps import apps
from django.utils.timezone import now
from datetime import datetime
import csv
import os

from competitions.models import Submission
from profiles.models import Organization, Membership
from solutions.models import SolutionPDF


class Command(BaseCommand):
    help = "导出前60名队伍排名到CSV文件"

    def add_arguments(self, parser):
        parser.add_argument(
            '--export',
            type=str,
            default='/tmp/team_rankings.csv',
            help='将结果导出到CSV文件'
        )

    def handle(self, *args, **options):
        export_file = options.get('export')

        # 计算队伍排名，参考overall_leaderboard的逻辑
        self.stdout.write("正在计算队伍排名...")

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
        Leaderboard = apps.get_model('leaderboards', 'Leaderboard')
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

        # 计算每个组织的总分
        org_total_scores = {}
        # 记录每个组织的平均提交时间（用于排名时的平局处理）
        org_avg_submission_times = {}

        for org_id, scores in org_leaderboard_scores.items():
            # 计算总分
            total_score = sum(scores.values())
            org_total_scores[org_id] = total_score

            # 计算平均提交时间
            submission_times = []
            for lb_id, sub in org_best_submissions.get(org_id, {}).items():
                submission_times.append(sub.created_when)

            if submission_times:
                # 计算平均提交时间
                avg_time = sum((t.timestamp() for t in submission_times)) / len(submission_times)
                avg_datetime = datetime.fromtimestamp(avg_time)
                org_avg_submission_times[org_id] = avg_datetime

        # 获取组织对象
        overall_leaderboard_list = []
        for org_id, total_score in org_total_scores.items():
            try:
                organization = Organization.objects.get(id=org_id)
            except Organization.DoesNotExist:
                continue

            # 获取组织成员信息
            members = []
            for membership in organization.membership_set.filter(group__in=Membership.ALL_GROUP).order_by('date_joined'):
                user = membership.user
                members.append({
                    'username': user.username,
                    'real_name': user.real_name or '',
                    'student_id': user.student_id or '',
                    'role': membership.group
                })

            # 获取该组织的平均提交时间
            avg_submission_time = org_avg_submission_times.get(org_id)

            overall_leaderboard_list.append({
                'organization': organization,
                'total_points': total_score,  # 使用总分作为总积分
                'members': members,  # 添加成员信息
                'avg_submission_time': avg_submission_time  # 添加平均提交时间
            })

        # 按总分降序排序，总分相同时按平均提交时间升序排序（越早提交排名越靠前）
        overall_leaderboard_list.sort(key=lambda x: (-x['total_points'], x['avg_submission_time'] if x['avg_submission_time'] else datetime.max))

        # 只取前60名
        top_60_teams = overall_leaderboard_list[:60]

        # 导出到CSV
        try:
            with open(export_file, 'w', newline='', encoding='utf-8') as csvfile:
                # 定义CSV字段
                fieldnames = [
                    '队伍名次', '队伍名字',
                    '成员1姓名', '成员1学号',
                    '成员2姓名', '成员2学号',
                    '成员3姓名', '成员3学号',
                    '队伍积分', '提交wp文件名字'
                ]

                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()

                # 写入每个队伍的数据
                for rank, team in enumerate(top_60_teams, 1):
                    org = team['organization']
                    members = team['members']

                    # 准备成员数据
                    member_data = {}
                    for i, member in enumerate(members[:3], 1):  # 最多取3个成员
                        member_data[f'成员{i}姓名'] = member['real_name']
                        member_data[f'成员{i}学号'] = member['student_id']

                    # 确保所有成员字段都存在，即使队伍成员不足3人
                    for i in range(1, 4):
                        if f'成员{i}姓名' not in member_data:
                            member_data[f'成员{i}姓名'] = ''
                        if f'成员{i}学号' not in member_data:
                            member_data[f'成员{i}学号'] = ''

                    # 获取队伍的题解PDF文件名
                    solution_pdf = SolutionPDF.objects.filter(
                        organization=org,
                        upload_completed_successfully=True
                    ).first()

                    solution_filename = "无"
                    if solution_pdf and solution_pdf.pdf_file:
                        # 从完整路径中提取文件名
                        solution_filename = os.path.basename(solution_pdf.pdf_file.name)

                    # 写入一行数据
                    row_data = {
                        '队伍名次': rank,
                        '队伍名字': org.name,
                        '队伍积分': team['total_points'],
                        '提交wp文件名字': solution_filename,
                        **member_data
                    }
                    writer.writerow(row_data)

            self.stdout.write(self.style.SUCCESS(f'\n数据已导出到 {export_file}'))

            # 提供访问文件的命令
            if export_file.startswith('/tmp/'):
                self.stdout.write(self.style.SUCCESS(
                    f'\n文件已导出到容器的 {export_file}，'
                    f'您可以通过以下命令将其内容输出并保存到宿主机：\n'
                    f'docker compose exec django cat {export_file} > team_rankings.csv'
                ))

        except Exception as e:
            self.stdout.write(self.style.ERROR(f'\n导出失败: {str(e)}'))
