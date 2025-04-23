from django.core.management.base import BaseCommand
from django.db.models import Count, Q
from profiles.models import Organization, Membership
from competitions.models import Submission
import csv


class Command(BaseCommand):
    help = "统计组织和成员数量，包括所有注册组织和有提交的组织"

    def add_arguments(self, parser):
        parser.add_argument(
            '--active-only',
            action='store_true',
            help='只统计已接受邀请的成员（排除INVITED状态的成员）'
        )
        parser.add_argument(
            '--detail',
            action='store_true',
            help='显示每个组织的详细信息'
        )
        parser.add_argument(
            '--export',
            type=str,
            help='将结果导出到CSV文件'
        )

    def handle(self, *args, **options):
        active_only = options.get('active_only')
        detail = options.get('detail')
        export_file = options.get('export')

        # 准备查询条件
        membership_filter = {}
        if active_only:
            membership_filter['group__in'] = Membership.ALL_GROUP  # 排除INVITED状态的成员

        # 1. 统计所有注册的组织
        all_organizations = Organization.objects.all().order_by('name')
        total_orgs = all_organizations.count()

        # 收集所有组织的详细信息
        all_orgs_details = []
        total_members = 0

        for org in all_organizations:
            member_count = org.membership_set.filter(**membership_filter).count()
            total_members += member_count

            # 统计不同角色的成员数量
            owners = org.membership_set.filter(group=Membership.OWNER, **membership_filter).count()
            managers = org.membership_set.filter(group=Membership.MANAGER, **membership_filter).count()
            participants = org.membership_set.filter(group=Membership.PARTICIPANT, **membership_filter).count()
            members = org.membership_set.filter(group=Membership.MEMBER, **membership_filter).count()

            # 检查是否有提交
            has_submissions = Submission.objects.filter(organization=org).exists()
            submission_count = Submission.objects.filter(organization=org).count()

            all_orgs_details.append({
                'id': org.id,
                'name': org.name,
                'email': org.email,
                'member_count': member_count,
                'owners': owners,
                'managers': managers,
                'participants': participants,
                'members': members,
                'has_submissions': has_submissions,
                'submission_count': submission_count,
                'date_created': org.date_created
            })

        # 2. 统计所有提交过submission的组织
        orgs_with_submissions = [org for org in all_orgs_details if org['has_submissions']]
        total_orgs_with_submissions = len(orgs_with_submissions)
        total_members_in_orgs_with_submissions = sum(org['member_count'] for org in orgs_with_submissions)

        # 输出结果
        self.stdout.write("\n组织统计信息:")
        self.stdout.write("=" * 80)
        self.stdout.write(self.style.SUCCESS(f'1. 所有注册的组织:'))
        self.stdout.write(f'   - 组织总数: {total_orgs}')
        self.stdout.write(f'   - 成员总数: {total_members}')

        self.stdout.write(self.style.SUCCESS(f'\n2. 所有提交过submission的组织:'))
        self.stdout.write(f'   - 组织总数: {total_orgs_with_submissions}')
        self.stdout.write(f'   - 成员总数: {total_members_in_orgs_with_submissions}')

        # 如果有active_only参数，说明这些统计只包括已接受邀请的成员
        if active_only:
            self.stdout.write(self.style.WARNING('\n注意: 以上统计只包括已接受邀请的成员（排除INVITED状态的成员）'))

        # 显示详细信息
        if detail:
            self.stdout.write("\n所有组织详细信息:")
            self.stdout.write("=" * 80)
            header = f"{'ID':<5} {'名称':<30} {'成员数':<8} {'提交数':<8} {'创建日期':<12}"
            self.stdout.write(header)
            self.stdout.write("-" * 80)

            for org in all_orgs_details:
                row = (
                    f"{org['id']:<5} "
                    f"{org['name'][:28]:<30} "
                    f"{org['member_count']:<8} "
                    f"{org['submission_count']:<8} "
                    f"{org['date_created'].strftime('%Y-%m-%d'):<12}"
                )
                self.stdout.write(row)

            self.stdout.write("\n有提交的组织详细信息:")
            self.stdout.write("=" * 80)
            self.stdout.write(header)
            self.stdout.write("-" * 80)

            for org in orgs_with_submissions:
                row = (
                    f"{org['id']:<5} "
                    f"{org['name'][:28]:<30} "
                    f"{org['member_count']:<8} "
                    f"{org['submission_count']:<8} "
                    f"{org['date_created'].strftime('%Y-%m-%d'):<12}"
                )
                self.stdout.write(row)

        # 导出到CSV
        if export_file:
            try:
                with open(export_file, 'w', newline='') as csvfile:
                    fieldnames = [
                        'id', 'name', 'email', 'member_count', 'owners', 'managers',
                        'participants', 'members', 'has_submissions', 'submission_count', 'date_created'
                    ]
                    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

                    writer.writeheader()
                    for org in all_orgs_details:
                        # 转换日期格式以便CSV导出
                        org_copy = org.copy()
                        org_copy['date_created'] = org['date_created'].strftime('%Y-%m-%d')
                        writer.writerow(org_copy)

                self.stdout.write(self.style.SUCCESS(f'\n数据已导出到 {export_file}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'\n导出失败: {str(e)}'))
