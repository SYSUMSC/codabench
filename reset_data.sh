#!/bin/bash

# 确认用户是否真的要删除所有数据
read -p "此操作将永久删除所有挂载的数据，是否继续？(y/N): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
  echo "操作已取消。"
  exit 0
fi

# 定义所有挂载目录
mount_points=(
  "./var/postgres"
  "./var/minio"
  "./var/rabbit"
  "./var/log"
  "./var/logs"
  "/tmp/codalab-v2/django"
  "./backups"
  "./caddy_data"
  "./caddy_config"
  "./src/staticfiles"
)

# 删除所有挂载目录
for dir in "${mount_points[@]}"; do
  if [ -d "$dir" ]; then
    echo "正在删除目录: $dir"
    rm -rf "$dir"
  else
    echo "目录不存在: $dir"
  fi
done
echo "数据清理完成。"