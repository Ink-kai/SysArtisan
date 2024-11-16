#!/bin/bash
# system

# 防火墙设置
export FIREWALL_ZONES=("public" "internal")

# 备份设置
export BACKUP_COMPRESS=true
export BACKUP_COMPRESS_TYPE="gzip"

# 系统优化参数
export SYSCTL_PARAMS=(
    "net.ipv4.tcp_max_tw_buckets=5000"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.tcp_max_syn_backlog=1024"
    "net.core.somaxconn=32768"
    "vm.swappiness=10"
)

# 超时设置（秒）
export DOWNLOAD_TIMEOUT=300
export COMMAND_TIMEOUT=300
export NETWORK_TIMEOUT=5
export BACKUP_RETENTION_DAYS=30

# 重试设置
export MAX_RETRIES=3
export RETRY_INTERVAL=5

# 系统要求
export MIN_MEMORY_MB=1024
export MIN_DISK_MB=10240
export MIN_CPU_CORES=1
