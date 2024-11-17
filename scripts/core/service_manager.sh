#!/bin/bash
# 服务管理器

# 验证服务模块
verify_service_module() {
    local module_file=$1
    local service_name=$(basename "$module_file" .sh)

    # 检查文件是否存在且可读
    if [ ! -f "$module_file" ] || [ ! -r "$module_file" ]; then
        log "ERROR" "服务模块不存在: $module_file"
        return 1
    fi

    # 检查必需的函数是否存在
    declare -f "install_${service_name}" >/dev/null 2>&1
    declare -f "uninstall_${service_name}" >/dev/null 2>&1
}

# 获取服务列表的通用函数
get_services() {
    local list_type=$1

    # 检查服务模板目录是否存在
    if [ ! -d "${SERVICE_TEMPLATE_PATH}" ]; then
        log "ERROR" "服务模板目录不存在: ${SERVICE_TEMPLATE_PATH}"
        return "$ERR_SUCCESS"
    fi

    while IFS= read -r -d '' service_file; do
        local service_name=$(basename "$service_file" .sh)

        log "DEBUG" "验证 $service_name 服务 "

        case "$list_type" in
        "available")
            SERVICE_AVAILABLE+=("$service_name")
            ;;
        "installable" | "uninstallable")
            # 验证服务模块
            if verify_service_module "$service_file"; then
                SERVICE_INSTALLED+=("$service_name")
                log "DEBUG" "服务 $service_name 注册成功"
            else
                log "DEBUG" "服务 $service_name 注册失败"
            fi
            ;;
        esac
    done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)

    # SERVICE_AVAILABLE/SERVICE_INSTALLED 去重
    SERVICE_AVAILABLE=($(echo "${SERVICE_AVAILABLE[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    SERVICE_INSTALLED=($(echo "${SERVICE_INSTALLED[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    log "DEBUG" "已注册服务: ${SERVICE_AVAILABLE[*]}"
    log "DEBUG" "已安装服务: ${SERVICE_INSTALLED[*]}"
}