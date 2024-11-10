#!/bin/bash
# 网络工具

# 检查网络连接 不影响下一步执行
check_network() {
    local test_hosts=(
        "www.baidu.com"
        "www.aliyun.com"
        "www.qq.com"
    )
    local success=false
    local failed_hosts=()

    log "INFO" "检查网络连接"

    for host in "${test_hosts[@]}"; do
        if timeout "$NETWORK_TIMEOUT" ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
            success=true
            log "DEBUG" "成功连接到 $host"
            break
        else
            failed_hosts+=("$host")
            log "DEBUG" "无法连接到 $host"
        fi
    done

    if [ "$success" = true ]; then
        log "INFO" "网络连接正常"
        return 0
    else
        log "ERROR" "网络连接异常，所有测试主机均无法访问: ${failed_hosts[*]}"
        return 0
    fi
}

# 下载文件
download_file() {
    local url=$1
    local output=$2
    local retries=${3:-$MAX_RETRIES}
    local timeout=${4:-$DOWNLOAD_TIMEOUT}

    log "INFO" "下载文件: $url"

    # 创建临时文件
    local temp_file
    temp_file=$(mktemp)

    local attempt=0
    while [ "$attempt" -lt "$retries" ]; do
        attempt=$((attempt + 1))

        if [ "$attempt" -gt 1 ]; then
            log "INFO" "第 $attempt 次尝试下载"
            sleep "$RETRY_INTERVAL"
        fi

        if wget --timeout="$timeout" \
            --tries=1 \
            --quiet \
            --show-progress \
            --progress=bar:force:noscroll \
            "$url" \
            -O "$temp_file"; then

            # 验证下载的文件
            if [ -s "$temp_file" ]; then
                mv "$temp_file" "$output"
                chmod 644 "$output"
                return 0
            else
                log "WARN" "下载的文件为空"
                rm -f "$temp_file"
            fi
        else
            log "WARN" "下载失败"
            rm -f "$temp_file"
        fi
    done

    log "ERROR" "文件下载失败，已重试 $retries 次"
    return 1
}

check_port_available() {
    local port=$1
    local bind_address=${2:-"0.0.0.0"}

    if netstat -tln | grep -q "${bind_address}:${port} "; then
        log "DEBUG" "端口 $port 已被占用"
        return 1
    fi

    return 0
}

# 批量检查端口是否可用
check_ports_available() {
    local port
    for port in "$@"; do
        if ! check_port_available "$port"; then
            log "ERROR" "端口 $port 已被占用"
            return 1
        fi
    done
    return 0
}

# 获取本机IP
get_local_ip() {
    local interface=${1:-""}
    local ip

    if [ -n "$interface" ]; then
        ip=$(ip -4 addr show "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    else
        ip=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    fi

    if [ -n "$ip" ]; then
        log "INFO" "本机IP地址: $ip"
        return 0
    else
        log "ERROR" "无法获取本机IP地址"
        return 1
    fi
}

# 检查防火墙状态
check_firewall() {
    case "$SYSTEM_OS" in
    "centos")
        if systemctl is-active firewalld >/dev/null 2>&1; then
            log "INFO" "防火墙状态: firewalld"
            return 0
        fi
        ;;
    "ubuntu")
        if systemctl is-active ufw >/dev/null 2>&1; then
            log "INFO" "防火墙状态: ufw"
            return 0
        fi
        ;;
    esac

    return 1
}

# 防火墙规则移除
remove_firewall_rule() {
    local port=$1
    local protocol=${2:-"tcp"}

    case "$SYSTEM_OS" in
    "centos")
        firewall-cmd --permanent --remove-port="${port}/${protocol}"
        firewall-cmd --reload
        ;;
    "ubuntu")
        ufw delete allow "$port/$protocol"
        ;;
    *)
        log "WARN" "未检测到活动的防火墙服务"
        return 0
        ;;
    esac
}

# 配置防火墙
configure_firewall() {
    local port=$1
    local protocol=${2:-"tcp"}
    local description=${3:-""}

    local firewall_type
    firewall_type=$(check_firewall)

    case "$firewall_type" in
    "firewalld")
        for zone in "${FIREWALL_ZONES[@]}"; do
            firewall-cmd --permanent --zone="$zone" --add-port="${port}/${protocol}" \
                --add-rich-rule="rule family=\"ipv4\" port port=\"${port}\" protocol=\"${protocol}\" accept"
        done
        firewall-cmd --reload
        ;;
    "ufw")
        ufw allow "$port/$protocol"
        ;;
    *)
        log "WARN" "未检测到活动的防火墙服务"
        return 0
        ;;
    esac

    log "INFO" "防火墙规则已添加: ${port}/${protocol}"
    return 0
}

# 检查域名解析
check_dns() {
    local domain=$1
    local expected_ip=${2:-""}

    if ! validate_domain "$domain"; then
        log "ERROR" "无效的域名: $domain"
        return 1
    fi

    local resolved_ip
    resolved_ip=$(dig +short "$domain" | grep -oP '^\d+(\.\d+){3}$' | head -n 1)

    if [ -z "$resolved_ip" ]; then
        log "ERROR" "无法解析域名: $domain"
        return 1
    fi

    if [ -n "$expected_ip" ] && [ "$resolved_ip" != "$expected_ip" ]; then
        log "ERROR" "域名 $domain 解析到 $resolved_ip，期望 $expected_ip"
        return 1
    fi

    log "DEBUG" "域名 $domain 解析正常: $resolved_ip"
    return 0
}

# 测试网络连接性
test_connectivity() {
    local host=$1
    local port=$2
    local timeout=${3:-5}

    if ! validate_port "$port"; then
        log "ERROR" "无效的端口号: $port"
        return 1
    fi

    if timeout "$timeout" nc -zv "$host" "$port" >/dev/null 2>&1; then
        log "DEBUG" "可以连接到 ${host}:${port}"
        return 0
    else
        log "ERROR" "无法连接到 ${host}:${port}"
        return 1
    fi
}

# 获取公网IP
get_public_ip() {
    local ip_services=(
        "https://api.ipify.org"
        "https://ifconfig.me"
        "https://icanhazip.com"
    )

    for service in "${ip_services[@]}"; do
        local public_ip
        public_ip=$(curl -s --connect-timeout 5 "$service")

        if [[ "$public_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$public_ip"
            return 0
        fi
    done

    log "ERROR" "无法获取公网IP地址"
    return 1
}

# 检查服务端口
check_service_ports() {
    local service_name=$1
    local bind_address=${2:-"0.0.0.0"}

    case $service_name in
    "nginx")
        local http_port=$(get_config "NGINX_HTTP_PORT" "80")
        local https_port=$(get_config "NGINX_HTTPS_PORT" "443")

        if ! check_port_available "$http_port" "$bind_address"; then
            log "ERROR" "Nginx HTTP端口 $http_port 已被占用"
            return 1
        fi

        if ! check_port_available "$https_port" "$bind_address"; then
            log "ERROR" "Nginx HTTPS端口 $https_port 已被占用"
            return 1
        fi
        ;;

    "redis")
        local redis_port=$(get_config "REDIS_PORT" "6379")

        if ! check_port_available "$redis_port" "$bind_address"; then
            log "ERROR" "Redis端口 $redis_port 已被占用"
            return 1
        fi
        ;;

    *)
        log "WARN" "未定义端口检查方法: $service_name"
        return 0
        ;;
    esac

    return 0
}
