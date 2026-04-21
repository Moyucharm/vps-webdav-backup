# VPS WebDAV 备份

轻量级 VPS 备份方案，将 Docker Compose 项目和配置文件备份至 WebDAV，支持自动轮转。

## 功能特性

- **零服务中断** - 无需停止容器即可执行备份
- **WebDAV 支持** - 上传备份至任意 WebDAV 兼容存储
- **自动轮转** - 仅保留指定数量的备份
- **可配置排除规则** - 支持排除模式（如 `.git`、`node_modules`、`*.log`）
- **Systemd 集成** - 通过 systemd timer 实现每周定时备份
- **简单恢复** - 在新设备上轻松还原

## 快速开始

### 1. 下载

```bash
git clone https://github.com/your-username/vps-webdav-backup.git
cd vps-webdav-backup
```

### 2. 安装

```bash
sudo make install
```

### 3. 配置

```bash
sudo nano /etc/vps-webdav-backup.conf
```

编辑以下必填项：

```bash
WEBDAV_URL="https://your-webdav-server.com"
WEBDAV_USER="your_username"
WEBDAV_PASS="your_password_or_token"
WEBDAV_PATH="/your-backup-folder"

BACKUP_DIRS=(
    "/home/user/apps/project1"
    "/home/user/apps/project2"
)
```

### 4. 启用定时器

```bash
sudo systemctl enable --now vps-webdav-backup.timer
```

### 5. 测试备份

```bash
sudo systemctl start vps-webdav-backup.service
journalctl -u vps-webdav-backup.service -f
```

## 文档

- [DEPLOY.md](docs/DEPLOY.md) - 详细部署指南
- [RESTORE.md](docs/RESTORE.md) - 恢复与还原指南
- [AGENTS_PROMPT.md](AGENTS_PROMPT.md) - AI Agent 自动化部署指令

## 配置项

| 变量 | 必填 | 说明 |
|------|------|------|
| `WEBDAV_URL` | 是 | WebDAV 服务器地址 |
| `WEBDAV_USER` | 是 | WebDAV 用户名 |
| `WEBDAV_PASS` | 是 | WebDAV 密码或令牌 |
| `WEBDAV_PATH` | 是 | 远程备份目录（如 `/backup`） |
| `KEEP_COUNT` | 否 | 保留备份数量（默认：3） |
| `BACKUP_DIRS` | 是* | 需备份的目录（Docker Compose 项目） |
| `EXTRA_FILES` | 否 | 额外需备份的文件 |
| `EXCLUDE_PATTERNS` | 否 | 备份排除规则 |

*`BACKUP_DIRS` 或 `EXTRA_FILES` 至少配置一项。

## 备份结构

```
backup_YYYYMMDD_HHMMSS.tar.xz
├── dirs/
│   ├── project1/
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── data/
│   └── project2/
│       └── docker-compose.yml
└── files/
    ├── Caddyfile
    └── nginx.conf
```

## 系统要求

- Linux（systemd）
- Docker（用于 Docker Compose 项目）
- `rsync`、`curl`、`tar`（通常已预装）
- WebDAV 兼容存储服务

## 许可证

MIT License - 详见 [LICENSE](LICENSE)
