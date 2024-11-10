#!/bin/bash
# Redis服务实现

# 实现安装接口
install_redis() {
    log "INFO" "开始安装Redis服务"
    
    # 1. 检查安装环境
    if ! check_redis_prerequisites; then
        log "ERROR" "Redis安装环境检查失败"
        return 1
    }
    
    # 2. 获取配置
    local version=$(get_config "REDIS_VERSION" "7.0.0")
    local install_dir=$(get_config "REDIS_INSTALL_DIR" "/usr/local/redis")
    local user=$(get_config "REDIS_USER" "redis")
    local group=$(get_config "REDIS_GROUP" "redis")
    local port=$(get_config "REDIS_PORT" "6379")
    
    # 3. 创建用户和组
    if ! create_redis_user "$user" "$group"; then
        log "ERROR" "创建Redis用户失败"
        return 1
    }
    
    # 4. 执行安装
    if ! download_and_install_redis "$version" "$install_dir" "$user" "$group"; then
        log "ERROR" "Redis安装失败"
        return 1
    }
    
    # 5. 配置服务
    if ! configure_redis_service "$install_dir" "$port" "$user"; then
        log "ERROR" "Redis服务配置失败"
        return 1
    }
    
    # 6. 启动服务
    if ! systemctl start redis; then
        log "ERROR" "Redis启动失败"
        return 1
    }
    
    log "INFO" "Redis安装完成"
    return 0
}

# 实现卸载接口
uninstall_redis() {
    log "INFO" "开始卸载Redis服务"
    
    # 1. 停止服务
    systemctl stop redis
    systemctl disable redis
    
    # 2. 删除服务配置
    rm -f "${SYSTEMD_SERVICE_DIR}/redis.service"
    systemctl daemon-reload
    
    # 3. 删除安装目录
    local install_dir=$(get_config "REDIS_INSTALL_DIR" "/usr/local/redis")
    rm -rf "$install_dir"
    
    # 4. 删除配置文件
    rm -f "/etc/redis.conf"
    
    # 5. 删除数据目录
    rm -rf "/var/lib/redis"
    
    # 6. 删除日志目录
    rm -rf "/var/log/redis"
    
    log "INFO" "Redis卸载完成"
    return 0
}

# 实现安装检查接口
is_redis_installed() {
    if command -v redis-server >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# 实现状态检查接口
get_redis_status() {
    if ! is_redis_installed; then
        echo "未安装"
        return 1
    fi
    
    if systemctl is-active redis >/dev/null 2>&1; then
        local version
        version=$(redis-server --version | awk '{print $3}')
        local info
        info=$(redis-cli info | grep -E "connected_clients|used_memory_human|total_connections_received")
        echo "状态: 运行中 - 版本: $version"
        echo "$info"
        return 0
    else
        echo "状态: 已停止"
        return 1
    fi
}

# ===== 内部辅助函数 =====

# 检查安装环境
check_redis_prerequisites() {
    # 检查依赖包
    local dependencies=(
        "gcc"
        "make"
        "tcl"
    )
    
    for dep in "${dependencies[@]}"; do
        if ! install_package "$dep"; then
            log "ERROR" "安装依赖包失败: $dep"
            return 1
        fi
    done
    
    # 检查内存
    if ! check_memory_requirement 512; then
        log "ERROR" "内存不足，需要至少512MB内存"
        return 1
    }
    
    # 检查端口占用
    local port=$(get_config "REDIS_PORT" "6379")
    if ! check_port_available "$port"; then
        log "ERROR" "端口${port}已被占用"
        return 1
    }
    
    return 0
}

# 创建Redis用户
create_redis_user() {
    local user=$1
    local group=$2
    
    if ! getent group "$group" >/dev/null; then
        groupadd "$group"
    fi
    
    if ! getent passwd "$user" >/dev/null; then
        useradd -r -g "$group" -d "/var/lib/redis" -s /sbin/nologin "$user"
    fi
    
    return 0
}

# 下载并安装Redis
download_and_install_redis() {
    local version=$1
    local install_dir=$2
    local user=$3
    local group=$4
    
    # 创建临时目录
    local temp_dir
    temp_dir=$(mktemp -d) || return 1
    
    # 下载源码
    local redis_url="http://download.redis.io/releases/redis-${version}.tar.gz"
    if ! download_file "$redis_url" "$temp_dir/redis.tar.gz"; then
        return 1
    fi
    
    # 解压编译
    cd "$temp_dir" || return 1
    tar xzf "redis.tar.gz"
    cd "redis-${version}" || return 1
    
    # 编译安装
    make -j"$(nproc)" && make install PREFIX="$install_dir" || return 1
    
    # 创建必要目录
    mkdir -p "/var/lib/redis"
    mkdir -p "/var/log/redis"
    chown -R "$user:$group" "/var/lib/redis"
    chown -R "$user:$group" "/var/log/redis"
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    return 0
}

# 配置Redis服务
configure_redis_service() {
    local install_dir=$1
    local port=$2
    local user=$3
    
    # 创建配置文件
    cat > "/etc/redis.conf" << EOF
bind 127.0.0.1
protected-mode yes
port ${port}
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes
supervised systemd
pidfile /var/run/redis/redis.pid
loglevel notice
logfile /var/log/redis/redis.log
databases 16
always-show-logo no
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
replica-priority 100
maxmemory-policy noeviction
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
EOF
    
    # 创建systemd服务配置
    cat > "${SYSTEMD_SERVICE_DIR}/redis.service" << EOF
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=${user}
Group=${user}
ExecStart=${install_dir}/bin/redis-server /etc/redis.conf
ExecStop=${install_dir}/bin/redis-cli shutdown
Type=notify
RuntimeDirectory=redis
RuntimeDirectoryMode=0755
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 设置开机启动
    systemctl enable redis
    
    return 0
}
