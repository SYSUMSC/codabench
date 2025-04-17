from django.core.management.base import BaseCommand
from django.db.models import Count, Sum, Avg, Min, Max, F, Q, Case, When, IntegerField
from profiles.models import Organization, Membership, User
from competitions.models import Submission
from django.utils import timezone
import csv
import sys
import datetime


class Command(BaseCommand):
    help = "生成组织的详细统计信息"

    def add_arguments(self, parser):
        parser.add_argument(
            '--export',
            type=str,
            help='将结果导出到CSV文件'
        )
        parser.add_argument(
            '--days',
            type=int,
            default=30,
            help='统计最近几天的活跃情况，默认为30天'
        )

    def handle(self, *args, **options):
        export_file = options.get('export')
        days = options.get('days')
        
        # 获取所有组织
        organizations = Organization.objects.all()
        total_orgs = organizations.count()
        
        if total_orgs == 0:
            self.stdout.write(self.style.WARNING('数据库中没有组织！'))
            return

        # 计算日期范围
        today = timezone.now()
        date_from = today - datetime.timedelta(days=days)
        
        # 统计信息
        stats = []
        
        for org in organizations:
            # 基本成员统计
            total_members = org.membership_set.count()
            active_members = org.membership_set.filter(group__in=Membership.ALL_GROUP).count()
            invited_members = org.membership_set.filter(group=Membership.INVITED).count()
            
            # 提交统计
            total_submissions = Submission.objects.filter(organization=org).count()
            recent_submissions = Submission.objects.filter(
                organization=org, 
                created_when__gte=date_from
            ).count()
            
            # 成员角色统计
            owners = org.membership_set.filter(group=Membership.OWNER).count()
            managers = org.membership_set.filter(group=Membership.MANAGER).count()
            participants = org.membership_set.filter(group=Membership.PARTICIPANT).count()
            members = org.membership_set.filter(group=Membership.MEMBER).count()
            
            # 组织年龄（天数）
            age_days = (today - org.date_created).days
            
            stats.append({
                'id': org.id,
                'name': org.name,
                'total_members': total_members,
                'active_members': active_members,
                'invited_members': invited_members,
                'total_submissions': total_submissions,
                'recent_submissions': recent_submissions,
                'owners': owners,
                'managers': managers,
                'participants': participants,
                'members': members,
                'age_days': age_days,
                'date_created': org.date_created
            })
        
        # 计算汇总统计
        total_members = sum(org['total_members'] for org in stats)
        total_active_members = sum(org['active_members'] for org in stats)
        total_submissions = sum(org['total_submissions'] for org in stats)
        total_recent_submissions = sum(org['recent_submissions'] for org in stats)
        
        # 输出汇总信息
        self.stdout.write(self.style.SUCCESS(f'组织总数: {total_orgs}'))
        self.stdout.write(self.style.SUCCESS(f'成员总数: {total_members} (其中活跃成员: {total_active_members})'))
        self.stdout.write(self.style.SUCCESS(f'提交总数: {total_submissions} (最近{days}天: {total_recent_submissions})'))
        
        # 输出详细统计
        self.stdout.write("\n组织详细统计:")
        self.stdout.write("=" * 100)
        header = f"{'ID':<5} {'名称':<25} {'总成员':<8} {'活跃':<8} {'提交':<8} {'最近提交':<8} {'创建日期':<12}"
        self.stdout.write(header)
        self.stdout.write("-" * 100)
        
        # 按活跃成员数排序
        sorted_stats = sorted(stats, key=lambda x: x['active_members'], reverse=True)
        
        for org in sorted_stats:
            row = (
                f"{org['id']:<5} "
                f"{org['name'][:23]:<25} "
                f"{org['total_members']:<8} "
                f"{org['active_members']:<8} "
                f"{org['total_submissions']:<8} "
                f"{org['recent_submissions']:<8} "
                f"{org['date_created'].strftime('%Y-%m-%d'):<12}"
            )
            self.stdout.write(row)
        
        # 导出到CSV
        if export_file:
            try:
                with open(export_file, 'w', newline='') as csvfile:
                    fieldnames = [
                        'id', 'name', 'total_members', 'active_members', 'invited_members',
                        'total_submissions', 'recent_submissions', 'owners', 'managers',
                        'participants', 'members', 'age_days', 'date_created'
                    ]
                    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                    
                    writer.writeheader()
                    for org in stats:
                        # 转换日期格式以便CSV导出
                        org_copy = org.copy()
                        org_copy['date_created'] = org['date_created'].strftime('%Y-%m-%d')
                        writer.writerow(org_copy)
                    
                self.stdout.write(self.style.SUCCESS(f'数据已导出到 {export_file}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'导出失败: {str(e)}'))
