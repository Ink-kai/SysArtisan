#!/bin/bash
# 系统指标收集工具

# 获取CPU使用率
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}'
}

# 获取内存使用率
get_memory_usage() {
    free | grep Mem | awk '{print int($3/$2 * 100)}'
}

# 获取磁盘使用率
get_disk_usage() {
    df -h / | awk 'NR==2 {print int($5)}'
}

# 获取系统负载
get_system_load() {
    uptime | awk -F'load average:' '{ print $2 }' | tr -d ' '
}

# 获取进程数
get_process_count() {
    ps aux | wc -l
}

# 获取网络连接数
get_network_connections() {
    netstat -an | grep ESTABLISHED | wc -l
}

# 检查系统资源
check_system_resources() {
    # 检查CPU核心数
    local cpu_cores
    cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        log "ERROR" "CPU核心数不足: 当前${cpu_cores}核，建议至少2核"
        return 1
    fi

    # 检查内存大小（以MB为单位）
    local mem_total
    mem_total=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$mem_total" -lt 2048 ]; then
        log "ERROR" "内存不足: 当前${mem_total}MB，建议至少2048MB"
        return 1
    fi

    # 检查磁盘空间（根分区，以GB为单位）
    local disk_free
    disk_free=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$disk_free" -lt 10 ]; then
        log "ERROR" "磁盘空间不足: 当前剩余${disk_free}GB，建议至少10GB"
        return 1
    fi

    # 检查系统负载 - 修改不使用 bc 命令
    local load_average
    load_average=$(awk '{print $1}' /proc/loadavg)
    if awk -v load="$load_average" 'BEGIN { exit !(load > 0.9) }'; then
        log "WARN" "系统负载较高: ${load_average}"
    fi

    # 检查打开文件数限制
    local file_limit
    file_limit=$(ulimit -n)
    if [ "$file_limit" -lt 65535 ]; then
        log "WARN" "建议增加系统文件描述符限制: 当前${file_limit}，建议至少65535"
    fi

    log "INFO" "系统资源检查通过"
    return 0
}
