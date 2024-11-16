#!/bin/bash
# log

# 日志级别
export LOG_LEVEL_DEBUG=0
export LOG_LEVEL_INFO=1
export LOG_LEVEL_WARN=2
export LOG_LEVEL_ERROR=3

# 日志文件
export LOG_FILE="${LOG_PATH}/deploy.log"
export LOG_MAX_SIZE=$((10 * 1024 * 1024)) # 10MB
export LOG_BACKUP_COUNT=5