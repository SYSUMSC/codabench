# 排行榜自动选择最佳提交脚本

## 功能说明

`auto_select_best_submissions.py` 是一个Django管理命令，用于自动为每个组织的每个问题（比赛）选择得分最高的提交显示在排行榜上。

这个命令会：
1. 查找所有有提交的组织
2. 检查每个组织是否有管理员成员（is_staff 或 is_superuser）
   - 如果有管理员成员，默认会从排行榜中移除该组织的所有提交
   - 如果没有管理员成员，则继续处理
3. 对于每个普通组织，找到其在每个排行榜（问题）上的所有提交
4. 根据排行榜的主要评分列，选择得分最高的提交
5. 将选中的提交添加到排行榜，并从排行榜中移除该组织的其他提交

## 使用方法

### 直接运行命令

```bash
# 干运行模式（不实际修改数据库）
python manage.py auto_select_best_submissions --dry-run

# 显示详细信息
python manage.py auto_select_best_submissions --verbose

# 包括有管理员成员的组织（默认会移除管理员组织的所有提交）
python manage.py auto_select_best_submissions --include-admin-orgs

# 正式运行（更新排行榜）
python manage.py auto_select_best_submissions
```

### 使用脚本定期运行

我们提供了一个脚本 `src/scripts/update_leaderboard.sh`，可以通过cron定期运行：

```bash
# 编辑crontab
crontab -e

# 添加以下行，每天凌晨3点运行
0 3 * * * /www/wwwroot/codabench/src/scripts/update_leaderboard.sh >> /www/wwwroot/codabench/logs/leaderboard_update.log 2>&1
```

## 参数说明

- `--dry-run`: 干运行模式，只显示将要执行的操作，不实际修改数据库
- `--verbose`: 显示详细的操作信息
- `--include-admin-orgs`: 包括有管理员成员的组织（默认会移除管理员组织的所有提交）

## 注意事项

1. 该命令会根据排行榜的主要评分列（primary_index）和排序方式（sorting）来确定"最佳"提交
2. 对于降序排序（desc）的列，分数越高越好；对于升序排序（asc）的列，分数越低越好
3. 如果有多个得分相同的提交，会选择最早创建的那个
4. 默认情况下，如果组织中有任何成员是管理员（is_staff 或 is_superuser），该组织的所有提交都会从排行榜中移除
5. 使用 `--include-admin-orgs` 参数可以让管理员组织的提交也显示在排行榜上
