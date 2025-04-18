from django.core.management.base import BaseCommand
from competitions.models import Submission
from datetime import datetime, timedelta
import pytz

class Command(BaseCommand):
    help = '修复提交记录的时间，将4月18日12点之后的提交时间加8小时（从美国时间调整为北京时间）'

    def handle(self, *args, **options):
        # 设置起始时间：2025年4月18日 12:00
        start_date = datetime(2025, 4, 18, 12, 0, 0)
        
        # 获取需要修复的提交记录
        submissions_to_fix = Submission.objects.filter(
            created_when__gte=start_date
        )
        
        count = submissions_to_fix.count()
        self.stdout.write(self.style.SUCCESS(f'找到 {count} 条需要修复的提交记录'))
        
        # 如果没有需要修复的记录，直接返回
        if count == 0:
            self.stdout.write(self.style.SUCCESS('没有需要修复的记录'))
            return
        
        # 确认是否继续
        self.stdout.write(self.style.WARNING('将为这些记录的创建时间加上8小时，确认继续吗？(y/n)'))
        confirm = input()
        
        if confirm.lower() != 'y':
            self.stdout.write(self.style.WARNING('操作已取消'))
            return
        
        # 修复记录
        fixed_count = 0
        for submission in submissions_to_fix:
            old_time = submission.created_when
            # 添加8小时
            new_time = old_time + timedelta(hours=8)
            
            # 更新记录
            submission.created_when = new_time
            submission.save(update_fields=['created_when'])
            
            fixed_count += 1
            if fixed_count % 100 == 0:
                self.stdout.write(self.style.SUCCESS(f'已修复 {fixed_count}/{count} 条记录'))
        
        self.stdout.write(self.style.SUCCESS(f'成功修复 {fixed_count} 条提交记录的时间'))
        self.stdout.write(self.style.SUCCESS('时间修复完成！'))
