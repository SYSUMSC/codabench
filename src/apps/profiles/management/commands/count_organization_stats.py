from django.core.management.base import BaseCommand
from django.db.models import Count, Q
from profiles.models import Organization, Membership, User
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

    def get_member_details(self, organization, membership_filter=None):
        """获取组织成员的详细信息"""
        if membership_filter is None:
            membership_filter = {}

        # 学历映射表
        education_level_map = {
            'bachelor': '本科',
            'master': '硕士',
            'phd': '博士',
            'other': '其他'
        }

        # 角色映射表
        role_map = {
            'OWNER': '拥有者',
            'MANAGER': '管理员',
            'PARTICIPANT': '参与者',
            'MEMBER': '成员',
            'INVITED': '已邀请'
        }

        member_details = []
        # 获取组织的所有成员
        memberships = organization.membership_set.filter(**membership_filter)

        for membership in memberships:
            user = membership.user
            # 转换学历为中文
            education_level = user.education_level or ''
            education_level_zh = education_level_map.get(education_level, education_level)

            # 转换角色为中文
            role = membership.group
            role_zh = role_map.get(role, role)

            member_details.append({
                'username': user.username,
                'email': user.email,
                'phone_number': user.phone_number or '',
                'student_id': user.student_id or '',
                'graduation_year': user.graduation_year or '',
                'education_level': education_level_zh,
                'real_name': user.real_name or '',
                'role': role_zh
            })

        return member_details

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

            # 获取成员详细信息
            member_details = self.get_member_details(org, membership_filter)

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
                'date_created': org.date_created,
                'member_details': member_details
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
                with open(export_file, 'w', newline='', encoding='utf-8') as csvfile:
                    # 定义组织基本信息的字段（英文字段名 -> 中文字段名）
                    org_field_map = {
                        'id': '组织ID',
                        'name': '组织名称',
                        'email': '组织邮箱',
                        'member_count': '成员数量',
                        'owners': '拥有者数',
                        'managers': '管理员数',
                        'participants': '参与者数',
                        'members': '普通成员数',
                        'has_submissions': '有提交',
                        'submission_count': '提交数量',
                        'date_created': '创建日期'
                    }

                    # 定义成员详细信息的字段（英文字段名 -> 中文字段名）
                    member_field_map = {
                        'member_username': '成员用户名',
                        'member_email': '成员邮箱',
                        'member_phone': '电话号码',
                        'member_student_id': '学号',
                        'member_graduation_year': '毕业年份',
                        'member_education_level': '学历',
                        'member_real_name': '真实姓名',
                        'member_role': '角色'
                    }

                    # 英文字段名列表
                    org_fieldnames = list(org_field_map.keys())
                    member_fieldnames_prefixed = [
                        'member_username', 'member_email', 'member_phone',
                        'member_student_id', 'member_graduation_year',
                        'member_education_level', 'member_real_name', 'member_role'
                    ]

                    # 所有字段的英文名列表
                    fieldnames = org_fieldnames + member_fieldnames_prefixed

                    # 创建一个自定义的DictWriter，使用中文字段名作为表头
                    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

                    # 写入中文表头
                    header_row = {}
                    for field in org_fieldnames:
                        header_row[field] = org_field_map[field]
                    for field in member_fieldnames_prefixed:
                        header_row[field] = member_field_map[field]

                    writer.writerow(header_row)

                    for org in all_orgs_details:
                        # 转换日期格式以便CSV导出
                        org_copy = org.copy()
                        org_copy['date_created'] = org['date_created'].strftime('%Y-%m-%d')

                        # 移除member_details字段，因为我们会单独处理它
                        member_details = org_copy.pop('member_details')

                        if not member_details:
                            # 如果没有成员，只导出组织信息
                            row_data = {**org_copy,
                                       'member_username': '', 'member_email': '', 'member_phone': '',
                                       'member_student_id': '', 'member_graduation_year': '',
                                       'member_education_level': '', 'member_real_name': '', 'member_role': ''}
                            writer.writerow(row_data)
                        else:
                            # 如果有成员，为每个成员创建一行
                            for i, member in enumerate(member_details):
                                # 第一个成员行包含组织信息
                                if i == 0:
                                    row_data = {**org_copy,
                                              'member_username': member['username'],
                                              'member_email': member['email'],
                                              'member_phone': member['phone_number'],
                                              'member_student_id': member['student_id'],
                                              'member_graduation_year': member['graduation_year'],
                                              'member_education_level': member['education_level'],
                                              'member_real_name': member['real_name'],
                                              'member_role': member['role']}
                                else:
                                    # 后续成员行只包含成员信息，组织字段留空
                                    row_data = {field: '' for field in org_fieldnames}
                                    row_data.update({
                                        'member_username': member['username'],
                                        'member_email': member['email'],
                                        'member_phone': member['phone_number'],
                                        'member_student_id': member['student_id'],
                                        'member_graduation_year': member['graduation_year'],
                                        'member_education_level': member['education_level'],
                                        'member_real_name': member['real_name'],
                                        'member_role': member['role']
                                    })
                                writer.writerow(row_data)

                self.stdout.write(self.style.SUCCESS(f'\n数据已导出到 {export_file}'))

                # 导出文件已经在/tmp目录下，提供多种方式访问该文件
                if export_file.startswith('/tmp/'):
                    self.stdout.write(self.style.SUCCESS(
                        f'\n文件已导出到容器的 {export_file}，'
                        f'您可以通过以下命令将其内容输出并保存到宿主机：\n'
                        f'docker compose exec django cat {export_file} > organization_stats.csv\n\n'
                        f'或者尝试复制文件（如果遇到问题，请使用上面的方法）：\n'
                        f'docker cp $(docker compose ps -q django):{export_file} .'
                    ))

            except Exception as e:
                self.stdout.write(self.style.ERROR(f'\n导出失败: {str(e)}'))
