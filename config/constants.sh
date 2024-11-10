#!/bin/bash

# 系统路径
export  SYSTEMD_SERVICE_DIR="/etc/systemd/system"
export  INSTALL_PATH="/usr/local"
export  SYSTEM_PROFILE_DIR="/etc/profile"
export  LOG_PATH="/var/log/environment_deploy"
export  BACKUP_PATH="/var/backup/environment_deploy"
export  CONFIG_PATH="/etc/environment_deploy"
export  TEMP_PATH="/tmp/environment_deploy"

# 服务模板路径
export  SERVICE_TEMPLATE_PATH="$SCRIPT_DIR/services"

# 配置文件
export  CONFIG_FILE="$CONFIG_PATH/config.conf"
export  SERVICE_CONFIG="$CONFIG_PATH/services.conf"

# 程序版本信息
export  MIN_JAVA_VERSION="8"
export  MAX_JAVA_VERSION="17"
export  DEFAULT_JAVA_VERSION="11"
export  DEFAULT_NGINX_VERSION="1.24.0"
export  DEFAULT_REDIS_VERSION="7.0.0"

# 超时设置（秒）
export  DOWNLOAD_TIMEOUT=300
export  COMMAND_TIMEOUT=300
export  NETWORK_TIMEOUT=5
export  BACKUP_RETENTION_DAYS=30

# 重试设置
export  MAX_RETRIES=3
export  RETRY_INTERVAL=5

# 系统要求
export  MIN_MEMORY_MB=1024
export  MIN_DISK_MB=10240
export  MIN_CPU_CORES=1

# 版本依赖
export  DEFAULT_DEPENDENCIES="gcc libpcre3-dev zlib1g-dev libssl-dev make"
export  DEFAULT_NGINX_DEPENDENCIES="gcc c++ kernel-devel autogen autoconf"
export  DEFAULT_REDIS_DEPENDENCIES="gcc"
export  DEFAULT_JAVA_DEPENDENCIES=""

# 日志级别
export  LOG_LEVEL_DEBUG=0
export  LOG_LEVEL_INFO=1
export  LOG_LEVEL_WARN=2
export  LOG_LEVEL_ERROR=3

# 防火墙设置
export  FIREWALL_ZONES=("public" "internal")

# 备份设置
export  BACKUP_COMPRESS=true
export  BACKUP_COMPRESS_TYPE="gzip"

# 系统优化参数
export  SYSCTL_PARAMS=(
    "net.ipv4.tcp_max_tw_buckets=5000"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.tcp_max_syn_backlog=1024"
    "net.core.somaxconn=32768"
    "vm.swappiness=10"
)

# 错误码
export  ERR_SUCCESS=0
export  ERR_PERMISSION=1
export  ERR_NETWORK=2
export  ERR_DEPENDENCY=3
export  ERR_CONFIG=4
export  ERR_INSTALL=5
export  ERR_SYSTEM=6