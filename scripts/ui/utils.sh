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
    # hide_cursor
    
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