from django.core.management.base import BaseCommand
from django.db.models import Sum, Q
from django.utils import timezone
from competitions.models import Submission
from leaderboards.models import Leaderboard
from profiles.models import Organization
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

    def handle(self, *args, **options):
        dry_run = options.get('dry_run')
        verbose = options.get('verbose')
        
        if dry_run:
            self.stdout.write(self.style.WARNING('执行干运行模式，不会实际修改数据库'))
        
        # 获取所有有提交的组织
        organizations = Organization.objects.filter(submissions__isnull=False).distinct()
        self.stdout.write(f'找到 {organizations.count()} 个有提交的组织')
        
        total_updated = 0
        
        # 处理每个组织
        for org in organizations:
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
                
                # 获取排行榜的主要评分列
                try:
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
                            
                            total_updated += 1
                        
                        if verbose:
                            self.stdout.write(self.style.SUCCESS(f'    已将提交 ID={best_submission.id} 添加到排行榜'))
                    
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f'处理排行榜 {leaderboard.title} 时出错: {str(e)}'))
        
        if dry_run:
            self.stdout.write(self.style.SUCCESS(f'干运行完成，将会更新 {total_updated} 个提交'))
        else:
            self.stdout.write(self.style.SUCCESS(f'成功更新了 {total_updated} 个提交到排行榜'))
