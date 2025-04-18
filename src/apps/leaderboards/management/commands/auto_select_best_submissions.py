from django.core.management.base import BaseCommand
from django.db.models import Sum, Q
from django.utils import timezone
from competitions.models import Submission
from leaderboards.models import Leaderboard, SubmissionScore
from profiles.models import Organization, User, Membership
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = "自动为每个组织的每个问题选择得分最高的提交显示在排行榜上"

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='只显示将要执行的操作，不实际修改数据库'
        )
        parser.add_argument(
            '--verbose',
            action='store_true',
            help='显示详细的操作信息'
        )
        parser.add_argument(
            '--include-admin-orgs',
            action='store_true',
            help='包括有管理员成员的组织（默认跳过）'
        )
        parser.add_argument(
            '--force-all-columns',
            action='store_true',
            help='强制为每个列选择最佳提交，即使没有主要列的得分'
        )

    def has_admin_members(self, organization):
        """检查组织是否有管理员成员"""
        # 获取组织的所有成员（排除未接受邀请的）
        memberships = Membership.objects.filter(
            organization=organization,
            group__in=Membership.ALL_GROUP  # 排除INVITED状态的成员
        ).select_related('user')

        # 检查是否有任何成员是管理员（is_staff或is_superuser）
        for membership in memberships:
            if membership.user.is_staff or membership.user.is_superuser:
                return True

        return False

    def handle(self, *args, **options):
        dry_run = options.get('dry_run')
        verbose = options.get('verbose')
        include_admin_orgs = options.get('include-admin-orgs')
        force_all_columns = options.get('force-all-columns')

        if dry_run:
            self.stdout.write(self.style.WARNING('执行干运行模式，不会实际修改数据库'))

        # 获取所有有提交的组织
        organizations = Organization.objects.filter(submissions__isnull=False).distinct()
        self.stdout.write(f'找到 {organizations.count()} 个有提交的组织')

        total_updated = 0
        skipped_admin_orgs = 0

        # 处理每个组织
        for org in organizations:
            # 检查组织是否有管理员成员
            if self.has_admin_members(org):
                # 如果组织有管理员成员
                if include_admin_orgs:
                    # 如果指定了包含管理员组织，则正常处理
                    if verbose:
                        self.stdout.write(self.style.WARNING(f'处理包含管理员成员的组织: {org.name}'))
                else:
                    # 默认情况下，移除该组织的所有提交并跳过
                    skipped_admin_orgs += 1

                    # 获取该组织的所有提交
                    admin_org_submissions = Submission.objects.filter(
                        organization=org,
                        leaderboard__isnull=False  # 只处理已经在排行榜上的提交
                    )

                    # 统计要移除的提交数量
                    remove_count = admin_org_submissions.count()

                    if remove_count > 0:
                        if verbose:
                            self.stdout.write(self.style.WARNING(f'从排行榜移除组织 {org.name} 的所有提交 ({remove_count} 个)'))

                        # 从排行榜中移除所有提交
                        if not dry_run:
                            admin_org_submissions.update(leaderboard=None)
                    else:
                        if verbose:
                            self.stdout.write(self.style.WARNING(f'跳过组织: {org.name} (包含管理员成员，无排行榜提交)'))

                    continue

            if verbose:
                self.stdout.write(f'处理组织: {org.name}')

            # 获取该组织的所有已完成的提交
            submissions = Submission.objects.filter(
                organization=org,
                status='Finished'
            ).select_related('phase', 'leaderboard')

            if not submissions.exists():
                if verbose:
                    self.stdout.write(f'  组织 {org.name} 没有已完成的提交')
                continue

            # 按排行榜（问题）分组
            leaderboards = set(sub.phase.leaderboard for sub in submissions if hasattr(sub.phase, 'leaderboard') and sub.phase.leaderboard)

            for leaderboard in leaderboards:
                if verbose:
                    self.stdout.write(f'  处理排行榜: {leaderboard.title}')

                # 获取该组织在该排行榜上的所有提交
                lb_submissions = submissions.filter(phase__leaderboard=leaderboard)

                if not lb_submissions.exists():
                    continue

                # 获取排行榜的所有列
                try:
                    # 获取排行榜的所有列
                    columns = leaderboard.columns.all()

                    # 获取主要评分列
                    primary_col = leaderboard.columns.get(index=leaderboard.primary_index)

                    # 根据主要评分列的排序方式确定排序方向
                    is_desc = primary_col.sorting == 'desc'

                    # 为每个提交计算主要列的得分
                    annotated_submissions = lb_submissions.annotate(
                        primary_col=Sum('scores__score', filter=Q(scores__column=primary_col))
                    )

                    # 根据排序方向选择最佳提交
                    if is_desc:  # 降序，分数越高越好
                        best_submission = annotated_submissions.order_by('-primary_col', 'created_when').first()
                    else:  # 升序，分数越低越好
                        best_submission = annotated_submissions.order_by('primary_col', 'created_when').first()

                    if best_submission:
                        if verbose:
                            self.stdout.write(f'    最佳提交: ID={best_submission.id}, 得分={best_submission.primary_col}')

                        # 从排行榜中移除该组织的所有提交
                        if not dry_run:
                            lb_submissions.update(leaderboard=None)

                            # 将最佳提交添加到排行榜
                            best_submission.leaderboard = leaderboard
                            best_submission.save()

                            # 确保该提交有所有列的得分
                            for column in columns:
                                # 检查该提交是否已有该列的得分
                                score_exists = SubmissionScore.objects.filter(
                                    column=column,
                                    submission__id=best_submission.id
                                ).exists()

                                # 如果没有该列的得分，尝试从该组织的其他提交中找到最佳得分
                                if not score_exists and force_all_columns:
                                    # 获取该组织在该列上的所有得分
                                    column_scores = SubmissionScore.objects.filter(
                                        column=column,
                                        submission__in=lb_submissions
                                    )

                                    if column_scores.exists():
                                        # 根据列的排序方式选择最佳得分
                                        if column.sorting == 'desc':
                                            best_score = column_scores.order_by('-score').first()
                                        else:
                                            best_score = column_scores.order_by('score').first()

                                        if best_score:
                                            # 创建一个新的得分记录，关联到最佳提交
                                            new_score = SubmissionScore.objects.create(
                                                column=column,
                                                score=best_score.score
                                            )
                                            best_submission.scores.add(new_score)

                                            if verbose:
                                                self.stdout.write(f'      为提交 ID={best_submission.id} 添加列 {column.title} 的得分: {best_score.score}')

                            total_updated += 1

                        if verbose:
                            self.stdout.write(self.style.SUCCESS(f'    已将提交 ID={best_submission.id} 添加到排行榜'))

                except Exception as e:
                    self.stdout.write(self.style.ERROR(f'处理排行榜 {leaderboard.title} 时出错: {str(e)}'))

        if dry_run:
            self.stdout.write(self.style.SUCCESS(f'干运行完成，将会更新 {total_updated} 个提交，跳过 {skipped_admin_orgs} 个管理员组织'))
        else:
            self.stdout.write(self.style.SUCCESS(f'成功更新了 {total_updated} 个提交到排行榜，跳过 {skipped_admin_orgs} 个管理员组织'))
