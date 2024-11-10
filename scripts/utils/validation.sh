#!/bin/bash
# 验证工具

# 验证IP地址
validate_ip() {
    local ip=$1
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ ! $ip =~ $ip_regex ]]; then
        return 1
    fi

    local IFS='.'
    read -ra ip_parts <<<"$ip"

    for part in "${ip_parts[@]}"; do
        if [ "$part" -gt 255 ] || [ "$part" -lt 0 ]; then
            return 1
        fi
    done

    # 检查是否为保留地址
    case "${ip_parts[0]}" in
    127 | 169 | 224 | 225 | 226 | 227 | 228 | 229 | 230 | 231 | 232 | 233 | 234 | 235 | 236 | 237 | 238 | 239 | 240 | 241 | 242 | 243 | 244 | 245 | 246 | 247 | 248 | 249 | 250 | 251 | 252 | 253 | 254 | 255)
        return 1
        ;;
    esac

    return 0
}

# 验证端口号
validate_port() {
    local port=$1
    local reserved_ports=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23)

    if ! [[ "$port" =~ ^[0-9]+$ ]] ||
        [ "$port" -lt 1 ] ||
        [ "$port" -gt 65535 ]; then
        return 1
    fi

    # 检查是否为保留端口
    for reserved_port in "${reserved_ports[@]}"; do
        if [ "$port" -eq "$reserved_port" ]; then
            return 1
        fi
    done

    return 0
}

# 验证域名
validate_domain() {
    local domain=$1
    local domain_regex='^([a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'

    if [[ ! $domain =~ $domain_regex ]]; then
        return 1
    fi

    # 检查域名长度
    if [ ${#domain} -gt 255 ]; then
        return 1
    fi

    # 检查每个标签的长度
    local IFS='.'
    read -ra labels <<<"$domain"
    for label in "${labels[@]}"; do
        if [ ${#label} -gt 63 ]; then
            return 1
        fi
    done

    return 0
}

# 验证版本号
validate_version() {
    local version=$1
    local version_regex='^[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'

    [[ $version =~ $version_regex ]]
}

# 验证路径
validate_path() {
    local path=$1

    # 检查路径是否为空
    if [ -z "$path" ]; then
        return 1
    fi

    # 检查路径是否包含特殊字符
    if [[ "$path" =~ [[:cntrl:]] || "$path" =~ [^[:print:]] ]]; then
        return 1
    fi

    # 检查路径是否以 / 开头
    if [[ ! "$path" =~ ^/ ]]; then
        return 1
    fi

    # 检查路径长度
    if [ ${#path} -gt 4096 ]; then
        return 1
    fi

    # 检查目录深度
    local depth
    depth=$(echo "$path" | tr -cd '/' | wc -c)
    if [ "$depth" -gt 20 ]; then
        return 1
    fi

    return 0
}

# 验证用户名
validate_username() {
    local username=$1
    local username_regex='^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$'
    local reserved_users=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd-network" "systemd-resolve" "systemd-timesync" "messagebus" "syslog" "postfix" "ssh" "ntp")

    if [[ ! $username =~ $username_regex ]]; then
        return 1
    fi

    # 检查是否为保留用户名
    for reserved_user in "${reserved_users[@]}"; do
        if [ "$username" = "$reserved_user" ]; then
            return 1
        fi
    done

    return 0
}

# 验证密码强度
validate_password_strength() {
    local password=$1
    local min_length=${2:-8}
    local require_special=${3:-true}

    # 检查长度
    if [ ${#password} -lt "$min_length" ]; then
        return 1
    fi

    # 检查是否包含大写字母
    if [[ ! "$password" =~ [A-Z] ]]; then
        return 1
    fi

    # 检查是否包含小写字母
    if [[ ! "$password" =~ [a-z] ]]; then
        return 1
    fi

    # 检查是否包含数字
    if [[ ! "$password" =~ [0-9] ]]; then
        return 1
    fi

    # 检查是否包含特殊字符
    if [ "$require_special" = true ] && [[ ! "$password" =~ [^[:alnum:]] ]]; then
        return 1
    fi

    # 检查是否包含连续重复字符
    if [[ "$password" =~ (.)\1{2,} ]]; then
        return 1
    fi

    return 0
}

# 验证邮箱地址
validate_email() {
    local email=$1
    local email_regex='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

    if [[ ! $email =~ $email_regex ]]; then
        return 1
    fi

    # 检查邮箱长度
    if [ ${#email} -gt 254 ]; then
        return 1
    fi

    # 检查本地部分长度
    local local_part
    local_part=$(echo "$email" | cut -d@ -f1)
    if [ ${#local_part} -gt 64 ]; then
        return 1
    fi

    return 0
}

# 验证URL
validate_url() {
    local url=$1
    local url_regex='^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$'

    if [[ ! $url =~ $url_regex ]]; then
        return 1
    fi

    # 检查URL长度
    if [ ${#url} -gt 2048 ]; then
        return 1
    fi

    return 0
}

# 验证MAC地址
validate_mac() {
    local mac=$1
    local mac_regex='^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'

    [[ $mac =~ $mac_regex ]]
}

# 验证IPv6地址
validate_ipv6() {
    local ip=$1
    local ipv6_regex='^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'

    [[ $ip =~ $ipv6_regex ]]
}

# 验证日期格式
validate_date() {
    local date=$1
    local format=${2:-"%Y-%m-%d"}

    date -d "$date" +"$format" >/dev/null 2>&1
}

# 验证时间格式
validate_time() {
    local time=$1
    local time_regex='^([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$'

    [[ $time =~ $time_regex ]]
}

# 验证文件名
validate_filename() {
    local filename=$1
    local max_length=${2:-255}

    # 检查文件名长度
    if [ ${#filename} -gt "$max_length" ]; then
        return 1
    fi

    # 检查是否包含非法字符
    # if [[ "$filename" =~ [/\\:*?"<>|] ]]; then
    #     return 1
    # fi

    # 检查是否以点或空格开头
    if [[ "$filename" =~ ^[\ \.] ]]; then
        return 1
    fi

    return 0
}

# 验证目录名
validate_dirname() {
    local dirname=$1

    # 使用文件名验证规则
    validate_filename "$dirname" || return 1

    # 额外的目录名规则
    if [[ "$dirname" =~ /$ ]]; then
        return 1
    fi

    return 0
}

# 验证Java版本
validate_java_version() {
    local version=$1
    if [[ "$version" =~ ^[0-9]+$ ]]; then
        # 主版本号检查
        if [ "$version" -ge 8 ] && [ "$version" -le 17 ]; then
            return 0
        fi
    elif [[ "$version" =~ ^[0-9]+u[0-9]+$ ]]; then
        # 带更新号的版本检查
        local major_version=${version%u*}
        if [ "$major_version" -ge 8 ] && [ "$major_version" -le 17 ]; then
            return 0
        fi
    fi
    return 1
}

# 验证配置项
validate_config_item() {
    local key=$1
    local value=$2

    case $key in
    "JAVA_VERSION")
        validate_java_version "$value"
        ;;
    "NGINX_VERSION")
        validate_version "$value"
        ;;
    "REDIS_VERSION")
        validate_version "$value"
        ;;
    "PORT")
        validate_port "$value"
        ;;
    "HOST")
        validate_ip "$value" || validate_domain "$value"
        ;;
    "PATH")
        validate_path "$value"
        ;;
    "EMAIL")
        validate_email "$value"
        ;;
    *)
        # 默认验证：不为空且不包含特殊字符
        [[ -n "$value" && ! "$value" =~ [[:cntrl:]] ]]
        ;;
    esac
}

# 添加：数字范围验证函数
validate_number_range() {
    local input=$1
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le 2 ]; then
        return 0
    else
        echo "请输入 1 到 2 之间的数字"
        return 1
    fi
}

# 添加：文件存在性验证函数
validate_file_exists() {
    local file_path=$1
    if [ -f "$file_path" ]; then
        return 0
    else
        echo "文件不存在: $file_path"
        return 1
    fi
}


# 验证菜单选择
validate_menu_choice() {
    local total=$1
    local choice=$2
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total" ]; then
        return 0
    fi
    return 1
}

# 添加服务名称验证函数
validate_service_name() {
    local service_name=$1
    local service_file="${SCRIPT_DIR}/services/${service_name}.sh"
    
    if [ -f "$service_file" ]; then
        return 0
    else
        return 1
    fi
}
