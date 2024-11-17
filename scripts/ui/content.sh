#!/bin/bash
# Tab页内容管理

# 显示系统内容
show_system_content() {
    show_system_options
}

# 显示配置内容
show_config_content() {
    show_config_options
}

# 显示状态内容
show_status_content() {
    echo -e "${COLOR_YELLOW}状态查看:${COLOR_RESET}"
    echo "1. 查看系统状态"
    echo "2. 查看服务状态"
    echo "3. 查看资源使用"
    echo "4. 查看系统日志"
    
    # 显示当前状态概览
    show_status_overview
}

# 显示状态概览
show_status_overview() {
    # 显示系统状态
    echo -e "\n系统状态概览:"
    echo "CPU使用率: $(get_cpu_usage)%"
    echo "内存使用率: $(get_memory_usage)%"
    echo "磁盘使用率: $(get_disk_usage)%"

    # 显示服务状态概览
    echo -e "\n服务状态概览:"
    get_services_status
}

# 显示系统选项
show_system_options() {
    echo -e "${COLOR_YELLOW}系统管理:${COLOR_RESET}"
    echo "1. 系统优化"
    echo "2. 清理系统"
    echo "3. 更新系统"
    echo "4. 查看系统信息"
}

# 显示配置选项
show_config_options() {
    echo -e "${COLOR_YELLOW}配置管理:${COLOR_RESET}"
    echo "1. 查看配置"
    echo "2. 修改配置"
    echo "3. 备份配置"
    echo "4. 恢复配置"
}
