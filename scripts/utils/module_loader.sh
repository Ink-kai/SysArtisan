#!/bin/bash
# 模块加载器

# 定义已加载模块的关联数组
declare -A LOADED_MODULES

# 加载系统模块
load_system_modules() {
    local module_dir=$1
    local allow_errors=${2:-0}  # 允许错误参数：0=不允许(默认)，1=允许
    local modules=()
    local has_errors=0

    # 检查模块目录是否存在
    if [ ! -d "$module_dir" ]; then
        printf "${COLOR_ERROR}ERROR: 模块目录不存在: %s${COLOR_RESET}\n" "$module_dir"
        has_errors=1
        [ "$allow_errors" -eq 0 ] && return 1
        return 0  # 如果允许错误，则继续执行
    fi

    # 查找所有.sh文件并排序
    while IFS= read -r -d '' file; do
        modules+=("$file")
    done < <(find "$module_dir" -type f -name "*.sh" -print0 | sort -z)

    # 检查是否找到模块
    if [ ${#modules[@]} -eq 0 ]; then
        printf "${COLOR_WARNING}WARN: 未找到任何模块: %s${COLOR_RESET}\n" "$module_dir"
        has_errors=1
        [ "$allow_errors" -eq 0 ] && return 1
    fi

    # 加载每个模块
    for module in "${modules[@]}"; do
        local module_name
        module_name=$(basename "$module")
        
        # 检查模块是否已加载
        if [[ -n "${LOADED_MODULES[$module]}" ]]; then
            printf "${COLOR_DEBUG}DEBUG: 模块已加载，跳过: %s${COLOR_RESET}\n" "$module_name"
            continue
        fi
        
        # 验证模块
        if ! verify_module "$module"; then
            printf "${COLOR_ERROR}ERROR: 模块验证失败: %s${COLOR_RESET}\n" "$module_name"
            has_errors=1
            if [ "$allow_errors" -eq 0 ]; then
                return 1
            else
                continue  # 如果允许错误，跳过此模块继续下一个
            fi
        fi
        
        # 尝试加载模块
        if source "$module" 2>/dev/null; then
            printf "${COLOR_DEBUG}DEBUG: 成功加载模块: %s${COLOR_RESET}\n" "$module_name"
            LOADED_MODULES[$module]=1
        else
            printf "${COLOR_ERROR}ERROR: 无法加载模块: %s${COLOR_RESET}\n" "$module_name"
            has_errors=1
            if [ "$allow_errors" -eq 0 ]; then
                return 1
            else
                continue  # 如果允许错误，跳过此模块继续下一个
            fi
        fi
    done

    [ "$has_errors" -eq 1 ] && [ "$allow_errors" -eq 0 ] && return 1
    return 0
}

# 检查模块是否已加载
is_module_loaded() {
    local module=$1
    [[ -n "${LOADED_MODULES[$module]}" ]]
}

# 获取已加载模块列表
get_loaded_modules() {
    for module in "${!LOADED_MODULES[@]}"; do
        printf "${COLOR_DEBUG}DEBUG: 已加载模块: %s${COLOR_RESET}\n" "$(basename "$module")"
    done
}

# 清除已加载模块记录
clear_loaded_modules() {
    LOADED_MODULES=()
}

# 验证模块
verify_module() {
    local module=$1
    
    # 检查文件是否存在且可读
    if [ ! -r "$module" ]; then
        return 1
    fi
    
    # 检查文件是否为bash脚本
    if ! grep -q "^#!/bin/bash" "$module"; then
        return 1
    fi
    
    return 0
}
