#!/bin/bash
# 配置管理

# 默认配置
declare -A DEFAULT_CONFIG=(
    ["INSTALL_MODE"]="network"
    ["AUTO_BACKUP"]="true"
    ["DEBUG_MODE"]="false"
    ["BACKUP_RETENTION"]="30"
    ["MAX_LOG_SIZE"]="10485760"
    ["NETWORK_RETRY"]="3"
)

# 初始化配置
init_config() {
    # 创建配置目录
    if [ ! -d "$CONFIG_PATH" ]; then
        create_directory "$CONFIG_PATH" || {
            log "ERROR" "无法创建配置目录: $CONFIG_PATH"
            return 1
        }
        chmod 755 "$CONFIG_PATH"
    fi
    
    # 如果配置文件不存在，创建默认配置
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
    
    # 加载配置
    load_config
    
    # 验证配置
    validate_config
    
    return 0
}

# 创建默认配置
create_default_config() {
    log "INFO" "创建默认配置文件"
    
    # 清空或创建配置文件
    echo ""> "$CONFIG_FILE"
    
    # 写入配置头
    cat >> "$CONFIG_FILE" <<EOF
# 环境部署工具配置文件
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')
# 请勿手动修改此文件，除非您知道自己在做什么

EOF
    
    # 写入默认配置
    for key in "${!DEFAULT_CONFIG[@]}"; do
        echo "${key}=${DEFAULT_CONFIG[$key]}" >> "$CONFIG_FILE"
    done
    
    chmod 644 "$CONFIG_FILE"
    log "INFO" "默认配置文件已创建: $CONFIG_FILE"
}

# 加载配置
load_config() {
    log "INFO" "加载配置文件"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log "ERROR" "配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    # 加载配置到环境变量
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # 去除空格
        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | tr -d '[:space:]')
        
        # 设置环境变量
        export "CONFIG_${key}"="$value"
    done < "$CONFIG_FILE"
    
    return 0
}

# 验证配置
validate_config() {
    log "INFO" "验证配置"
    
    local has_error=false
    
    # 验证Java版本
    if ! validate_java_version "$CONFIG_JAVA_VERSION"; then
        log "ERROR" "无效的Java版本: $CONFIG_JAVA_VERSION"
        has_error=true
    fi
    
    # 验证安装模式
    if [[ ! "$CONFIG_INSTALL_MODE" =~ ^(network|local)$ ]]; then
        log "ERROR" "无效的安装模式: $CONFIG_INSTALL_MODE"
        has_error=true
    fi
    
    # 验证其他配置项
    # 
    
    if $has_error; then
        log "ERROR" "配置验证失败，请检查配置文件"
        return 1
    else
        log "INFO" "配置验证通过"
        return 0
    fi
}

# 获取配置值
get_config() {
    local key=$1
    local default_value=$2
    local value
    
    if [ -z "$key" ]; then
        log "ERROR" "配置键不能为空"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log "WARN" "配置文件不存在，使用默认值: $default_value"
        create_default_config
    fi
    
    value=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2)
    if [ -z "$value" ]; then
        log "WARN" "未找到配置项 $key，使用默认值: $default_value"
        echo "$default_value"
    else
        echo "$value"
    fi
}

# 更新配置
update_config() {
    local key=$1
    local value=$2
    
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
}

# 显示配置
show_config() {
    log "INFO" "当前配置信息："
    echo "----------------------------------------"
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # 去除空格并显示
        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | tr -d '[:space:]')
        printf "%-20s = %s\n" "$key" "$value"
    done < "$CONFIG_FILE"
    echo "----------------------------------------"
}

# 修改配置
modify_config() {
    local key=$1
    local value=$2
    
    if [ -z "$key" ]; then
        log "ERROR" "配置键不能为空"
        return 1
    fi
    
    if [ -z "$value" ]; then
        value=$(get_user_input "请输入 $key 的新值")
    fi
    
    if ! validate_config_item "$key" "$value"; then
        log "ERROR" "配置验证失败"
        return 1
    fi
    
    update_config "$key" "$value"
    log "INFO" "配置已更新: $key = $value"
}

# 恢复配置
restore_config() {
    local backup_file
    backup_file=$(get_user_input "请输入备份文件路径" "" 30 true validate_path)
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "备份文件不存在"
        return 1
    fi
    
    cp "$backup_file" "$CONFIG_FILE"
    log "INFO" "配置已恢复"
}