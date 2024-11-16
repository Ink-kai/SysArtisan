#!/bin/bash
# 服务接口层 - 定义与服务交互的最小接口集

# 安装服务
install_service() {
    local service_name=$1

    # 检查服务模块是否存在
    if [ ! -f "${SERVICE_TEMPLATE_PATH}/${service_name}.sh" ]; then
        log "ERROR" "服务模块不存在: ${service_name}"
    fi

    # 调用具体服务的安装方法
    if declare -f "install_${service_name}" >/dev/null; then
        install_"${service_name}"
    else
        log "ERROR" "未实现 ${service_name} 服务安装方法"
    fi
}

# 卸载服务
uninstall_service() {
    local service_name=$1

    # 检查服务模块是否存在
    if [ ! -f "${SERVICE_TEMPLATE_PATH}/${service_name}.sh" ]; then
        log "ERROR" "服务模块不存在: ${service_name}"
    fi
    # 调用具体服务的卸载方法
    if declare -f "uninstall_${service_name}" >/dev/null; then
        uninstall_"${service_name}"
    else
        log "ERROR" "未实现 ${service_name} 服务卸载方法"
    fi
}

# 检查服务是否已安装
is_service_installed() {
    local service_name=$1

    # 检查服务模块是否存在
    if [ ! -f "${SERVICE_TEMPLATE_PATH}/${service_name}.sh" ]; then
        log "ERROR" "服务模块不存在: ${service_name}"
    fi

    # 调用具体服务的检查方法
    if declare -f "is_${service_name}_installed" >/dev/null; then
        is_"${service_name}"_installed
    else
        log "ERROR" "未实现 ${service_name} 服务检查方法"
    fi

}

# 获取服务状态
get_service_status() {
    local service_name=$1

    if declare -f "get_${service_name}_status" >/dev/null; then
        get_"${service_name}"_status
    else
        log "ERROR" "未实现状态检查方法: ${service_name}"
    fi

}
