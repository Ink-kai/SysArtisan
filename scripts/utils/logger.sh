#!/bin/bash
# 日志工具

# UI日志数组
declare -a RECENT_LOGS=()
readonly MAX_LOGS=5

# 当前日志级别（默认为 INFO）
CURRENT_LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_DEBUG}

# UI日志函数
add_ui_log() {
    local message=$1
    local timestamp=$(date '+%H:%M:%S')

    # 添加新日志到数组开头
    RECENT_LOGS=("[$timestamp] $message" "${RECENT_LOGS[@]}")

    # 保持日志数量限制
    if [ ${#RECENT_LOGS[@]} -gt $MAX_LOGS ]; then
        unset 'RECENT_LOGS[${#RECENT_LOGS[@]}-1]'
    fi
}

# 获取最近UI日志
get_recent_logs() {
    echo "${RECENT_LOGS[@]}"
}

# 清除UI日志
clear_ui_logs() {
    RECENT_LOGS=()
}

# 初始化日志系统
init_logger() {
    # 创建日志目录
    if [ ! -d "$(dirname "$LOG_FILE")" ]; then
        mkdir -p "$(dirname "$LOG_FILE")" || {
            echo "无法创建日志目录: $(dirname "$LOG_FILE")"
            return 1
        }
    fi

    # 创建日志文件
    touch "$LOG_FILE" || {
        echo "无法创建日志文件: $LOG_FILE"
        return 1
    }

    # 设置权限
    chmod 644 "$LOG_FILE" || {
        echo "无法设置日志文件权限"
        return 1
    }

    # 检查日志大小并轮转
    check_log_rotation

    # 清除UI日志
    clear_ui_logs

    log "INFO" "日志系统初始化完成"
    return 0
}

# 检查日志轮转
check_log_rotation() {
    if [ -f "$LOG_FILE" ]; then
        local size
        size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")

        # 确保size是数字
        if [[ "$size" =~ ^[0-9]+$ ]] && [ "$size" -gt "$LOG_MAX_SIZE" ]; then
            rotate_logs
        fi
    fi
}

# 轮转日志
rotate_logs() {
    local i=$LOG_BACKUP_COUNT

    while [ $i -gt 0 ]; do
        if [ -f "${LOG_FILE}.$((i - 1))" ]; then
            mv "${LOG_FILE}.$((i - 1))" "${LOG_FILE}.$i"
        fi
        i=$((i - 1))
    done

    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.1"
    fi

    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

# 日志记录
log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_level_num

    # 转换日志级别为数字
    case $level in
    "DEBUG") log_level_num=$LOG_LEVEL_DEBUG ;;
    "INFO") log_level_num=$LOG_LEVEL_INFO ;;
    "WARN") log_level_num=$LOG_LEVEL_WARN ;;
    "ERROR") log_level_num=$LOG_LEVEL_ERROR ;;
    *) log_level_num=$LOG_LEVEL_INFO ;;
    esac

    # 检查日志级别
    if [ "$log_level_num" -ge "$CURRENT_LOG_LEVEL" ]; then
        # 格式化日志消息
        local log_message="[$timestamp] [$level] $message"

        # 写入文件日志
        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            echo "$log_message" >>"$LOG_FILE"
        fi

        # 添加到UI日志
        add_ui_log "$message"

        # 根据日志级别使用不同颜色
        case "$level" in
        "DEBUG") echo -e "${COLOR_DEBUG}${log_message}${COLOR_RESET}" 3>&1 ;;
        "INFO") echo -e "${COLOR_INFO}${log_message}${COLOR_RESET}" 3>&1 ;;
        "WARN") echo -e "${COLOR_WARNING}${log_message}${COLOR_RESET}" 3>&1 ;;
        "ERROR") echo -e "${COLOR_ERROR}${log_message}${COLOR_RESET}" 3>&1 ;;
        *) echo -e "${log_message}" 3>&1 ;;
        esac
    fi
}

# 设置日志级别
set_log_level() {
    case ${1^^} in
    "DEBUG") CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
    "INFO") CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
    "WARN") CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
    "ERROR") CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
    *) log "ERROR" "无效的日志级别: $1" ;;
    esac
}

# 清理旧日志
cleanup_old_logs() {
    local max_days=${1:-30} # 默认保留30天
    local log_dir
    log_dir=$(dirname "$LOG_FILE")

    find "$log_dir" -name "*.log.*" -type f -mtime +"$max_days" -delete
    log "INFO" "已清理${max_days}天前的旧日志文件"
}

# 检查日志目录权限
check_log_permissions() {
    local log_dir
    log_dir=$(dirname "$LOG_FILE")

    # 检查目录权限
    if [ ! -w "$log_dir" ]; then
        log "ERROR" "日志目录无写入权限: $log_dir"
        return 1
    fi

    # 检查文件权限
    if [ -f "$LOG_FILE" ] && [ ! -w "$LOG_FILE" ]; then
        log "ERROR" "日志文件无写入权限: $LOG_FILE"
        return 1
    fi

    return 0
}

# 显示日志内容
show_logs() {
    local lines=${1:-50} # 默认显示最后50行
    local log_file=${2:-"$LOG_FILE"}
    local filter=${3:-""}

    echo -e "\n系统日志内容:"
    echo "----------------------------------------"

    if [ ! -f "$log_file" ]; then
        log "ERROR" "日志文件不存在: $log_file"
        return 1
    fi

    # 显示日志文件信息
    echo "日志文件: $log_file"
    echo "文件大小: $(du -h "$log_file" | cut -f1)"
    echo "最后修改: $(stat -c '%y' "$log_file")"
    echo "----------------------------------------"

    # 根据是否有过滤条件显示日志
    if [ -n "$filter" ]; then
        echo "应用过滤条件: $filter"
        if ! grep -i "$filter" "$log_file" >/dev/null; then
            echo "未找到匹配的日志条目"
        else
            tail -n "$lines" "$log_file" | grep --color=auto -i "$filter" || true
        fi
    else
        tail -n "$lines" "$log_file"
    fi

    # 提供交互式选项
    echo -e "\n----------------------------------------"
    echo "操作选项:"
    echo "1. 查看更多日志行"
    echo "2. 应用过滤条件"
    echo "3. 清空日志文件"
    echo "4. 返回上级菜单"

    read -r -p "请选择操作 [1-4]: " choice
    case $choice in
    1)
        read -r -p "请输入要查看的行数: " new_lines
        show_logs "$new_lines" "$log_file" "$filter"
        ;;
    2)
        read -r -p "请输入过滤关键字: " new_filter
        show_logs "$lines" "$log_file" "$new_filter"
        ;;
    3)
        read -r -p "确定要清空日志文件吗？(y/n): " confirm
        if [ "$confirm" = "y" ]; then
            truncate -s 0 "$log_file"
            log "INFO" "日志文件已清空"
        fi
        ;;
    4)
        return 0
        ;;
    *)
        log "WARN" "无效的选择"
        ;;
    esac
}
