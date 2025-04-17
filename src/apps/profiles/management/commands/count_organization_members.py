from django.core.management.base import BaseCommand
from django.db.models import Count, Sum, Avg, Min, Max, F, Q
from profiles.models import Organization, Membership
from django.utils import timezone
import csv
import sys


class Command(BaseCommand):
    help = "统计数据库中所有组织的成员数量"

    def add_arguments(self, parser):
        parser.add_argument(
            '--detail',
            action='store_true',
            help='显示详细的组织成员信息'
        )
        parser.add_argument(
            '--export',
            type=str,
            help='将结果导出到CSV文件'
        )
        parser.add_argument(
            '--active-only',
            action='store_true',
            help='只统计已接受邀请的成员（排除INVITED状态的成员）'
        )

    def handle(self, *args, **options):
        detail = options.get('detail')
        export_file = options.get('export')
        active_only = options.get('active_only')

        # 获取所有组织
        organizations = Organization.objects.all()
        total_orgs = organizations.count()
        
        if total_orgs == 0:
            self.stdout.write(self.style.WARNING('数据库中没有组织！'))
            return

        # 准备查询条件
        membership_filter = {}
        if active_only:
            membership_filter['group__in'] = Membership.ALL_GROUP  # 排除INVITED状态的成员

        # 统计每个组织的成员数量
        org_members = []
        total_members = 0
        
        for org in organizations:
            member_count = org.membership_set.filter(**membership_filter).count()
            total_members += member_count
            org_members.append({
                'id': org.id,
                'name': org.name,
                'member_count': member_count,
                'date_created': org.date_created
            })

        # 计算统计信息
        avg_members = total_members / total_orgs
        
        # 输出结果
        self.stdout.write(self.style.SUCCESS(f'组织总数: {total_orgs}'))
        self.stdout.write(self.style.SUCCESS(f'成员总数: {total_members}'))
        self.stdout.write(self.style.SUCCESS(f'平均每个组织的成员数: {avg_members:.2f}'))
        
        if detail:
            self.stdout.write("\n组织详情:")
            self.stdout.write("=" * 60)
            self.stdout.write(f"{'ID':<5} {'名称':<30} {'成员数':<10} {'创建日期'}")
            self.stdout.write("-" * 60)
            
            # 按成员数量排序
            sorted_orgs = sorted(org_members, key=lambda x: x['member_count'], reverse=True)
            
            for org in sorted_orgs:
                self.stdout.write(
                    f"{org['id']:<5} {org['name'][:28]:<30} {org['member_count']:<10} {org['date_created'].strftime('%Y-%m-%d')}"
                )
        
        # 导出到CSV
        if export_file:
            try:
                with open(export_file, 'w', newline='') as csvfile:
                    fieldnames = ['id', 'name', 'member_count', 'date_created']
                    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                    
                    writer.writeheader()
                    for org in org_members:
                        # 转换日期格式以便CSV导出
                        org_copy = org.copy()
                        org_copy['date_created'] = org['date_created'].strftime('%Y-%m-%d')
                        writer.writerow(org_copy)
                    
                self.stdout.write(self.style.SUCCESS(f'数据已导出到 {export_file}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'导出失败: {str(e)}'))
