#!/bin/bash
set -e

# 定义脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 基础颜色
COLOR_RESET="\033[0m"
COLOR_BLACK="\033[30m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_PURPLE="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_WHITE="\033[37m"

# 错误处理
trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# 异常退出处理
# trap 'handle_exit $?' EXIT

handle_error() {
    local exit_code=$1
    local line_no=$2
    local last_command=$3
    local func_trace=$4

    log "ERROR" "错误发生在第 $line_no 行: '$last_command' (退出码: $exit_code)"
    log "ERROR" "函数调用栈: $func_trace"

    exit "$exit_code"
}

handle_exit() {
    local exit_code=$1

    # 清理临时文件
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"

    if [ "$exit_code" -ne 0 ]; then
        log "ERROR" "程序异常退出，退出码: $exit_code"
    fi
}

# 加载日志模块
source "${SCRIPT_DIR}/utils/logger.sh" || {
    echo "ERROR: 无法加载日志模块"
    exit 1
}

# 加载模块加载器
source "${SCRIPT_DIR}/utils/module_loader.sh" || {
    echo "ERROR: 无法加载模块加载器"
    exit 1
}

# 定义模块目录（数组）
MODULES_DIR=(
    "${SCRIPT_DIR}/config"
    "${SCRIPT_DIR}/utils"
    "${SCRIPT_DIR}/ui"
    "${SCRIPT_DIR}/core"
)

# 动态加载所有系统模块
for module_path in "${MODULES_DIR[@]}"; do
    load_system_modules "$module_path" || {
        log "ERROR" "加载系统模块失败: $module_path"
        exit 1
    }
done

# 主函数
main() {
    # 初始化环境
    init_environment || {
        log "ERROR" "环境初始化失败"
        exit 1
    }

    # 初始化UI
    init_ui || {
        log "ERROR" "初始化UI失败"
        exit 1
    }

    # services具体服务方法（出错继续）
    load_system_modules "${SCRIPT_DIR}/services" 1  

    # 显示Tab式菜单
    main_menu_loop

    # 清理
    cleanup_ui
    cleanup_environment

    return 0
}

# 执行主函数
main "$@"
