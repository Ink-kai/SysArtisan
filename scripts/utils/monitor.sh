#!/bin/bash
# 监控工具

# 监控系统资源
monitor_system_resources() {
    local interval=${1:-5}
    local count=${2:-12}
    local i=0
    
    echo "系统资源监控 (每${interval}秒更新，共${count}次)"
    echo "----------------------------------------"
    
    while [ $i -lt "$count" ]; do
        clear
        date '+%Y-%m-%d %H:%M:%S'
        echo "----------------------------------------"
        
        # CPU使用率
        echo "CPU使用率:"
        top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4"%"}'
        
        # 内存使用
        echo -e "\n内存使用:"
        free -h | grep -E "Mem|内存"
        
        # 磁盘使用
        echo -e "\n磁盘使用:"
        df -h / | tail -n 1
        
        # 系统负载
        echo -e "\n系统负载:"
        uptime | awk -F'load average:' '{print $2}'
        
        # 网络连接
        echo -e "\n网络连接数:"
        netstat -an | grep ESTABLISHED | wc -l
        
        echo "----------------------------------------"
        i=$((i + 1))
        
        if [ $i -lt "$count" ]; then
            sleep "$interval"
        fi
    done
}

# 监控服务状态
monitor_services() {
    local services=("nginx" "redis" "java")
    local interval=${1:-5}
    local count=${2:-12}
    local i=0
    
    echo "服务状态监控 (每${interval}秒更新，共${count}次)"
    echo "----------------------------------------"
    
    while [ $i -lt "$count" ]; do
        clear
        date '+%Y-%m-%d %H:%M:%S'
        echo "----------------------------------------"
        
        for service in "${services[@]}"; do
            echo -n "$service: "
            case $service in
                "nginx")
                    if systemctl is-active nginx >/dev/null 2>&1; then
                        echo "运行中"
                        nginx -t 2>&1 | grep "successful"
                        echo "工作进程数: $(pgrep -c nginx)"
                    else
                        echo "已停止"
                    fi
                    ;;
                "redis")
                    if systemctl is-active redis >/dev/null 2>&1; then
                        echo "运行中"
                        redis-cli info | grep -E "connected_clients|used_memory_human|total_connections_received"
                    else
                        echo "已停止"
                    fi
                    ;;
                "java")
                    if check_java_process; then
                        echo "运行中"
                        show_java_processes
                    else
                        echo "已停止"
                    fi
                    ;;
            esac
            echo "----------------------------------------"
        done
        
        i=$((i + 1))
        
        if [ $i -lt "$count" ]; then
            sleep "$interval"
        fi
    done
}

# 监控日志
monitor_logs() {
    local log_file=$1
    local pattern=${2:-""}
    local lines=${3:-10}
    
    if [ ! -f "$log_file" ]; then
        log "ERROR" "日志文件不存在: $log_file"
        return 1
    fi
    
    if [ -n "$pattern" ]; then
        tail -f -n "$lines" "$log_file" | grep --line-buffered "$pattern"
    else
        tail -f -n "$lines" "$log_file"
    fi
}

# 监控端口
monitor_ports() {
    local ports=("$@")
    local interval=${1:-5}
    
    echo "端口监控"
    echo "----------------------------------------"
    
    while true; do
        clear
        date '+%Y-%m-%d %H:%M:%S'
        echo "----------------------------------------"
        
        for port in "${ports[@]}"; do
            echo -n "端口 $port: "
            if netstat -tuln | grep -q ":$port "; then
                echo "开放"
                netstat -tuln | grep ":$port "
            else
                echo "关闭"
            fi
        done
        
        echo "----------------------------------------"
        sleep "$interval"
    done
} 