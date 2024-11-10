#!/bin/bash
# Java服务实现

# 实现安装接口
install_java() {
    log "INFO" "开始安装Java服务"
    
    # 1. 检查安装环境
    if ! check_java_prerequisites; then
        log "ERROR" "Java安装环境检查失败"
        return 1
    fi
    
    # 2. 获取配置
    local version=$(get_config "JAVA_VERSION" "11")
    local install_dir=$(get_config "JAVA_INSTALL_DIR" "/usr/local/java")
    
    # 3. 执行安装
    if ! download_and_install_java "$version" "$install_dir"; then
        log "ERROR" "Java安装失败"
        return 1
    fi
    
    # 4. 配置环境
    if ! configure_java_env "$install_dir"; then
        log "ERROR" "Java环境配置失败"
        return 1
    fi
    
    log "INFO" "Java安装完成"
    return 0
}

# 实现卸载接口
uninstall_java() {
    log "INFO" "开始卸载Java服务"
    
    # 1. 清理环境变量
    clean_java_env
    
    # 2. 删除安装目录
    local install_dir=$(get_config "JAVA_INSTALL_DIR" "/usr/local/java")
    rm -rf "$install_dir"
    
    log "INFO" "Java卸载完成"
    return 0
}

# 实现安装检查接口
is_java_installed() {
    if command -v java >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# 实现状态检查接口
get_java_status() {
    if ! is_java_installed; then
        echo "未安装"
        return 1
    fi
    
    local version
    version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "已安装 - 版本: $version"
    return 0
}

# ===== 内部辅助函数 =====

# 检查安装环境
check_java_prerequisites() {
    # 检查内存
    if ! check_memory_requirement 1024; then
        return 1
    fi
    
    # 检查磁盘空间
    if ! check_disk_space 2048; then
        return 1
    fi
    
    return 0
}

# 下载并安装Java
download_and_install_java() {
    local version=$1
    local install_dir=$2
    
    # 创建临时目录
    local temp_dir
    temp_dir=$(mktemp -d) || return 1
    
    # 下载JDK
    local jdk_url="https://download.oracle.com/java/${version}/latest/jdk-${version}_linux-x64_bin.tar.gz"
    if ! download_file "$jdk_url" "$temp_dir/jdk.tar.gz"; then
        return 1
    fi
    
    # 解压安装
    mkdir -p "$install_dir"
    tar xzf "$temp_dir/jdk.tar.gz" -C "$install_dir" || return 1
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    return 0
}

# 配置Java环境
configure_java_env() {
    local install_dir=$1
    local env_file="/etc/profile.d/java.sh"
    
    # 创建环境变量文件
    cat > "$env_file" << EOF
export JAVA_HOME=${install_dir}/current
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
    
    # 创建软链接
    ln -sf "$install_dir/jdk-"* "$install_dir/current"
    
    # 重新加载环境变量
    source "$env_file"
    
    return 0
}

# 清理Java环境
clean_java_env() {
    rm -f "/etc/profile.d/java.sh"
}
