#!/bin/bash
# UI工具函数

# UI初始化
init_ui() {
    # 检查终端大小
    local term_size
    term_size=$(get_terminal_size)
    local term_width
    local term_height
    read -r term_width term_height <<< "$term_size"
    
    if [ "$term_width" -lt "$SCREEN_WIDTH" ] || [ "$term_height" -lt 24 ]; then
        log "ERROR" "终端窗口太小,最小需求: ${SCREEN_WIDTH}x24"
        log "ERROR" "当前大小: ${term_width}x${term_height}"
        return 1
    fi
    
    # 清屏并隐藏光标
    clear_screen
    hide_cursor
    
    # 显示系统基本信息
    echo -e "${COLOR_CYAN}系统信息:${COLOR_RESET}"
    echo -e "操作系统: $SYSTEM_OS"
    echo -e "CPU使用率: $(get_cpu_usage)%"
    echo -e "内存使用率: $(get_memory_usage)%"
    echo -e "磁盘使用率: $(get_disk_usage)%"
    echo -e "----------------------------------------"
    
    # 初始化日志
    clear_ui_logs
    
    return 0
}

# UI清理
cleanup_ui() {
    # 显示光标
    show_cursor
    # 清屏
    clear_screen
}

# 保存光标位置
save_cursor_position() {
    echo -ne "\033[s"
}

# 恢复光标位置
restore_cursor_position() {
    echo -ne "\033[u"
}

# 移动光标
move_cursor() {
    local row=$1
    local col=$2
    echo -ne "\033[${row};${col}H"
}

# 清除行
clear_line() {
    echo -ne "\033[2K"
}

# 清除屏幕
clear_screen() {
    echo -ne "\033[2J\033[H"
}

# 隐藏光标
hide_cursor() {
    echo -ne "\033[?25l"
}

# 显示光标
show_cursor() {
    echo -ne "\033[?25h"
}

# 获取终端大小
get_terminal_size() {
    local width
    local height
    width=$(tput cols)
    height=$(tput lines)
    echo "$width $height"
}

# 显示页面头部
show_header() {
    # 显示标题
    local title="${APPLICATION_TITLE} v${APPLICATION_VERSION}"
    local padding=$(( (SCREEN_WIDTH - ${#title}) / 2 ))
    echo -e "\n${COLOR_CYAN}$(printf '%*s' $padding '')${title}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 $SCREEN_WIDTH))+${COLOR_RESET}"
    
    # 显示系统信息(横排)
    echo -e "${COLOR_YELLOW}系统: ${COLOR_RESET}$(uname -s) $(uname -r)  " \
            "${COLOR_YELLOW}主机: ${COLOR_RESET}$(hostname)  " \
            "${COLOR_YELLOW}用户: ${COLOR_RESET}$(whoami)  " \
            "${COLOR_YELLOW}时间: ${COLOR_RESET}$(date '+%Y-%m-%d %H:%M:%S')"
    
    # 显示资源信息(横排)
    echo -e "${COLOR_YELLOW}CPU: ${COLOR_RESET}$(get_cpu_usage)%  " \
            "${COLOR_YELLOW}内存: ${COLOR_RESET}$(get_memory_usage)%  " \
            "${COLOR_YELLOW}磁盘: ${COLOR_RESET}$(get_disk_usage)%  " \
            "${COLOR_YELLOW}负载: ${COLOR_RESET}$(get_system_load)"
} 