#!/bin/bash
# 文件操作工具

# 创建目录
create_directory() {
    local dir=$1
    local mode=${2:-755}
    local owner=${3:-"root"}
    local group=${4:-"root"}

    if [ ! -d "$dir" ]; then
        log "DEBUG" "创建目录: $dir"
        mkdir -p "$dir" || {
            log "ERROR" "无法创建目录: $dir"
            return 1
        }
    fi

    chmod "$mode" "$dir" || {
        log "ERROR" "无法设置目录权限: $dir"
        return 1
    }

    chown "$owner:$group" "$dir" || {
        log "ERROR" "无法设置目录所有者: $dir"
        return 1
    }

    return 0
}

# 备份目录
backup_directory() {
    local source=$1
    local backup_dir=${2:-"$BACKUP_PATH"}
    local timestamp=${3:-$(date +%Y%m%d_%H)}

    # 确保备份目录存在
    create_directory "$backup_dir" || return 1

    # 生成备份目录名
    local backup_dir_name
    backup_dir_name="${backup_dir}/$(basename "$source").${timestamp}"

    # 创建备份目录的父目录
    create_directory "$(dirname "$backup_dir_name")" || {
        log "ERROR" "无法创建备份目录的父目录: $(dirname "$backup_dir_name")"
    }

    # cp备份目录
    cp -rp "$source" "$backup_dir_name" || {
        log "ERROR" "无法备份目录: $source -> $backup_dir_name"
    }

    # 如果需要压缩
    if [ "$BACKUP_COMPRESS" = true ]; then
        case "$BACKUP_COMPRESS_TYPE" in
        "gzip")
            tar -czf "${backup_dir_name}.tar.gz" -C "$(dirname "$backup_dir_name")" "$(basename "$backup_dir_name")" &&
                rm -rf "$backup_dir_name" &&
                backup_dir_name="${backup_dir_name}.tar.gz"
            ;;
        "bzip2")
            tar -cjf "${backup_dir_name}.tar.bz2" -C "$(dirname "$backup_dir_name")" "$(basename "$backup_dir_name")" &&
                rm -rf "$backup_dir_name" &&
                backup_dir_name="${backup_dir_name}.tar.bz2"
            ;;
        *)
            log "WARN" "未知的压缩类型: $BACKUP_COMPRESS_TYPE"
            ;;
        esac
    fi

    log "INFO" "目录已备份: $backup_dir_name"
    echo "$backup_dir_name"
    return 0
}

# 备份文件
backup_file() {
    local source=$1
    local backup_dir=${2:-"$BACKUP_PATH"}
    local timestamp=${3:-$(date +%Y%m%d_%H)}

    if [ ! -f "$source" ]; then
        return 0
    fi

    # 创建备份目录
    create_directory "$backup_dir" || return 1

    # 生成备份文件名
    local filename
    filename=$(basename "$source")
    local backup_file="${backup_dir}/${filename}.${timestamp}"

    # 复制文件
    cp -p "$source" "$backup_file" || {
        log "ERROR" "备份文件失败: $source"
    }

    # 如果需要压缩
    if [ "$BACKUP_COMPRESS" = true ]; then
        case "$BACKUP_COMPRESS_TYPE" in
        "gzip")
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
            ;;
        "bzip2")
            bzip2 "$backup_file"
            backup_file="${backup_file}.bz2"
            ;;
        *)
            log "WARN" "未知的压缩类型: $BACKUP_COMPRESS_TYPE"
            ;;
        esac
    fi

    log "INFO" "文件已备份: $backup_file"
    echo "$backup_file"
    return 0
}

# 安全删除批量文件
secure_delete() {
    local target=$1
    local force=${2:-false}

    if [ ! -e "$target" ]; then
        # log "WARN" "目标不存在: $target"
        return 0
    fi

    # 检查路径结尾是否为系统关键文件名称
    if [[ "$target" =~ /(bin|sbin|lib|lib64|usr|etc|var|boot)$ ]]; then
        if [ "$force" != true ]; then
            log "ERROR" "禁止删除系统关键文件: $target"
            return 1
        fi
    fi

    if [ -d "$target" ]; then
        rm -rf "$target" || {
            log "ERROR" "无法删除目录: $target"
        }
    fi

    if [ -f "$target" ]; then
        rm -f "$target" || {
            log "ERROR" "无法删除文件: $target"
        }
    fi

    return 0
}

# 查找系统中指定关键词的所有文件
# 参数:
#   $1 - 查找关键词
#   $2 - 排除最后一个目录名称在目录列表中 (可选, 格式: "dir1,dir2,dir3")
#   $3 - 排除文件列表 (可选, 格式: "file1,file2,file3")
#   $4 - 文件类型过滤 (可选, 格式: "f", "d", "l")
#   $5 - 是否大小写敏感 (可选, true/false)
# 返回: 找到的文件列表
find_files_by_keyword() {
    local keyword=$1
    local exclude_dirs=${2:-""}
    local exclude_files=${3:-""}
    local file_type=${4:-""}
    local case_sensitive=${5:-true}
    
    # 根据大小写敏感设置find命令
    local name_opt="-name"
    if [ "$case_sensitive" != true ]; then
        name_opt="-iname"
    fi
    
    local find_cmd="find / $name_opt \"*${keyword}*\""
    
    # 添加文件类型过滤
    if [ -n "$file_type" ]; then
        find_cmd+=" -type $file_type"
    fi
    
    find_cmd+=" 2>/dev/null"

    # 修改：构建一个过滤命令来检查最后一个目录名
    local filter_cmd="cat"
    if [ -n "$exclude_dirs" ]; then
        local IFS=','
        local dirs=($exclude_dirs)
        filter_cmd="while read -r path; do"
        filter_cmd+=" base_dir=\$(basename \"\$(dirname \"\$path\")\");"
        filter_cmd+=" exclude=false;"
        filter_cmd+=" for dir in ${dirs[*]}; do"
        filter_cmd+="   if [ \"\$base_dir\" = \"\$dir\" ]; then"
        filter_cmd+="     exclude=true;"
        filter_cmd+="     break;"
        filter_cmd+="   fi;"
        filter_cmd+=" done;"
        filter_cmd+=" if [ \"\$exclude\" != true ]; then echo \"\$path\"; fi;"
        filter_cmd+=" done"
    fi

    # 合并 whereis 和 find 的结果，使用新的过滤逻辑
    {
        if [ -z "$file_type" ] || [ "$file_type" = "f" ]; then
            whereis "$keyword" | cut -d: -f2- | tr ' ' '\n'
        fi
        eval "$find_cmd"
    } | grep -v '^$' | eval "$filter_cmd" | sort -u
}

# 使用示例:
# 查找nginx相关文件，排除备份目录和特定文件，只查找普通文件，忽略大小写
# find_files_by_keyword "nginx" "/backup,/tmp" "nginx.pid,nginx.conf" "f" false
