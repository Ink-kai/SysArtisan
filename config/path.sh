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
export  SERVICE_TEMPLATE_PATH="$SCRIPT_DIR/scripts/services"