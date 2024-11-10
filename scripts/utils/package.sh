#!/bin/bash
# 包管理工具

# 初始化包管理器
init_package_manager() {
    log "INFO" "初始化包管理器"

    case "$SYSTEM_OS" in
    "centos")
        # 检查并安装EPEL源
        if ! rpm -q epel-release >/dev/null 2>&1; then
            yum install -y epel-release || {
                log "ERROR" "无法安装EPEL源"
                return 1
            }
        fi
        ;;
    "ubuntu")
        # 更新软件源
        apt update || {
            log "ERROR" "无法更新软件源"
            return 1
        }
        ;;
    *)
        log "ERROR" "不支持的操作系统: $SYSTEM_OS"
        return 1
        ;;
    esac

    return 0
}

# SYSTEM_OS检测yum/apt-get是否被占用
check_package_manager_lock() {
    local max_wait_time=${1:-${COMMAND_TIMEOUT}}
    local check_interval=10
    local elapsed_time=0

    case "$SYSTEM_OS" in
    "centos")
        while true; do
            local yum_pid
            yum_pid=$(pgrep -x yum)

            # 如果进程不存在，强制清理锁文件并退出
            if [ -z "$yum_pid" ]; then
                if [ -f "/var/run/yum.pid" ]; then
                    rm -f "/var/run/yum.pid"
                fi
                break
            fi

            # 进程存在，继续等待
            if [ $elapsed_time -ge "$max_wait_time" ]; then
                log "ERROR" "等待yum解锁超时（${max_wait_time}秒）"
                return 1
            fi
            log "WARN" "检测到yum进程正在运行，等待解锁 (已等待 ${elapsed_time}秒)"
            sleep $check_interval
            elapsed_time=$((elapsed_time + check_interval))
        done
        ;;
    "ubuntu")
        local lock_files=(
            "/var/lib/dpkg/lock-frontend"
            "/var/lib/dpkg/lock"
            "/var/lib/apt/lists/lock"
            "/var/cache/apt/archives/lock"
        )

        while true; do
            local apt_pid
            apt_pid=$(pgrep -x "apt\|apt-get\|dpkg")

            # 如果进程不存在，强制清理所有锁文件并退出
            if [ -z "$apt_pid" ]; then
                local found_locks=()
                for lock_file in "${lock_files[@]}"; do
                    if [ -f "$lock_file" ]; then
                        found_locks+=("$lock_file")
                    fi
                done

                if [ ${#found_locks[@]} -gt 0 ]; then
                    for lock_file in "${found_locks[@]}"; do
                        rm -f "$lock_file"
                    done
                    dpkg --configure -a >/dev/null 2>&1
                fi
                break
            fi

            # 进程存在，继续等待
            if [ $elapsed_time -ge "$max_wait_time" ]; then
                log "ERROR" "等待apt-get解锁超时（${max_wait_time}秒）"
                return 1
            fi
            log "WARN" "检测到apt/apt-get/dpkg进程正在运行，等待解锁 (已等待 ${elapsed_time}秒)"
            sleep $check_interval
            elapsed_time=$((elapsed_time + check_interval))
        done
        ;;
    *)
        log "ERROR" "不支持的操作系统: $SYSTEM_OS"
        return 1
        ;;
    esac

    return 0
}

# 更新包管理器缓存
update_package_manager() {
    log "INFO" "更新包管理器缓存"

    case "$SYSTEM_OS" in
    "centos")
        execute_command "yum clean all" "清理包缓存失败"
        execute_command "yum makecache" "重建包缓存失败"
        execute_command "yum update -y" "更新系统失败"
        ;;
    "ubuntu")
        execute_command "apt update" "更新软件源失败"
        execute_command "apt upgrade -y" "更新系统失败"
        ;;
    *)
        log "ERROR" "不支持的操作系统: $SYSTEM_OS"
        return 1
        ;;
    esac

    return 0
}

# 批量安装包
install_packages() {
    local packages=$1
    local version=${2:-""}
    local options=${3:-""}

    for package in "${packages[@]}"; do
        install_package "$package" "$version" "$options" || {
            return 1
        }
    done

    return 0
}

# 安装包
install_package() {
    local package=$1
    local version=${2:-""}
    local options=${3:-""}

    if [ -z "$SYSTEM_OS" ]; then
        log "ERROR" "系统类型未定义"
        return 1
    fi

    log "INFO" "安装 $package${version:+ version $version} (系统类型: $SYSTEM_OS)"

    # 检查包管理器锁
    check_package_manager_lock "$COMMAND_TIMEOUT" || {
        echo ""
        log "ERROR" "等待包管理器解锁失败"
        return 1
    }

    case "$SYSTEM_OS" in
    "centos")
        local cmd="yum install -y $options"
        if [ -n "$version" ]; then
            cmd+=" $package-$version"
        else
            cmd+=" $package"
        fi
        execute_command "$cmd" "安装包失败: $package" "$COMMAND_TIMEOUT" || {
            return 1
        }
        ;;
    "ubuntu")
        local cmd="apt-get install -y $options"
        if [ -n "$version" ]; then
            cmd+=" $package-$version"
        else
            cmd+=" $package"
        fi
        execute_command "$cmd" "安装包失败: $package" "$COMMAND_TIMEOUT" || {
            return 1
        }
        ;;
    *)
        log "ERROR" "不支持的操作系统: $SYSTEM_OS"
        return 1
        ;;
    esac

    return 0
}

# 批量检查包是否已安装
check_packages_installed() {
    local packages=$1
    local version=${2:-""}

    case "$SYSTEM_OS" in
    "centos")
        # yum和rpm都查询
        yum list installed "$packages" >/dev/null 2>&1
        rpm -q "$packages" >/dev/null 2>&1
        return $?
        ;;
    "ubuntu")
        # apt-get和dpkg都查询
        apt-get list "$packages" >/dev/null 2>&1
        dpkg -l "$packages" >/dev/null 2>&1
        return $?
        ;;
    *)
        return 1
        ;;
    esac
}

# 批量卸载包
remove_packages() {
    local packages=$1
    local purge=${2:-false}

    # 检查包管理器锁
    check_package_manager_lock "$COMMAND_TIMEOUT" || {
        log "ERROR" "等待包管理器解锁失败"
        return 1
    }

    case "$SYSTEM_OS" in
    "centos")
        # 模糊匹配
        execute_command "yum remove -y ${packages}" "卸载包失败: $packages"
        ;;
    "ubuntu")
        if [ "$purge" = true ]; then
            execute_command "apt-get purge -y ${packages}" "清除包失败: $packages"
        else
            execute_command "apt-get remove -y ${packages}" "卸载包失败: $packages"
        fi
        execute_command "apt-get autoremove -y" "清理无用包失败"
        ;;
    *)
        log "ERROR" "不支持的操作系统: $SYSTEM_OS"
        return 1
        ;;
    esac

    return 0
}

# 获取包版本
get_package_version() {
    local package=$1

    case "$SYSTEM_OS" in
    "centos")
        # yum/rpm获取版本号(如: 1.20.0-1ubuntu2)
        rpm -q --qf '%{VERSION}' "$package" 2>/dev/null
        yum list "$package" 2>/dev/null | grep '^Version:' | cut -d ' ' -f 2
        ;;
    "ubuntu")
        # apt-get/dpkg获取版本号(如: 1.20.0-1ubuntu2)
        apt-cache show "$package" 2>/dev/null | grep '^Version:' | cut -d ' ' -f 2
        dpkg -s "$package" 2>/dev/null | grep '^Version:' | cut -d ' ' -f 2
        ;;
    *)
        echo "unknown"
        ;;
    esac
}

# 清理包缓存
clean_package_cache() {
    log "INFO" "清理包缓存"

    case "$SYSTEM_OS" in
    "centos")
        execute_command "yum clean all" "清理包缓存失败"
        ;;
    "ubuntu")
        execute_command "apt clean" "清理包缓存失败"
        execute_command "apt autoclean" "清理过期包失败"
        ;;
    *)
        log "ERROR" "不支持的操作系统: $SYSTEM_OS"
        return 1
        ;;
    esac

    return 0
}

# 安装依赖包
install_dependencies() {
    local common_deps=(
        "wget"
        "curl"
        "tar"
        "gzip"
        "unzip"
        "net-tools"
        "sysstat"
        "proccps"
    )

    local os_deps=()
    case "$SYSTEM_OS" in
    "centos")
        os_deps+=(
            "epel-release"
            "yum-utils"
            "gcc"
            "make"
            "openssl-devel"
        )
        ;;
    "ubuntu")
        os_deps+=(
            "build-essential"
            "software-properties-common"
            "apt-transport-https"
            "ca-certificates"
        )
        ;;
    esac

    # 安装通用依赖
    check_packages_installed "${common_deps[@]}" || {
        log "ERROR" "安装通用依赖失败: ${common_deps[*]}"
        return 1
    }

    # 安装系统特定依赖
    check_packages_installed "${os_deps[@]}" || {
        log "ERROR" "安装系统依赖失败: ${os_deps[*]}"
        return 1
    }

    return 0
}

# 添加软件源
add_repository() {
    local repo_name=$1
    local repo_url=$2
    local repo_key=${3:-""}

    log "INFO" "添加软件源: $repo_name"

    case "$SYSTEM_OS" in
    "centos")
        cat >"/etc/yum.repos.d/${repo_name}.repo" <<EOF
[${repo_name}]
name=${repo_name}
baseurl=${repo_url}
enabled=1
gpgcheck=0
EOF
        ;;
    "ubuntu")
        if [ -n "$repo_key" ]; then
            curl -fsSL "$repo_key" | apt-key add - || {
                log "ERROR" "添加软件源密钥失败: $repo_key"
                return 1
            }
        fi
        add-apt-repository -y "$repo_url" || {
            log "ERROR" "添加软件源失败: $repo_url"
            return 1
        }
        apt update
        ;;
    *)
        log "ERROR" "不支持的操作系统: $SYSTEM_OS"
        return 1
        ;;
    esac

    return 0
}
