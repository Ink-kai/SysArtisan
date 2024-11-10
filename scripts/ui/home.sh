#!/bin/bash
# 用户界面工具

# 显示菜单标题和系统信息
show_menu_header() {
    clear

    # 显示标题边框
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}"

    # 显示系统信息
    echo -e "${COLOR_YELLOW}系统信息: ${COLOR_RESET}$(uname -s) $(uname -r)"
    echo -e "${COLOR_YELLOW}主机名: ${COLOR_RESET}$(hostname)"
    echo -e "${COLOR_YELLOW}当前用户: ${COLOR_RESET}$(whoami)"
    echo -e "${COLOR_YELLOW}系统时间: ${COLOR_RESET}$(date '+%Y-%m-%d %H:%M:%S')"

    # 显示标题边框
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}"

    # 显示操作提示
    echo -e "\n${COLOR_GREEN}操作说明:${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}[a-e]${COLOR_RESET} - 切换标签"
    echo -e "  ${COLOR_YELLOW}[0-9]${COLOR_RESET} - 执行操作"
    echo -e "  ${COLOR_YELLOW}[q]${COLOR_RESET}   - 退出程序\n"
}

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

# 显示菜单
show_menu() {
    echo -e "\n${COLOR_CYAN}=== 可用操作 ===${COLOR_RESET}"
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}"
    
    # 横排显示主菜单选项
    printf "%-20s" "  ${COLOR_GREEN}1. 安装服务${COLOR_RESET}"
    printf "%-20s" "  ${COLOR_GREEN}2. 卸载服务${COLOR_RESET}"
    printf "%-20s" "  ${COLOR_GREEN}3. 系统管理${COLOR_RESET}"
    printf "%-20s\n" "  ${COLOR_GREEN}4. 配置管理${COLOR_RESET}"
    
    printf "%-20s" "  ${COLOR_GREEN}5. 查看状态${COLOR_RESET}"
    printf "%-20s\n" "  ${COLOR_YELLOW}0. 退出程序${COLOR_RESET}"
    
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}\n"

    [ -z "$1" ] && return

    case "$1" in
    "install")
        show_install_menu_by_template
        ;;
    "uninstall") 
        show_uninstall_menu_by_template
        ;;
    "system")
        show_submenu "系统管理" "系统优化" "清理系统" "更新系统" "返回主菜单"
        ;;
    "config")
        show_submenu "配置管理" "查看配置" "修改配置" "备份配置" "恢复配置" "返回主菜单"
        ;;
    "status")
        show_submenu "状态查看" "系统状态" "服务状态" "资源使用" "查看日志" "返回主菜单"
        ;;
    0)
        return
        ;;
    *)
        log "WARN" "无效的选择: $1"
        ;;
    esac
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

# 显示进度条
show_progress() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local title=${4:-"进度"}

    # 计算百分比
    local percentage=$((current * 100 / total))
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))

    # 构建进度条
    printf "\r%s: [" "$title"
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '-'
    printf "] %3d%%" "$percentage"

    # 完成时换行
    if [ "$current" -eq "$total" ]; then
        echo
    fi
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
                echo
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

# 显示选择列表
show_select_list() {
    local title=$1
    shift
    local options=("$@")
    local selected

    echo -e "\n$title:"
    echo "----------------------------------------"
    for i in "${!options[@]}"; do
        echo "$((i + 1)). ${options[$i]}"
    done
    echo "----------------------------------------"

    while true; do
        read -r -p "请选择 [1-${#options[@]}]: " selected
        if [[ "$selected" =~ ^[0-9]+$ ]] &&
            [ "$selected" -ge 1 ] &&
            [ "$selected" -le "${#options[@]}" ]; then
            return "$((selected - 1))"
        else
            echo "无效的选择，请重试"
        fi
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

# 显示子菜单
show_submenu() {
    local title=$1
    shift
    local options=("$@")

    echo -e "\n${COLOR_CYAN}=== $title ===${COLOR_RESET}"
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}\n"

    local count=1
    local items_per_row=4

    for option in "${options[@]}"; do
        if [[ "$option" == *"返回"* ]]; then
            printf "\n  ${COLOR_YELLOW}0. %-20s${COLOR_RESET}" "$option"
        else
            printf "  ${COLOR_GREEN}%d. %-20s${COLOR_RESET}" "$count" "$option"
            if [ $((count % items_per_row)) -eq 0 ]; then
                echo -e "\n"
            fi
            ((count++))
        fi
    done
    echo -e "\n"
}
show_main_menu() {
    echo -e "\n${COLOR_CYAN}=== 主菜单 ===${COLOR_RESET}"
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}\n"
    
    # 横排显示标签选项
    printf "  ${COLOR_GREEN}[a] %-15s${COLOR_RESET}" "安装服务"
    printf "  ${COLOR_GREEN}[b] %-15s${COLOR_RESET}" "卸载服务" 
    printf "  ${COLOR_GREEN}[c] %-15s${COLOR_RESET}" "系统管理"
    printf "  ${COLOR_GREEN}[d] %-15s${COLOR_RESET}\n" "配置管理"
    
    printf "  ${COLOR_GREEN}[e] %-15s${COLOR_RESET}" "状态查看"
    printf "  ${COLOR_YELLOW}[q] %-15s${COLOR_RESET}\n" "退出程序"
    
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 80))+${COLOR_RESET}\n"
}
