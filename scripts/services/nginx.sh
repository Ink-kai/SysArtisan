#!/bin/bash
# Nginx服务实现

# 实现安装接口
install_nginx() {
    if is_nginx_installed; then
        # 是否卸载重新安装
        if confirm_action "Nginx 已安装，是否卸载重新安装？" "n" 20; then
            uninstall_nginx
        else
            log "INFO" "Nginx 取消安装"
            return
        fi
    fi

    # 1. 检查安装环境
    check_nginx_prerequisites || {
        log "ERROR" "Nginx 安装环境检查失败"
        return
    }

    log "INFO" "安装 Nginx 服务"

    # 3. 创建用户和组
    create_nginx_user || {
        log "ERROR" "创建 Nginx 用户失败"
        return
    }

    # 4. 下载源码
    download_nginx_source || {
        log "ERROR" "下载 Nginx 源码失败"
        return
    }

    log "DEBUG" "Nginx 源码下载路径: ${nginx_tmp_dir}"
    log "DEBUG" "Nginx 安装路径: ${NGINX_INSTALL_PATH}"

    # 源码安装
    install_nginx_source "$nginx_tmp_dir" || {
        log "ERROR" "安装 Nginx 源码失败"
        return
    }

    # 配置服务
    configure_nginx_service || {
        log "ERROR" "Nginx 服务配置失败"
        return
    }

    # 配置环境变量
    add_nginx_env || {
        log "ERROR" "Nginx 环境变量配置失败"
        return
    }
    # 启动服务
    start_nginx_service || {
        log "ERROR" "启动 Nginx 失败"
        return
    }

    [ -d "$nginx_tmp_dir" ] && rm -rf "$nginx_tmp_dir"
    log "INFO" "Nginx 安装完成"
}

# 实现卸载接口
uninstall_nginx() {
    if is_nginx_installed; then

        log "INFO" "卸载 Nginx 服务"

        NGINX_INSTALL_PATH=$(dirname "$(find / -name "*nginx*" -type d 2>/dev/null | head -n 1)")

        if [ -z "$NGINX_INSTALL_PATH" ]; then
            log "ERROR" "Nginx 安装路径为空"
        fi

        # 备份
        backup_nginx_config

        # 停止服务
        systemctl stop nginx
        systemctl disable nginx
        find "${SYSTEMD_SERVICE_PATH}" -name "nginx.service" -delete
        systemctl daemon-reload

        # 删除安装目录
        [ -d "$NGINX_INSTALL_PATH" ] && rm -rf "$NGINX_INSTALL_PATH"

        # 删除配置文件
        [ -d "${NGINX_INSTALL_PATH}" ] && rm -rf "${NGINX_INSTALL_PATH}"

        # 删除日志目录
        [ -d "/var/log/nginx" ] && rm -rf "/var/log/nginx"

        # 删除环境变量
        delete_nginx_env

        log "INFO" "Nginx 卸载完成"
    else
        log "INFO" "Nginx 未安装"
    fi

}

# 备份配置
backup_nginx_config() {
    log "DEBUG" "备份 Nginx 配置"
    local nginx_install_dir
    # 获取nginx安装路径
    nginx_install_dir=$(dirname "$NGINX_INSTALL_PATH" | sed 's/\/$//')

    local backup_dir
    backup_dir="${BACKUP_PATH}/$(date +%Y%m%d%H)-${nginx_install_dir:-"nginx"}"
    mkdir -p "$backup_dir"
    # 备份配置文件
    [ -d "${nginx_install_dir}" ] && cp -r "${nginx_install_dir}" "$backup_dir"
    # 备份日志目录
    [ -d "/var/log/nginx" ] && cp -r "/var/log/nginx" "$backup_dir"
    # 备份环境变量
    grep -q "PATH=\$NGINX_INSTALL_PATH\/sbin:\$PATH" "${SYSTEM_PROFILE}" && cp "$SYSTEM_PROFILE" "$backup_dir"
    # 备份服务配置
    [ -f "${SYSTEMD_SERVICE_PATH}/nginx.service" ] && cp "${SYSTEMD_SERVICE_PATH}/nginx.service" "$backup_dir"
    # 备份安装目录
    [ -d "$NGINX_INSTALL_PATH" ] && cp -r "$NGINX_INSTALL_PATH" "$backup_dir"
    # 备份用户和组
    [ -n "$(getent passwd nginx)" ] && cp -r "/etc/passwd" "$backup_dir"
    [ -n "$(getent group nginx)" ] && cp -r "/etc/group" "$backup_dir"
    log "INFO" "Nginx 配置备份路径 ${backup_dir}"
}

# 实现安装检查接口
is_nginx_installed() {
    log "DEBUG" "检查 Nginx 是否安装"

    local installed=false

    # 检查nginx命令是否可执行
    if command -v nginx >/dev/null 2>&1; then
        installed=true
    fi

    # 检查nginx进程是否运行
    if ps -ef | grep -v grep | grep -q nginx; then
        installed=true
    fi

    # 检查安装目录是否存在且非空
    if [ -d "$NGINX_INSTALL_PATH" ] && [ "$(ls -A "$NGINX_INSTALL_PATH" 2>/dev/null)" ]; then
        installed=true
    fi

    # 检查服务是否存在且启用
    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q nginx.service; then
        installed=true
    fi

    $installed && return 0 || return 1
}

# 添加环境变量
add_nginx_env() {
    log "DEBUG" "配置 Nginx 环境变量"

    # 添加软连接
    [ ! -f "$BIN_PATH/nginx" ] && ln -s "$NGINX_INSTALL_PATH/sbin/nginx" "$BIN_PATH/nginx"

    # 添加环境变量
    sed -i "\#PATH=$NGINX_INSTALL_PATH/sbin:\$PATH#d" "$SYSTEM_PROFILE"
    echo "PATH=$NGINX_INSTALL_PATH/sbin:\$PATH" >>"$SYSTEM_PROFILE"

    # 重新加载环境变量
    source "$SYSTEM_PROFILE" >/dev/null 2>&1
}

# 删除环境变量
delete_nginx_env() {
    log "DEBUG" "删除 Nginx 环境变量"

    # 删除软连接
    [ -f "$BIN_PATH/nginx" ] && rm -f "$BIN_PATH/nginx"

    # 删除环境变量 - 修复sed命令的语法
    sed -i "\#NGINX_INSTALL_PATH=#d" "$SYSTEM_PROFILE"
    sed -i "\#PATH=\$NGINX_INSTALL_PATH/sbin:\$PATH#d" "$SYSTEM_PROFILE"

    source "$SYSTEM_PROFILE" >/dev/null 2>&1
}

# ===== 内部辅助函数 =====

# 检查安装环境
check_nginx_prerequisites() {
    # 检查依赖包
    local dependencies
    if [[ "$SYSTEM_OS" == "centos" ]]; then
        dependencies=("${NGINX_DEPENDENCIES["centos"]}")
    elif [[ "$SYSTEM_OS" == "ubuntu" ]]; then
        dependencies=("${NGINX_DEPENDENCIES["ubuntu"]}")
    fi
    local deps_str="${dependencies[*]}"
    check_packages_installed "${dependencies[@]}" || {
        install_package "$deps_str"
    }

    # 检查端口占用
    check_port_available 80 || {
        log "ERROR" "端口80已被占用"
    }
}

# 创建Nginx用户
create_nginx_user() {
    log "DEBUG" "创建 Nginx 用户"

    local user="nginx"
    local group="nginx"

    getent group "$group" >/dev/null || groupadd "$group"

    getent passwd "$user" >/dev/null || useradd -r -g "$group" -s /sbin/nologin "$user"
}

# 下载nginx源码
download_nginx_source() {
    local version="1.24.0"

    # 下载源码
    local nginx_url
    nginx_url="http://nginx.org/download/nginx-${version}.tar.gz"

    NGINX_VERSION=$(basename "$nginx_url" .tar.gz)

    log "DEBUG" "下载 Nginx-${NGINX_VERSION} 源码"

    nginx_tmp_dir=$(mktemp -d)
    download_file "$nginx_url" "$nginx_tmp_dir" || return 1

    NGINX_INSTALL_PATH="${INSTALL_PATH}/$(basename "$nginx_url" .tar.gz)"
}

# 源码安装Nginx
install_nginx_source() {
    # 检查源码文件是否存在（模糊匹配）
    local nginx_source_file
    nginx_source_file=$(find "$nginx_tmp_dir" -name "nginx*.tar.gz")
    [ -n "$nginx_source_file" ] || {
        log "ERROR" "源码文件不存在"
        return 1
    }

    log "DEBUG" "源码安装 Nginx"
    # 解压编译
    cd "$nginx_tmp_dir" && tar xzf "$nginx_source_file"

    cd nginx-* || {
        log "ERROR" "进入源码目录失败"
        return 1
    }

    # 配置编译选项
    ./configure \
        --prefix="$NGINX_INSTALL_PATH" \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_stub_status_module >/dev/null 2>&1 || {
        log "ERROR" "编译失败"
        return 1
    }

    # 编译安装
    make >/dev/null 2>&1 || {
        log "ERROR" "编译失败"
        return 1
    }
    make install >/dev/null 2>&1 || {
        log "ERROR" "安装失败"
        return 1
    }

    # 创建必要目录
    mkdir -p "/var/log/nginx"
    chown -R "nginx:nginx" "/var/log/nginx"
}

# 配置Nginx服务
configure_nginx_service() {
    log "DEBUG" "配置 Nginx 服务"

    mkdir -p "${NGINX_INSTALL_PATH}/logs"
    chown -R nginx:nginx "${NGINX_INSTALL_PATH}/logs"
    chmod 755 "${NGINX_INSTALL_PATH}/logs"

    # 创建systemd服务配置
    cat >"${SYSTEMD_SERVICE_PATH}/nginx.service" <<EOF
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=${NGINX_INSTALL_PATH}/logs/nginx.pid
ExecStartPre=${BIN_PATH}/nginx -t -c ${NGINX_INSTALL_PATH}/conf/nginx.conf
ExecStart=${BIN_PATH}/nginx -c ${NGINX_INSTALL_PATH}/conf/nginx.conf
ExecReload=${BIN_PATH}/nginx -s reload
ExecStop=${BIN_PATH}/nginx -s stop
KillSignal=SIGQUIT
TimeoutStopSec=5
PrivateTmp=true
User=nginx
Group=nginx

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload 2>&1 || {
        log "ERROR" "重新加载systemd配置失败"
    }

    # 设置开机启动
    systemctl enable nginx 2>&1 || {
        log "ERROR" "设置开机启动失败"
    }
}

# 添加新的启动函数
start_nginx_service() {
    command -v systemctl >/dev/null 2>&1 && systemctl daemon-reexec >/dev/null 2>&1 && {
        systemctl start nginx
    }

    # 检查 nginx 是否成功运行
    pgrep nginx >/dev/null && return 0
}
