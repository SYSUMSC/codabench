import os
from django.core.management.base import BaseCommand
from cdks.models import CDK


class Command(BaseCommand):
    help = "Import CDKs from a text file (one CDK per line)"

    def add_arguments(self, parser):
        parser.add_argument('file_path', type=str, help='Path to the text file containing CDKs')
        parser.add_argument(
            '--skip-existing',
            action='store_true',
            help='Skip CDKs that already exist in the database'
        )

    def handle(self, *args, **options):
        file_path = options['file_path']
        skip_existing = options.get('skip_existing', False)
        
        if not os.path.exists(file_path):
            self.stdout.write(self.style.ERROR(f'文件不存在: {file_path}'))
            return
        
        try:
            with open(file_path, 'r') as f:
                cdk_codes = [line.strip() for line in f.readlines() if line.strip()]
            
            total_cdks = len(cdk_codes)
            imported_count = 0
            skipped_count = 0
            
            for cdk_code in cdk_codes:
                if CDK.objects.filter(code=cdk_code).exists():
                    if skip_existing:
                        self.stdout.write(f'跳过已存在的 CDK: {cdk_code}')
                        skipped_count += 1
                        continue
                    else:
                        self.stdout.write(self.style.WARNING(f'CDK 已存在: {cdk_code}'))
                        continue
                
                CDK.objects.create(code=cdk_code)
                imported_count += 1
            
            self.stdout.write(self.style.SUCCESS(
                f'导入完成: 总共 {total_cdks} 个 CDK，成功导入 {imported_count} 个，'
                f'跳过 {skipped_count} 个'
            ))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'导入失败: {str(e)}'))
