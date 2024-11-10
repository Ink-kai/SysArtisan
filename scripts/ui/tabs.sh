#!/bin/bash
# Tab式菜单实现

# 定义界面常量
declare -rx SCREEN_WIDTH=80
declare -rx CONTENT_WIDTH=60
declare -rx STATUS_HEIGHT=5
declare -rx LOG_HEIGHT=3

# 定义Tab标题颜色
declare -rx TAB_ACTIVE="${COLOR_BLUE}${BOLD}"
declare -rx TAB_INACTIVE="${COLOR_RESET}"
declare -rx BORDER_COLOR="${COLOR_BLUE}"

# Tab菜单状态
declare -A TAB_STATE=(
    ["current_tab"]="install"
    ["last_tab"]=""
)

# 绘制标签页
draw_tabs() {
    local current_tab=$1

    # 显示标题和系统信息
    show_header

    # 绘制标签栏
    echo -ne "${COLOR_CYAN}|${COLOR_RESET}"
    local tabs=("a 安装" "b 卸载" "c 系统" "d 配置" "e 状态")

    # 计算间距使标签均匀分布
    local spacing=$(((SCREEN_WIDTH - 2) / ${#tabs[@]}))

    local i=1
    for tab in "${tabs[@]}"; do
        # 居中对齐每个标签
        local pad_left=$(((spacing - ${#tab}) / 2))
        printf "%${pad_left}s" ""

        if [ "$current_tab" = "${TAB_MAP[$i]}" ]; then
            echo -ne "${COLOR_GREEN}【$tab】${COLOR_RESET}"
        else
            echo -ne "${COLOR_YELLOW} $tab ${COLOR_RESET}"
        fi

        local pad_right=$((spacing - ${#tab} - pad_left))
        printf "%${pad_right}s" ""
        ((i++))
    done

    echo -e "${COLOR_CYAN}|${COLOR_RESET}"
    echo -e "${COLOR_CYAN}+$(printf '=%.0s' $(seq 1 $SCREEN_WIDTH))+${COLOR_RESET}\n"
}

# 处理Tab切换
handle_tab_switch() {
    local key=$1
    case "$key" in
    1) TAB_STATE["current_tab"]="install" ;;
    2) TAB_STATE["current_tab"]="uninstall" ;;
    3) TAB_STATE["current_tab"]="system" ;;
    4) TAB_STATE["current_tab"]="config" ;;
    5) TAB_STATE["current_tab"]="status" ;;
    *) return 1 ;;
    esac
    echo -e "\n"
    return 0
}

# 处理安装操作
handle_install_operation() {
    local choice=$1
    if [ "$choice" = "0" ]; then
        return 0
    fi
    echo -e "\n${COLOR_CYAN}=== 已安装的服务 ===${COLOR_RESET}\n"
    # 获取所有可用服务
    local services
    services=($(get_available_services))

    if [ "$choice" -gt 0 ] && [ "$choice" -le "${#services[@]}" ]; then
        local service_name="${services[$((choice - 1))]}"
        install_service "$service_name"
    else
        log "ERROR" "无效的选择: $choice"
    fi
}

# 处理卸载操作
handle_uninstall_operation() {
    local choice=$1
    if [ "$choice" = "0" ]; then
        return 0
    fi

    echo -e "\n${COLOR_CYAN}=== 可卸载的服务 ===${COLOR_RESET}\n"
    # 获取已安装服务列表
    local services
    services=($(get_installed_services))

    # 检查选择是否有效
    if [ "$choice" -gt 0 ] && [ "$choice" -le "${#services[@]}" ]; then
        local service_name="${services[$((choice - 1))]}"
        uninstall_service "$service_name"
    else
        log "ERROR" "无效的选择: $choice"
    fi
}

# 处理系统操作
handle_system_operation() {
    local choice=$1
    case "$choice" in
    1) optimize_system ;;
    2) cleanup_system ;;
    3) update_system ;;
    4) show_system_info ;;
    0) return 0 ;;
    *) log "ERROR" "无效的选择: $choice" ;;
    esac
}

# 处理配置操作
handle_config_operation() {
    local choice=$1
    case "$choice" in
    1) show_config ;;
    2) edit_config ;;
    3) backup_config ;;
    4) restore_config ;;
    0) return 0 ;;
    *) log "ERROR" "无效的选择: $choice" ;;
    esac
}

# 处理状态操作
handle_status_operation() {
    local choice=$1
    case "$choice" in
    1) show_system_status ;;
    2) show_service_status ;;
    3) show_resource_usage ;;
    4) show_logs ;;
    0) return 0 ;;
    *) log "ERROR" "无效的选择: $choice" ;;
    esac
}

# 主菜单循环
main_menu_loop() {
    while true; do
        clear_screen

        # 如果是主菜单状态,显示主菜单
        if [ "${TAB_STATE["current_tab"]}" = "main" ]; then
            show_menu_header
            show_main_menu
        else
            # 显示菜单标题
            show_menu_header

            # 绘制标签
            draw_tabs "${TAB_STATE["current_tab"]}"

            # 显示标签内容
            show_tab_content
        fi

        echo -e "\n${COLOR_YELLOW}请输入您的选择 [字母切换标签, 数字执行操作, q退出]:${COLOR_RESET}"
        read -rsn1 choice

        case "$choice" in
        [a-e])
            # 将字母映射到标签索引
            case "$choice" in
            a) handle_tab_switch 1 ;; # 安装
            b) handle_tab_switch 2 ;; # 卸载
            c) handle_tab_switch 3 ;; # 系统
            d) handle_tab_switch 4 ;; # 配置
            e) handle_tab_switch 5 ;; # 状态
            esac
            ;;
        [0-9])
            echo "$choice"
            handle_operation "$choice"
            echo -e "\n${COLOR_GREEN}按任意键继续${COLOR_RESET}"
            read -rsn1
            ;;
        q | Q)
            break
            ;;
        *)
            log "WARN" "无效的选择: $choice"
            sleep 1
            ;;
        esac
    done
}

# 显示标签页内容
show_tab_content() {
    local current_tab=${TAB_STATE["current_tab"]}

    case "$current_tab" in
    "install")
        show_install_content
        ;;
    "uninstall")
        show_uninstall_content
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

# 显示操作结果
show_operation_result() {
    local success=$1
    local message=$2

    echo -e "\n"
    if [ "$success" -eq 0 ]; then
        echo -e "${COLOR_GREEN}✓ 操作成功: ${message}${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}✗ 操作失败: ${message}${COLOR_RESET}"
    fi
    echo -e "\n"
}

# 修改handle_operation函数，添加结果显示
handle_operation() {
    local current_tab=${TAB_STATE["current_tab"]}
    local choice=$1
    local result=0

    # 处理返回主菜单
    if [ "$choice" = "0" ]; then
        # 清除当前标签状态
        TAB_STATE["last_tab"]=${TAB_STATE["current_tab"]}
        TAB_STATE["current_tab"]="main"
        return 0
    fi

    case "$current_tab" in
    "install")
        handle_install_operation "$choice"
        result=$?
        ;;

    "uninstall")
        handle_uninstall_operation "$choice"
        ;;
    "system")
        handle_system_operation "$choice"
        ;;
    "config")
        handle_config_operation "$choice"
        ;;
    "status")
        handle_status_operation "$choice"
        ;;
    esac

    show_operation_result "$result" "$(get_operation_message "$current_tab" "$choice")"
    return $result
}

# 获取操作结果消息
get_operation_message() {
    local tab=$1
    local choice=$2

    case "$tab" in
    "install")
        case "$choice" in
        0) echo "返回主菜单" ;;
        *)
            # 获取服务列表
            local services=()
            while IFS= read -r -d '' file; do
                local service_name
                service_name=$(basename "$file" .sh)
                services+=("$service_name")
            done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)

            if [ "$choice" -gt 0 ] && [ "$choice" -le "${#services[@]}" ]; then
                echo "安装服务: ${services[$((choice - 1))]}"
            else
                echo "无效的选择"
            fi
            ;;
        esac
        ;;

    "uninstall")
        case "$choice" in
        0) echo "返回主菜单" ;;
        *)
            # 获取已安装服务列表
            local services=()
            while IFS= read -r -d '' file; do
                local service_name
                service_name=$(basename "$file" .sh)
                if is_service_installed "$service_name"; then
                    services+=("$service_name")
                fi
            done < <(find "${SERVICE_TEMPLATE_PATH}" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null | sort -z)

            if [ "$choice" -gt 0 ] && [ "$choice" -le "${#services[@]}" ]; then
                echo "卸载服务: ${services[$((choice - 1))]}"
            else
                echo "无效的选择"
            fi
            ;;
        esac
        ;;

    "system")
        case "$choice" in
        0) echo "返回主菜单" ;;
        1) echo "执行系统优化" ;;
        2) echo "执行系统清理" ;;
        3) echo "执行系统更新" ;;
        4) echo "查看系统信息" ;;
        *) echo "无效的选择" ;;
        esac
        ;;

    "config")
        case "$choice" in
        0) echo "返回主菜单" ;;
        1) echo "查看配置信息" ;;
        2) echo "修改配置信息" ;;
        3) echo "备份配置信息" ;;
        4) echo "恢复配置信息" ;;
        *) echo "无效的选择" ;;
        esac
        ;;

    "status")
        case "$choice" in
        0) echo "返回主菜单" ;;
        1) echo "查看系统状态" ;;
        2) echo "查看服务状态" ;;
        3) echo "查看资源使用" ;;
        4) echo "查看系统日志" ;;
        *) echo "无效的选择" ;;
        esac
        ;;

    *)
        echo "未知的操作类型"
        ;;
    esac
}
