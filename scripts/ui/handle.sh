#!/bin/bash
# ui 操作处理

# 处理安装/卸载操作
handle_service_operation() {
    local operation=$1 # install 或 uninstall
    local choice=$2
    log "DEBUG" "${operation}选择: $choice"

    if [ "$choice" = "0" ]; then
        # 切换到主标签
        TAB_STATE["current_tab"]="main"
        sleep 1
        return 0
    fi

    # 根据操作类型获取服务列表
    local services_str
    if [ "$operation" = "install" ]; then
        get_services "installable"
        services_str=${SERVICE_AVAILABLE[*]}
    else
        get_services "uninstallable"
        services_str=${SERVICE_INSTALLED[*]}
    fi
    # 将服务列表字符串转换为数组
    IFS=' ' read -r -a services <<<"$services_str"

    log "DEBUG" "服务列表: ${services[*]}"
    log "DEBUG" "服务数量: ${#services[@]}"

    # 检查选择是否有效
    if [ "$choice" -gt 0 ] && [ "$choice" -le "${#services[@]}" ]; then
        local service_name="${services[$((choice - 1))]}"
        log "DEBUG" "选中服务: $service_name"
        if [ "$operation" = "install" ]; then
            install_service "$service_name"
        else
            uninstall_service "$service_name"
        fi
    else
        log "ERROR" "选择无效 $choice"
    fi
}

# 统一的操作处理函数
handle_operation() {
    local choice=$1
    local current_tab=${TAB_STATE["current_tab"]}

    if [ "$current_tab" ]; then
        handle_service_operation "$current_tab" "$choice"
    else
        log "ERROR" "未选择标签"
        sleep 1
        TAB_STATE["current_tab"]="main"
        handle_tab_content
    fi
}

# 处理Tab切换
handle_tab_switch() {
    local key=${1:-""}

    log "DEBUG" "Tab切换: $key"
    case "$key" in
    a | A)
        TAB_STATE["current_tab"]="install"
        handle_tab_content
        ;;
    b | B)
        TAB_STATE["current_tab"]="uninstall"
        handle_tab_content
        ;;
    c | C)
        TAB_STATE["current_tab"]="system"
        handle_tab_content
        ;;
    d | D)
        TAB_STATE["current_tab"]="config"
        handle_tab_content
        ;;
    e | E)
        TAB_STATE["current_tab"]="status"
        handle_tab_content
        ;;
    *)
        log "DEBUG" "无效标签: $key"
        sleep 1
        TAB_STATE["current_tab"]="main"
        handle_tab_content
        ;;
    esac
}

# 根据新的标签显示相应内容
handle_tab_content() {
    case "${TAB_STATE["current_tab"]}" in
    "install")
        get_services "installable"
        log "DEBUG" "安装服务列表: ${SERVICE_INSTALLED[*]}"
        show_select_list "安装" "${SERVICE_INSTALLED[@]}"
        ;;
    "uninstall")
        get_services "uninstallable"
        log "DEBUG" "卸载服务列表: ${SERVICE_AVAILABLE[*]}"
        show_select_list "卸载" "${SERVICE_AVAILABLE[@]}"
        ;;
    "system")
        show_system_content
        ;;
    "config")
        show_config_content
        ;;
    "status")
        show_status_content
        ;;
    esac
}

# 处理用户输入
handle_user_input() {
    local choice
    # 显示操作提示
    read -n 1 -s -r -p "$(show_operation_prompt)" choice
    echo -e "\n"

    case "$choice" in
    q | Q)
        log "INFO" "用户选择退出"
        cleanup_ui
        exit 0
        ;;
    [1-9] | [1-9][0-9])
        # 执行操作后等待用户确认
        handle_operation "$choice"
        ;;
    [a-eA-E])
        # 切换标签时只更新标签和内容区域
        handle_tab_switch "$choice"
        ;;
    *)
        log "WARN" "无效的输入: $choice"
        # 切换到主标签
        TAB_STATE["current_tab"]="main"
        sleep 1
        ;;
    esac
}
