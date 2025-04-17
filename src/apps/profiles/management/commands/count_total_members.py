from django.core.management.base import BaseCommand
from django.db.models import Count, Sum
from profiles.models import Organization, Membership


class Command(BaseCommand):
    help = "快速统计数据库中所有组织的成员总数"

    def add_arguments(self, parser):
        parser.add_argument(
            '--active-only',
            action='store_true',
            help='只统计已接受邀请的成员（排除INVITED状态的成员）'
        )

    def handle(self, *args, **options):
        active_only = options.get('active_only')

        # 准备查询条件
        if active_only:
            # 只统计已接受邀请的成员
            total_members = Membership.objects.filter(group__in=Membership.ALL_GROUP).count()
            self.stdout.write(self.style.SUCCESS(f'已接受邀请的成员总数: {total_members}'))
        else:
            # 统计所有成员（包括未接受邀请的）
            total_members = Membership.objects.count()
            invited_members = Membership.objects.filter(group=Membership.INVITED).count()
            active_members = total_members - invited_members
            
            self.stdout.write(self.style.SUCCESS(f'成员总数: {total_members}'))
            self.stdout.write(self.style.SUCCESS(f'其中:'))
            self.stdout.write(self.style.SUCCESS(f'  - 已接受邀请的成员: {active_members}'))
            self.stdout.write(self.style.SUCCESS(f'  - 未接受邀请的成员: {invited_members}'))
