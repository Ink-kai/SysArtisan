#!/bin/bash
# Tab式菜单实现

# Tab菜单状态
declare -A TAB_STATE=(
    ["current_tab"]="main"
    ["last_tab"]=""
)
SCREEN_WIDTH=56

# 绘制标签页
draw_tabs() {
    local current_tab=$1

    # 绘制标签栏
    echo -ne "${COLOR_CYAN}|${COLOR_RESET}"
    local tabs=("a 安装" "b 卸载" "c 系统" "d 配置" "e 状态")

    # 计算间距使标签均匀分布
    local spacing=$(((SCREEN_WIDTH - 2) / ${#tabs[@]}))

    for tab in "${tabs[@]}"; do
        # 居中对齐每个标签
        local pad_left=$(((spacing - ${#tab}) / 2))
        printf "%${pad_left}s" ""

        echo -ne "${COLOR_GREEN}【$tab】${COLOR_RESET}"

        local pad_right=$((spacing - ${#tab} - pad_left))
        printf "%${pad_right}s" ""
    done

    echo -e "${COLOR_CYAN}|${COLOR_RESET}"
    show_border
}

# 主菜单循环
main_menu_loop() {
    while true; do
        clear_screen
        log "DEBUG" "当前标签: ${TAB_STATE["current_tab"]}"
        # 显示系统信息
        show_system_info
        draw_tabs "${TAB_STATE["current_tab"]}"
        # 显示标签页
        if [ "${TAB_STATE["current_tab"]}" != "main" ]; then
            handle_tab_content
        else
            show_operation_prompt
        fi
        # 处理用户输入,只更新必要的部分
        handle_user_input
    done
}
