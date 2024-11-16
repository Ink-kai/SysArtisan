#!/bin/bash
# 用户界面工具


#  existing code
# 处理安装选择
process_install_choice() {
    local service_name=$1

    if [ ! -f "${SERVICE_TEMPLATE_PATH}/${service_name}.sh" ]; then
        log "ERROR" "未找到 ${service_name} 服务模板"
        return 1
    fi

    # 调用service层处理安装
    install_service "$service_name"
}

# 处理卸载选择
process_uninstall_choice() {
    local service_name=$1

    if [ ! -f "${SERVICE_TEMPLATE_PATH}/${service_name}.sh" ]; then
        log "ERROR" "未找到 ${service_name} 服务模板"
        return 1
    fi

    # 调用service层处理卸载
    uninstall_service "$service_name"
}

# 处理系统管理选择
process_system_choice() {
    local choice=$1
    case $choice in
    1)
        optimize_system
        ;;
    2)
        cleanup_system
        ;;
    3)
        update_system
        ;;
    4)
        return
        ;;
    *)
        log "WARN" "无效的选择: $choice"
        ;;
    esac
}

# 处理配置选择
process_config_choice() {
    local choice=$1
    case $choice in
    1)
        show_config
        ;;
    2)
        local key
        read -r -p "请输入要修改的配置项: " key
        modify_config "$key"
        ;;
    3)
        backup_config
        ;;
    4)
        restore_config
        ;;
    5)
        return 0
        ;;
    *)
        log "WARN" "无效的选择: $choice"
        return 1
        ;;
    esac
    return 0
}

# 处理状态选择
process_status_choice() {
    local choice=$1
    case $choice in
    1)
        get_system_status
        ;;
    2)
        get_service_status
        ;;
    3)
        show_resource_usage
        ;;
    4)
        show_logs
        ;;
    5)
        return 0
        ;;
    *)
        log "WARN" "无效的选择: $choice"
        return 1
        ;;
    esac
    return 0
}

# 获取用户输入
get_user_input() {
    local prompt=$1
    local default=$2
    local timeout=${3:-0}
    local required=${4:-false}
    local validate_func=${5:-""}
    local retry=${6:-3}
    local input

    while [ "$retry" -gt 0 ]; do
        if [ "$timeout" -gt 0 ]; then
            read -r -p "$prompt [${default}] (${timeout}s): " -t "$timeout" input || true
        else
            read -r -p "$prompt [${default}] (输入'q'退出): " input || true
        fi

        # 检查是否要退出
        if [ "$input" = "q" ] || [ "$input" = "Q" ]; then
            log "INFO" "用户取消操作"
            return 1
        fi

        # 处理Ctrl+D或其他读取错误
        if [ $? -ne 0 ]; then
            echo
            if [ "$required" = false ]; then
                echo "$default"
                return 0
            else
                retry=$((retry - 1))
                [ "$retry" -gt 0 ] && continue || return 1
            fi
        fi

        # 使用默认值
        input=${input:-$default}

        # 如果输入为空且不是必填项，直接返回默认值
        if [ -z "$input" ] && [ "$required" = false ]; then
            echo "$default"
            return 0
        fi

        # 检查必填项
        if [ "$required" = true ] && [ -z "$input" ]; then
            log "WARN" "此项为必填项，请重新输入"
            retry=$((retry - 1))
            continue
        fi

        # 验证输入
        if [ -n "$validate_func" ] && [ -n "$input" ]; then
            if ! $validate_func "$input"; then
                log "WARN" "输入的路径 '$input' 不存在或无效，请重新输入"
                retry=$((retry - 1))
                if [ "$retry" -gt 0 ]; then
                    log "INFO" "剩余重试次数: $retry"
                fi
                continue
            fi
        fi

        echo "$input"
        return 0
    done

    log "ERROR" "已达到最大重试次数"
    return 1
}

# 显示确认对话框
confirm_action() {
    local message=$1
    local default=${2:-"n"}
    local timeout=${3:-0}
    local response

    while true; do
        if [ "$timeout" -gt 0 ]; then
            read -r -p "$message [y/n] ($default) ${timeout}s: " -t "$timeout" response
            if [ $? -ge 128 ]; then
                response="$default"
            fi
        else
            read -r -p "$message [y/n] ($default): " response
        fi

        response=${response:-$default}
        case $response in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) echo "请输入 y 或 n" ;;
        esac
    done
}


# 输入服务名称不带文件后缀
get_service_by_name() {
    local service_input=$1
    local found=false

    while IFS= read -r file; do
        local service_name
        service_name=$(basename "$file" .sh)
        if [ "$service_name" = "$service_input" ]; then
            echo "$service_name"
            found=true
            break
        fi
    done < <(find "${SERVICE_TEMPLATE_PATH}" -name "*.sh" -type f | sort)

    if [ "$found" = true ]; then
        return 0
    else
        return 1
    fi
}