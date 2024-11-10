#!/bin/bash
# Tab页内容管理

# 显示安装选项
show_install_options() {
    echo -e "\n${COLOR_CYAN}=== 可安装的服务 ===${COLOR_RESET}\n"

    # 检查服务模板目录
    if [ ! -d "${SERVICE_TEMPLATE_PATH}" ]; then
        echo -e "${COLOR_RED} ${SERVICE_TEMPLATE_PATH} 服务模板目录不存在${COLOR_RESET}"
        echo -e "\n${COLOR_YELLOW}0. 返回主菜单${COLOR_RESET}\n"
        return 1
    fi

    # 获取所有可用服务
    local services
    services=($(get_available_services))

    # 检查是否找到服务
    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${COLOR_YELLOW}未找到任何可用服务${COLOR_RESET}"
        echo -e "\n${COLOR_YELLOW}0. 返回主菜单${COLOR_RESET}\n"
        return 1
    fi

    # 显示服务列表
    local index=1
    for service in "${services[@]}"; do
        echo -e "${COLOR_GREEN}$index. 安装 $service${COLOR_RESET}"
        ((index++))
    done

    echo -e "\n${COLOR_YELLOW}0. 返回主菜单${COLOR_RESET}\n"
    return 0
}

# 显示卸载选项
show_uninstall_options() {
    echo -e "${COLOR_YELLOW}可卸载的服务:${COLOR_RESET}"

    # 获取已安装的服务
    local services
    services=($(get_installed_services))

    if [ ${#services[@]} -eq 0 ]; then
        echo -e "${COLOR_YELLOW}没有已安装的服务${COLOR_RESET}"
        echo -e "\n${COLOR_YELLOW}0. 返回主菜单${COLOR_RESET}"
        return 0
    fi

    echo -e "\n${COLOR_YELLOW}0. 返回主菜单${COLOR_RESET}"
    return 0
}

# 显示系统选项
show_system_options() {
    echo -e "${COLOR_YELLOW}系统管理:${COLOR_RESET}"
    echo "1. 系统优化"
    echo "2. 清理系统"
    echo "3. 更新系统"
    echo "4. 查看系统信息"
    echo "0. 返回主菜单"
}

# 显示配置选项
show_config_options() {
    echo -e "${COLOR_YELLOW}配置管理:${COLOR_RESET}"
    echo "1. 查看配置"
    echo "2. 修改配置"
    echo "3. 备份配置"
    echo "4. 恢复配置"
    echo "0. 返回主菜单"
}

# 显示状态选项
show_status_options() {
    echo -e "${COLOR_YELLOW}状态查看:${COLOR_RESET}"

    # 显示系统状态
    echo -e "\n系统状态:"
    echo "CPU使用率: $(get_cpu_usage)%"
    echo "内存使用率: $(get_memory_usage)%"
    echo "磁盘使用率: $(get_disk_usage)%"

    # 显示服务状态
    echo -e "\n服务状态:"
    local services=()
    while IFS= read -r -d '' file; do
        local service_name
        service_name=$(basename "$file" .sh)
        if is_service_installed "$service_name"; then
            local status
            status=$(get_service_status "$service_name")
            echo "$service_name: $status"
        fi
    done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)

    echo -e "\n0. 返回主菜单"
}

# 显示安装内容
show_install_content() {
    show_install_options
}

# 显示卸载内容
show_uninstall_content() {
    show_uninstall_options
}

# 显示系统内容
show_system_content() {
    show_system_options
}

# 显示配置内容
show_config_content() {
    show_config_options
}

# 显示状态内容
show_status_content() {
    show_status_options
}

# 内容显示控制器
show_content_controller() {
    local content_type=$1
    case "$content_type" in
    "install") show_install_content ;;
    "uninstall") show_uninstall_content ;;
    "system") show_system_content ;;
    "config") show_config_content ;;
    "status") show_status_content ;;
    *) log "ERROR" "未知的内容类型: $content_type" ;;
    esac
}
