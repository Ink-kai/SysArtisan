# SysArtisian

> Server Environment Deploy Tool

一个用于 Linux 服务器环境配置、服务部署和系统优化的命令行工具。

## 功能特性

- 🚀 自动化部署常用服务(Java、Nginx、Redis 等)
- 🛠 系统环境检查与优化
- 📝 完整的日志记录
- 🔄 服务状态监控
- 💻 交互式命令行界面
- 🔒 安全的配置管理
- 📊 系统资源监控
- 💾 自动备份功能

## 系统要求

- 操作系统: CentOS 7+ / Ubuntu 18.04+
- 内存: 至少 1GB
- 磁盘空间: 至少 10GB
- 必须使用 root 权限运行

## 快速开始

1. 下载脚本:

```bash
wget https://raw.githubusercontent.com/yourusername/yourrepo/main/yourscript.sh
cd linux-deploy-tool

```

2.添加执行权限:

```bash
chmod +x deploy.sh
```

3. 运行脚本:

```bash
./main.sh
```

## 使用说明

### 主菜单选项

- **[1] 安装服务** - 部署新的服务
- **[2] 卸载服务** - 移除已安装的服务
- **[3] 系统管理** - 系统优化和清理
- **[4] 配置管理** - 查看和修改配置
- **[5] 状态查看** - 监控系统和服务状态

### 支持的服务

- Java (OpenJDK 8-17)
- Nginx
- Redis
- MySQL
- 更多服务持续添加中...

### 配置文件

主配置文件位于: `/etc/environment_deploy/config.conf`

示例配置:

```ini
JAVA_VERSION=11
NGINX_VERSION=1.24.0
REDIS_VERSION=7.0.0
INSTALL_MODE=network
AUTO_BACKUP=true
DEBUG_MODE=false
```

### 日志文件

- 主日志文件: `/var/log/environment_deploy/deploy.log`
- 备份目录: `/var/backup/environment_deploy/`

## 目录结构

```
.
├── deploy.sh               # 主执行脚本
├── scripts/                # 脚本目录
│   ├── install/            # 安装脚本
│   │   ├── java.sh
│   │   ├── nginx.sh
│   │   ├── redis.sh
│   │   └── mysql.sh
│   ├── uninstall/          # 卸载脚本
│   ├── system/             # 系统管理脚本
│   └── utils/              # 工具函数
├── config/                 # 配置文件目录
│   ├── templates/          # 配置模板
│   └── default.conf        # 默认配置
├── logs/                   # 日志目录
├── backup/                 # 备份目录
├── docs/                   # 文档
└── README.md               # 项目说明文档
```

## 常见问题

**Q: 如何修改安装目录?**  
A: 在配置文件中修改 `INSTALL_PATH` 参数。

**Q: 如何开启调试模式?**  
A: 在配置文件中设置 `DEBUG_MODE=true`。

**Q: 如何查看详细日志?**  
A: 查看 `/var/log/environment_deploy/deploy.log` 文件。

## 安全说明

- 所有密码和敏感信息都经过加密存储
- 自动备份重要配置文件
- 执行危险操作时需要确认
- 详细的操作日志记录

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 版本历史

- v1.0.0 (2024-01-01)
  - 初始版本发布
  - 支持基础服务安装
  - 系统优化功能

## 开源协议

本项目采用 MIT 协议 - 查看 [LICENSE](LICENSE) 文件了解详情

## 作者

作者名字 - [09wanyue@gmail.com](https://github.com/ink-kai)
