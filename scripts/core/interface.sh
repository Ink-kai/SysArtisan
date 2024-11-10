#!/bin/bash
# 服务接口层 - 定义与服务交互的最小接口集

# 安装服务
install_service() {
    local service_name=$1
    
    # 检查服务模块是否存在
    if [ ! -f "${SERVICE_TEMPLATE_PATH}/${service_name}.sh" ]; then
        log "ERROR" "服务模块不存在: ${service_name}"
        return 1
    fi
    
    # 调用具体服务的安装方法
    if type "install_${service_name}" >/dev/null 2>&1; then
        install_"${service_name}"
    else
        log "ERROR" "未实现安装方法: ${service_name}"
        return 1
    fi
    
    return $?
}

# 卸载服务
uninstall_service() {
    local service_name=$1
    
    # 检查服务是否已安装
    if ! is_service_installed "${service_name}"; then
        log "INFO" "${service_name} 未安装"
        return 0
    fi
    
    # 调用具体服务的卸载方法
    if type "uninstall_${service_name}" >/dev/null 2>&1; then
        uninstall_"${service_name}"
    else
        log "ERROR" "未实现卸载方法: ${service_name}"
        return 1
    fi
    
    return $?
}

# 检查服务是否已安装
is_service_installed() {
    local service_name=$1
    
    if type "is_${service_name}_installed" >/dev/null 2>&1; then
        is_"${service_name}"_installed
    else
        log "ERROR" "未实现安装检查方法: ${service_name}"
        return 1
    fi
    
    return $?
}

# 获取服务状态
get_service_status() {
    local service_name=$1
    
    if type "get_${service_name}_status" >/dev/null 2>&1; then
        get_"${service_name}"_status
    else
        log "ERROR" "未实现状态检查方法: ${service_name}"
        return 1
    fi
    
    return $?
}

# 获取所有可用服务列表
get_available_services() {
    local services=()
    while IFS= read -r -d '' file; do
        local service_name
        service_name=$(basename "$file" .sh)
        services+=("$service_name")
    done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)
    
    echo "${services[@]}"
    return 0
}

# 获取已安装服务列表
get_installed_services() {
    local available_services
    available_services=($(get_available_services))
    local installed_services=()
    
    for service in "${available_services[@]}"; do
        if is_service_installed "$service"; then
            installed_services+=("$service")
        fi
    done
    
    echo "${installed_services[@]}"
    return 0
} 