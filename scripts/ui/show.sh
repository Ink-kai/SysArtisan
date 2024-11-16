#!/bin/bash
# 显示菜单标题和系统信息
show_system_info() {

    # 显示标题边框
    show_border

    get_cpu_arch
    get_cpu_model
    printf "${COLOR_YELLOW}操作系统: ${COLOR_RESET}%s\n" "$SYSTEM_OS"
    printf "${COLOR_YELLOW}系统版本: ${COLOR_RESET}%s\n" "$(get_os_version)"
    printf "${COLOR_YELLOW}内核版本: ${COLOR_RESET}%s\n" "$(uname -r)"
    printf "${COLOR_YELLOW}主机名: ${COLOR_RESET}%s\n" "$(hostname)"
    printf "${COLOR_YELLOW}当前用户: ${COLOR_RESET}%s\n" "$(whoami)"
    printf "${COLOR_YELLOW}系统时间: ${COLOR_RESET}%s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
    printf "${COLOR_YELLOW}运行时间: ${COLOR_RESET}%s\n" "$(uptime -p)"

    show_border
    # 显示CPU信息
    get_cpu_info

    # 显示内存信息
    get_memory_info

    # 显示网络信息
    get_ip

    # 显示系统负载
    get_system_load

    # 显示磁盘信息
    get_disk_info

    # 显示标题边框
    show_border
}
# 显示边框
show_border() {
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}"
}

# 显示操作提示
show_operation_prompt() {
    echo -e "${COLOR_YELLOW}请输入您的选择 [字母切换标签, 数字执行操作, q退出]:${COLOR_RESET}"
}

# 显示选择列表
show_select_list() {
    local prefix_title=$1
    shift
    local options=("$@")
    if [ -n "$prefix_title" ]; then
        printf "${COLOR_YELLOW}%s${COLOR_RESET}\n" "$((i + 1)). ${prefix_title} ${options[$i]}"
    else
        printf "${COLOR_YELLOW}%s${COLOR_RESET}\n" "$((i + 1)). ${options[$i]}"
    fi

    local selected
    # while true; do
    #     read -rn 1 -p "请选择 [1-${#options[@]}]: " selected
    #     if [[ "$selected" -ge 1 ]] && [[ "$selected" -le "${#options[@]}" ]]; then
    #         return "$((selected - 1))"
    #     fi
    # done
}
