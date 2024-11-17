#!/bin/bash
# ui 操作处理

# 处理安装/卸载操作
handle_service_operation() {
    local operation=$1 # install 或 uninstall
    local choice=$2
    log "DEBUG" "${operation}选择: $choice"

    if [ "$choice" = "0" ]; then
        return 0
    fi

    # 根据操作类型获取服务列表
    local services_str
    if [ "$operation" = "install" ]; then
        get_available_services
        services_str=${SERVICE_AVAILABLE[*]}
    else
        get_installed_services
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

    # 处理返回主菜单
    if [ "$choice" = "0" ]; then
        TAB_STATE["last_tab"]=$current_tab
        TAB_STATE["current_tab"]="main"
        return 0
    fi

    # 根据当前标签处理操作
    case "$current_tab" in
    "install" | "uninstall")
        show_service_options "$current_tab"
        show_select_list "${current_tab^}" "${current_tab}_services[@]"
        handle_service_operation "$current_tab" "$choice"
        ;;
    *)
        # 调用对应的处理函数
        "handle_${current_tab}" "$choice"
        ;;
    esac

    printf "\n%s\n" "${COLOR_YELLOW}按任意键继续...${COLOR_RESET}"
    read -n 1 -s -r
}

# 处理Tab切换
handle_tab_switch() {
    local key=${1:-""}

    log "DEBUG" "Tab切换: $key"

    case "$key" in
    a | A) TAB_STATE["current_tab"]="install" ;;
    b | B) TAB_STATE["current_tab"]="uninstall" ;;
    c | C) TAB_STATE["current_tab"]="system" ;;
    d | D) TAB_STATE["current_tab"]="config" ;;
    e | E) TAB_STATE["current_tab"]="status" ;;
    esac

    # 根据新的标签显示相应内容
    case "${TAB_STATE["current_tab"]}" in
    "install")
        show_service_options "install"
        get_available_services
        show_select_list "安装" "${SERVICE_AVAILABLE[@]}"
        ;;
    "uninstall")
        show_service_options "uninstall"
        get_installed_services
        show_select_list "卸载" "${SERVICE_INSTALLED[@]}"
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
    show_operation_prompt

    # 读取用户输入(单个字符)
    read -r -n 1 choice
    echo # 换行

    # 检查是否为退出命令
    if [[ "$choice" =~ [qQ] ]]; then
        log "INFO" "用户选择退出"
        cleanup_ui
        exit 0
    fi

    # 如果是主菜单状态，处理标签切换
    if [ "${TAB_STATE["current_tab"]}" = "main" ]; then
        handle_tab_switch "$choice"
        return
    fi

    # 如果是数字，处理操作选择
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        handle_operation "$choice"
    # 如果是字母，处理标签切换
    elif [[ "$choice" =~ ^[a-eA-E]$ ]]; then
        handle_tab_switch "$choice"
    else
        log "WARN" "无效的输入: $choice"
    fi
}
