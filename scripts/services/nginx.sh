#!/bin/bash
# Nginx服务实现

# 实现安装接口
install_nginx() {
    log "INFO" "安装 Nginx 服务"

    # 1. 检查安装环境
    if ! check_nginx_prerequisites; then
        log "ERROR" "Nginx 安装环境检查失败"
        return 1
    fi

    # 2. 获取配置
    local version=$(get_config "NGINX_VERSION" "1.24.0")
    local install_dir=$(get_config "NGINX_INSTALL_DIR" "/usr/local/nginx")
    local user=$(get_config "NGINX_USER" "nginx")
    local group=$(get_config "NGINX_GROUP" "nginx")

    # 3. 创建用户和组
    if ! create_nginx_user "$user" "$group"; then
        log "ERROR" "创建 Nginx 用户失败"
        return 1
    fi

    # 4. 执行安装
    if ! download_and_install_nginx "$version" "$install_dir" "$user" "$group"; then
        log "ERROR" "安装 Nginx 失败"
        return 1
    fi

    # 5. 配置服务
    if ! configure_nginx_service "$install_dir"; then
        log "ERROR" "Nginx 服务配置失败"
        return 1
    fi

    # 6. 启动服务
    if ! systemctl start nginx; then
        log "ERROR" "启动 Nginx 失败"
        return 1
    fi

    log "INFO" "Nginx 安装完成"
    return 0
}

# 实现卸载接口
uninstall_nginx() {
    log "INFO" "卸载Nginx服务"

    # 1. 停止服务
    systemctl stop nginx
    systemctl disable nginx

    # 2. 删除服务配置
    rm -f "/etc/systemd/system/nginx.service"
    systemctl daemon-reload

    # 3. 删除安装目录
    local install_dir=$(get_config "NGINX_INSTALL_DIR" "/usr/local/nginx")
    rm -rf "$install_dir"

    # 4. 删除配置文件
    rm -rf "/etc/nginx"

    # 5. 删除日志目录
    rm -rf "/var/log/nginx"

    log "INFO" "Nginx 卸载完成"
    return 0
}

# 实现安装检查接口
is_nginx_installed() {
    if command -v nginx >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# 实现状态检查接口
get_nginx_status() {
    if ! is_nginx_installed; then
        echo "未安装"
        return 1
    fi

    local status
    if systemctl is-active nginx >/dev/null 2>&1; then
        status="运行中"
        local version
        version=$(nginx -v 2>&1 | awk -F '/' '{print $2}')
        local workers
        workers=$(pgrep -c nginx)
        echo "状态: $status - 版本: $version - 工作进程: $workers"
        return 0
    else
        status="已停止"
        echo "状态: $status"
        return 1
    fi
}

# ===== 内部辅助函数 =====

# 检查安装环境
check_nginx_prerequisites() {
    # 检查依赖包
    local dependencies=(
        "gcc"
        "pcre-devel"
        "zlib-devel"
        "openssl-devel"
        "make"
    )

    for dep in "${dependencies[@]}"; do
        if ! install_package "$dep"; then
            log "ERROR" "安装依赖包失败: $dep"
            return 1
        fi
    done

    # 检查端口占用
    if ! check_port_available 80; then
        log "ERROR" "端口80已被占用"
        return 1
    fi

    return 0
}

# 创建Nginx用户
create_nginx_user() {
    local user=$1
    local group=$2


    if ! getent group "$group" >/dev/null; then
        groupadd "$group"
    fi

    if ! getent passwd "$user" >/dev/null; then
        useradd -r -g "$group" -s /sbin/nologin "$user"
    fi

    return 0
}

# 下载并安装Nginx
download_and_install_nginx() {
    local version=$1
    local install_dir=$2
    local user=$3
    local group=$4

    # 创建临时目录
    local temp_dir
    temp_dir=$(mktemp -d) || return 1

    # 下载源码
    local nginx_url="http://nginx.org/download/nginx-${version}.tar.gz"
    if ! download_file "$nginx_url" "$temp_dir/nginx.tar.gz"; then
        return 1
    fi

    # 解压编译
    cd "$temp_dir" || return 1
    tar xzf "nginx.tar.gz"
    cd "nginx-${version}" || return 1

    # 配置编译选项
    ./configure \
        --prefix="$install_dir" \
        --user="$user" \
        --group="$group" \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_stub_status_module ||
        return 1

    # 编译安装
    make -j"$(nproc)" && make install || return 1

    # 创建必要目录
    mkdir -p "/var/log/nginx"
    chown -R "$user:$group" "/var/log/nginx"

    # 清理临时文件
    rm -rf "$temp_dir"

    return 0
}

# 配置Nginx服务
configure_nginx_service() {
    local install_dir=$1

    # 创建systemd服务配置
    cat >"/etc/systemd/system/nginx.service" <<EOF
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=${install_dir}/logs/nginx.pid
ExecStartPre=${install_dir}/sbin/nginx -t -c ${install_dir}/conf/nginx.conf
ExecStart=${install_dir}/sbin/nginx -c ${install_dir}/conf/nginx.conf
ExecReload=${install_dir}/sbin/nginx -s reload
ExecStop=${install_dir}/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload

    # 设置开机启动
    systemctl enable nginx

    return 0
}
