#!/bin/bash
# 服务管理器

# 验证服务模块
verify_service_module() {
    local module_file=$1
    local service_name=$(basename "$module_file" .sh)

    # 检查文件是否存在且可读
    if [ ! -f "$module_file" ] || [ ! -r "$module_file" ]; then
        log "DEBUG" "服务模块不存在: $module_file"
        return 1
    fi

    # 检查必需的函数是否存在
    declare -f "install_${service_name}" >/dev/null 2>&1 &
    declare -f "uninstall_${service_name}" >/dev/null 2>&1
}

# 获取可安装的服务列表
get_installable_services() {
    SERVICE_AVAILABLE=()
    local service_count=0

    while IFS= read -r -d '' service_file; do
        local service_name=$(basename "$service_file" .sh)

        log "DEBUG" "正在验证服务: $service_name"
        if verify_service_module "$service_file"; then
            SERVICE_AVAILABLE+=("$service_name")
            ((service_count++))
            log "DEBUG" "服务 $service_name 注册成功"
        else
            log "DEBUG" "服务 $service_name 注册失败"
        fi
    done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)

    log "DEBUG" "可安装服务总数: $service_count"

    [ $service_count -eq 0 ] && {
        echo -e "${COLOR_YELLOW}没有可安装服务${COLOR_RESET}"
        return "${ERR_SUCCESS}"
    }

    show_select_list "安装" "${SERVICE_AVAILABLE[@]}"
}

# 获取可卸载的服务列表
get_uninstallable_services() {
    if [ ! -d "${SERVICE_TEMPLATE_PATH}" ]; then
        log "ERROR" "服务模板目录不存在: ${SERVICE_TEMPLATE_PATH}"
        return "$ERR_SUCCESS"
    fi

    # 初始化变量
    local services=()
    local service_count=0

    while IFS= read -r -d '' service_file; do
        local service_name
        service_name=$(basename "$service_file" .sh)

        # 验证服务模块并打印调试信息
        log "DEBUG" "正在验证服务: $service_name"
        log "DEBUG" "服务文件路径: $service_file"

        if declare -f "uninstall_${service_name}" >/dev/null && verify_service_module "$service_file"; then
            log "DEBUG" "服务 $service_name 注册成功"
            services+=("$service_name")
            service_count=$((service_count + 1))
        else
            log "DEBUG" "服务 $service_name 注册失败"
        fi
    done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)

    # 打印找到的服务总数
    log "DEBUG" "可卸载服务总数: $service_count"

    # 如果没有可卸载的服务
    if [ $service_count -eq 0 ]; then
        echo -e "${COLOR_YELLOW}没有可卸载服务${COLOR_RESET}"
        return "${ERR_SUCCESS}"
    fi

    show_select_list "卸载" "${services[@]}"
}

# 获取所有可用服务列表
get_available_services() {
    SERVICE_AVAILABLE=()

    while IFS= read -r -d '' file; do
        SERVICE_AVAILABLE+=("$(basename "$file" .sh)")
    done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)

    SERVICE_AVAILABLE=$(echo "${SERVICE_AVAILABLE[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    log "DEBUG" "可用服务: ${SERVICE_AVAILABLE[*]}"
}

# 获取已安装服务列表
get_installed_services() {
    local available_services
    read -ra available_services <<<"$(get_available_services)"

    for service in "${available_services[@]}"; do
        if is_service_installed "$service"; then
            SERVICE_INSTALLED+=("$service")
        fi
    done

    SERVICE_INSTALLED=$(echo "${SERVICE_INSTALLED[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    log "DEBUG" "已安装服务: ${SERVICE_INSTALLED[*]}"

}
