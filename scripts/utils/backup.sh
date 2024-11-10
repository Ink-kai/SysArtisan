#!/bin/bash
# 备份工具

# 创建备份
create_backup() {
    local source_path=$1
    local backup_name=${2:-$(date +%Y%m%d_%H%M%S)}
    local backup_path="${BACKUP_PATH}/${backup_name}"
    
    log "INFO" "创建备份: ${backup_name}"
    
    # 创建备份目录
    ensure_dir "$backup_path"
    
    # 执行备份
    if [ -d "$source_path" ]; then
        tar -czf "${backup_path}.tar.gz" -C "$(dirname "$source_path")" "$(basename "$source_path")"
    elif [ -f "$source_path" ]; then
        cp -p "$source_path" "$backup_path"
    else
        log "ERROR" "备份源不存在: $source_path"
        return 1
    fi
    
    # 记录备份信息
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $source_path" >> "${BACKUP_PATH}/backup.log"
    
    return 0
}

# 恢复备份
restore_backup() {
    local backup_name=$1
    local target_path=$2
    
    log "INFO" "恢复备份: ${backup_name}"
    
    local backup_file="${BACKUP_PATH}/${backup_name}"
    
    if [ ! -e "$backup_file" ]; then
        log "ERROR" "备份文件不存在: $backup_file"
        return 1
    fi
    
    # 创建目标目录
    ensure_dir "$(dirname "$target_path")"
    
    # 执行恢复
    if [[ "$backup_file" == *.tar.gz ]]; then
        tar -xzf "$backup_file" -C "$(dirname "$target_path")"
    else
        cp -p "$backup_file" "$target_path"
    fi
    
    return 0
}

# 列出所有备份
list_backups() {
    local pattern=${1:-"*"}
    
    log "INFO" "列出备份文件"
    
    if [ -f "${BACKUP_PATH}/backup.log" ]; then
        grep "$pattern" "${BACKUP_PATH}/backup.log"
    else
        log "WARN" "没有找到备份记录"
    fi
}

# 清理旧备份
cleanup_old_backups() {
    local days=${1:-7}
    
    log "INFO" "清理 ${days} 天前的备份"
    
    find "$BACKUP_PATH" -type f -mtime +"$days" \( -name "*.tar.gz" -o -name "*.bak" \) -delete
    
    # 更新备份日志
    if [ -f "${BACKUP_PATH}/backup.log" ]; then
        temp_log=$(mktemp)
        grep -v "$(date -d "-${days} days" '+%Y-%m-%d')" "${BACKUP_PATH}/backup.log" > "$temp_log"
        mv "$temp_log" "${BACKUP_PATH}/backup.log"
    fi
}

# 备份所有服务配置
backup_all_configs() {
    local backup_dir="${BACKUP_PATH}/configs_$(date +%Y%m%d_%H%M%S)"
    
    log "INFO" "备份所有服务配置"
    
    # 创建备份目录
    ensure_dir "$backup_dir"
    
    # 备份系统配置
    cp -r /etc/sysctl.d "$backup_dir/" 2>/dev/null
    cp -r /etc/security/limits.d "$backup_dir/" 2>/dev/null
    
    # 备份服务配置
    for service in java nginx redis; do
        if type "backup_${service}_config" >/dev/null 2>&1; then
            log "INFO" "备份 $service 配置"
            if ! backup_"${service}"_config "$backup_dir/${service}"; then
                log "ERROR" "备份 $service 配置失败"
                continue
            fi
        fi
    done
    
    # 打包备份
    tar -czf "${backup_dir}.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    # 记录备份信息
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 全量配置备份" >> "${BACKUP_PATH}/backup.log"
    
    log "INFO" "配置备份完成: ${backup_dir}.tar.gz"
    return 0
} 