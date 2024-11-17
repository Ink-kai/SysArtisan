#!/bin/bash
# 系统工具

# shellcheck disable=SC2155

# 补充lsb标准
check_lsb() {
    if ! command -v lsb_release &>/dev/null; then
        # 安装lsb_release
        log "INFO" "安装 lsb_release"
        [ "$SYSTEM_OS" == "centos" ] && yum install -y redhat-lsb-core 2>/dev/null || exit 1
        [ "$SYSTEM_OS" == "ubuntu" ] && apt install -y lsb-release 2>/dev/null || exit 1
    fi
}

# 清理系统
cleanup_system() {
    log "INFO" "系统清理"

    # 清理包缓存
    clean_package_cache

    # 清理临时文件
    clean_temp_file

    # 清理系统缓存
    sync && echo 3 >/proc/sys/vm/drop_caches

    log "INFO" "系统清理完成"
}

# 清理临时文件
clean_temp_file() {
    rm -rf "${TEMP_PATH:?}"/*

    # 清理日志
    find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
    find /var/log -type f -name "*.gz" -delete
}

# 获取操作系统类型
get_os() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$ID" in
        "centos" | "rhel")
            SYSTEM_OS="centos"
            ;;
        "ubuntu" | "debian")
            SYSTEM_OS="ubuntu"
            ;;
        esac
    elif [ -f /etc/redhat-release ]; then
        SYSTEM_OS="centos"
    elif [ -f /etc/lsb-release ]; then
        SYSTEM_OS="ubuntu"
    fi
}

# 获取系统版本
get_os_version() {
    if [ -f /etc/os-release ]; then
        grep -oP '(?<=VERSION_ID=")[^"]*' /etc/os-release
    else
        echo "unknown"
    fi
}

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log "ERROR" "请使用root权限运行此脚本"
        return 1
    fi
    return 0
}

# 执行命令
execute_command() {
    local command=$1
    local error_msg=${2:-"命令执行失败"}
    local timeout=${3:-300}
    local show_output=${4:-false}

    log "DEBUG" "执行命令: $command"

    if [ "$show_output" = true ]; then
        # 显示命令输出
        if timeout "$timeout" bash -c "$command"; then
            return 0
        else
            log "ERROR" "$error_msg"
            return 1
        fi
    else
        # 不显示命令输出
        if timeout "$timeout" bash -c "$command" >/dev/null 2>&1; then
            return 0
        else
            log "ERROR" "$error_msg"
            return 1
        fi
    fi
}

# 获取所有网卡IP地址
get_ip() {
    # 获取所有网卡IP地址,排除回环地址
    local ip_list
    ip_list=$(ip addr show |
        grep "inet " |
        grep -v "127.0.0.1" |
        awk '{print $2}' |
        cut -d/ -f1)

    # 格式化输出IP地址列表
    printf "${COLOR_YELLOW}IP地址: ${COLOR_RESET}%s\n" "$ip_list"
}

# 获取CPU架构
get_cpu_arch() {
    printf "${COLOR_YELLOW}CPU架构: ${COLOR_RESET}%s\n" "$(uname -m)"
}

# 获取CPU型号
get_cpu_model() {
    # 字符串前后有空格,使用awk去除
    printf "${COLOR_YELLOW}CPU型号: ${COLOR_RESET}%s\n" "$(lscpu | grep "Model name" | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')"
}

# 获取CPU核心数/型号/使用率/逻辑CPU数/物理CPU数
get_cpu_info() {
    local cpu_cores=$(nproc)
    # 使用awk去除空格
    local cpu_usage_rate=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4"%"}' | awk '{print $1}')
    local cpu_logical_cores=$(lscpu | grep "CPU(s):" | awk -F: '{print $2}' | awk '{print $1}')
    local cpu_physical_cores=$(lscpu | grep "Core(s) per socket:" | awk -F: '{print $2}' | awk '{print $1}')
    printf "${COLOR_YELLOW}%-15s%-10s%-15s%-10s%-15s%-10s%-15s%-10s${COLOR_RESET}\n" "CPU核心数:" "$cpu_cores" "CPU使用率:" "$cpu_usage_rate" "逻辑CPU数:" "$cpu_logical_cores" "物理CPU数:" "$cpu_physical_cores"
}

# 获取内存信息
get_memory_info() {
    # 获取内存信息
    local total_memory used_memory free_memory usage_rate
    total_memory=$(free -h | awk '/^Mem:/{print $2}')
    used_memory=$(free -h | awk '/^Mem:/{print $3}')
    free_memory=$(free -h | awk '/^Mem:/{print $4}')
    usage_rate=$(free | awk '/^Mem:/{printf "%.2f", $3/$2*100}')

    # 获取交换分区信息
    local swap_total swap_used swap_free swap_usage_rate
    swap_total=$(free -h | awk '/^Swap:/{print $2}')
    swap_used=$(free -h | awk '/^Swap:/{print $3}')
    swap_free=$(free -h | awk '/^Swap:/{print $4}')
    swap_usage_rate=$(free | awk '/^Swap:/{if($2>0) printf "%.2f", $3/$2*100; else print "0"}')

    # 输出信息
    printf "${COLOR_YELLOW}%-15s%-10s%-15s%-10s%-15s%-10s%-15s%-10s${COLOR_RESET}\n" "内存总量:" "$total_memory" "已用内存:" "$used_memory" "可用内存:" "$free_memory" "内存使用率:" "${usage_rate}%"
    printf "${COLOR_YELLOW}%-15s%-10s%-15s%-10s%-15s%-10s%-15s%-10s${COLOR_RESET}\n" "交换分区:" "$swap_total" "已用交换:" "$swap_used" "可用交换:" "$swap_free" "交换使用率:" "${swap_usage_rate}%"
}

# 获取磁盘信息
get_disk_info() {
    df -h
}

# 系统优化
optimize_system() {
    # 安装必要的包
    update_package_manager

    install_package "bc build-essential libpcre3-dev zlib1g-dev"
    # 设置系统限制
    cat >/etc/security/limits.conf >/dev/null 2>&1 <<EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

    # 优化内核参数（不显示执行过程）
    cat >/etc/sysctl.d/99-system.conf >/dev/null 2>&1 <<EOF
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
vm.swappiness = 10
vm.max_map_count = 262144
fs.file-max = 65535
EOF

    sysctl -p /etc/sysctl.d/99-system.conf >/dev/null 2>&1
    log "INFO" "系统优化完成"
}

# 检查系统环境
check_environment() {
    # 检查root权限
    check_root || {
        log "ERROR" "请使用root权限运行此脚本"
        return 1
    }
    get_os

    log "INFO" "检测到操作系统类型: $SYSTEM_OS"

    # 检查必要命令
    local required_commands=("wget" "tar" "systemctl" "grep" "awk" "sed")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "缺少必要的命令: $cmd"
            return 1
        fi
    done

    # 检查网络连接
    check_network &
}

# 显示资源使用情况
show_resource_usage() {
    echo -e "\n系统资源使用情况:"
    echo "----------------------------------------"

    # CPU使用率
    echo "CPU使用率:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4"%"}'

    # 内存使用情况
    echo -e "\n内存使用情况:"
    free -h

    # 磁盘使用情况
    echo -e "\n磁盘使用情况:"
    df -h /

    # 显示占用CPU最多的进程
    echo -e "\n占用CPU最多的进程:"
    ps aux | sort -rn -k 3 | head -5

    # 显示占用内存最多的进程
    echo -e "\n占用内存最多的进程:"
    ps aux | sort -rn -k 4 | head -5

    # IO使用情况
    echo -e "\nIO使用情况:"
    iostat -x 1 2 | tail -n +6

    echo "----------------------------------------"
}

# 检查系统架构
check_system_arch() {
    local required_arch=$1
    local current_arch
    current_arch=$(uname -m)

    if [ "$current_arch" != "$required_arch" ]; then
        log "ERROR" "系统架构不匹配: 需要 $required_arch，当前为 $current_arch"
        return 1
    fi

    log "DEBUG" "系统架构检查通过: $current_arch"
    return 0
}

# 检查系统内存
check_system_memory() {
    local required_mb=$1
    local total_memory
    total_memory=$(free -m | awk '/^Mem:/{print $2}')

    if [ "$total_memory" -lt "$required_mb" ]; then
        log "ERROR" "内存不足: 需要 ${required_mb}MB，当前为 ${total_memory}MB"
        return 1
    fi

    log "DEBUG" "内存检查通过: ${total_memory}MB"
    return 0
}

# 检查磁盘空间
check_disk_space() {
    local mount_point=$1
    local required_mb=$2
    local available_mb

    # 获取指定挂载点的可用空间(MB)
    available_mb=$(df -m "$mount_point" | awk 'NR==2 {print $4}')

    if [ "$available_mb" -lt "$required_mb" ]; then
        log "ERROR" "磁盘空间不足: $mount_point 需要 ${required_mb}MB，当前可用 ${available_mb}MB"
        return 1
    fi

    log "DEBUG" "磁盘空间检查通过: $mount_point 可用 ${available_mb}MB"
    return 0
}

# 重载系统守护进程
system_daemon_reload() {
    systemctl daemon-reload
}

# 系统是否支持selinux
check_selinux() {
    if sestatus | grep "enabled" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# 添加：设置tab补全功能
setup_tab_completion() {
    # 定义补全函数
    _custom_completion() {
        local cur=${COMP_WORDS[COMP_CWORD]}
        local prev=${COMP_WORDS[COMP_CWORD - 1]}

        case "$prev" in
        -f | --file)
            # 文件补全
            mapfile -t COMPREPLY < <(compgen -f -- "$cur")
            ;;
        -d | --directory)
            # 目录补全
            mapfile -t COMPREPLY < <(compgen -d -- "$cur")
            ;;
        *)
            # 默认补全
            mapfile -t COMPREPLY < <(compgen -f -d -- "$cur")
            ;;
        esac
    }

    # 注册补全函数
    complete -F _custom_completion -o default read
}

# 调用设置函数
setup_tab_completion

# 清理环境
cleanup_environment() {
    # 清理临时目录
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"

    # 恢复系统设置
    restore_system_settings

    log "DEBUG" "环境清理完成"
    return 0
}

# 恢复系统设置
restore_system_settings() {
    # 恢复系统限制
    if [ -f "/etc/security/limits.d/temp.conf" ]; then
        rm -f "/etc/security/limits.d/temp.conf"
    fi

    # 恢复系统参数
    if [ -f "/etc/sysctl.d/99-temp.conf" ]; then
        rm -f "/etc/sysctl.d/99-temp.conf"
    fi
}

# 初始化环境
init_environment() {
    # 检查系统环境
    check_environment || {
        log "ERROR" "系统环境检查失败"
        return 1
    }

    # 检查系统资源
    check_system_resources || {
        log "ERROR" "系统资源检查失败"
        return 1
    }

    # 创建必要的目录
    TEMP_DIR=$(mktemp -d) || {
        log "ERROR" "无法创建临时目录: ${TEMP_DIR}"
        return 1
    }

    # 设置系统参数
    setup_system_params || {
        log "ERROR" "设置系统参数失败"
        return 1
    }

    return 0
}

# 设置系统参数
setup_system_params() {
    # 设置文件描述符限制
    if check_system_arch "x86_64"; then
        if [ "$(ulimit -n)" -lt 65535 ]; then
            ulimit -n 65535 || log "WARN" "无法设置文件描述符限制"
        fi
    fi

    return 0
}
