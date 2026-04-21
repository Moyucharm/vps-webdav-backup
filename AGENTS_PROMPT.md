# AGENTS_PROMPT.md - AI Agent 操作指南

本文件为 AI 编码代理（如 Claude、GPT-4 等）提供完整的上下文和指令，以自动化部署和恢复 VPS WebDAV Backup。

## 概述

VPS WebDAV Backup 是一个轻量级备份方案：
- 备份 Docker Compose 项目和配置文件
- 上传至 WebDAV 兼容存储
- 自动轮转旧备份
- 通过 systemd timer 实现每周定时备份

## 仓库结构

```
vps-webdav-backup/
├── README.md                 # 快速开始指南
├── AGENTS_PROMPT.md          # 本文件
├── src/
│   ├── vps-webdav-backup.sh  # 主备份脚本
│   └── vps-webdav-backup.conf # 配置模板
├── systemd/
│   ├── vps-webdav-backup.service
│   └── vps-webdav-backup.timer
└── docs/
    ├── DEPLOY.md             # 部署文档
    └── RESTORE.md            # 恢复文档
```

---

## 场景 A：部署备份服务

### 用户提示模板

```
从 https://github.com/USER/vps-webdav-backup 部署 VPS WebDAV Backup 服务

我的 WebDAV 凭据：
- WEBDAV_URL: <url>
- WEBDAV_USER: <用户名>
- WEBDAV_PASS: <密码>
- WEBDAV_PATH: /backup-folder

需要备份的目录：
- /home/user/apps/project1
- /home/user/apps/project2
- /home/user/develop/project3

额外文件：
- /etc/caddy/Caddyfile

定时计划：每周一 03:00
```

### Agent 执行步骤

#### 1. 环境检查

```bash
# 检查必需工具
which docker docker-compose rsync curl tar systemctl

# 检查 systemd
systemctl --version
```

如有工具缺失，提示用户安装后再继续。

#### 2. 克隆仓库

```bash
git clone https://github.com/USER/vps-webdav-backup.git /tmp/vps-webdav-backup
cd /tmp/vps-webdav-backup
```

#### 3. 安装文件

```bash
# 安装脚本
sudo cp src/vps-webdav-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/vps-webdav-backup.sh

# 安装配置
sudo cp src/vps-webdav-backup.conf /etc/vps-webdav-backup.conf

# 安装 systemd 单元
sudo cp systemd/vps-webdav-backup.service /etc/systemd/system/
sudo cp systemd/vps-webdav-backup.timer /etc/systemd/system/
```

#### 4. 配置

使用用户提供的值创建 `/etc/vps-webdav-backup.conf`：

```bash
# WebDAV 配置
WEBDAV_URL="<用户提供>"
WEBDAV_USER="<用户提供>"
WEBDAV_PASS="<用户提供>"
WEBDAV_PATH="<用户提供>"

# 备份轮转
KEEP_COUNT=3

# 需要备份的目录
BACKUP_DIRS=(
    "/home/user/apps/project1"
    "/home/user/apps/project2"
)

# 额外文件
EXTRA_FILES=(
    "/etc/caddy/Caddyfile"
)

# 排除规则
EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    "*.log"
)
```

#### 5. 启用定时器

```bash
sudo systemctl daemon-reload
sudo systemctl enable vps-webdav-backup.timer
sudo systemctl start vps-webdav-backup.timer
```

#### 6. 测试备份

```bash
sudo systemctl start vps-webdav-backup.service
journalctl -u vps-webdav-backup.service -f
```

#### 7. 验证

```bash
# 检查定时器状态
systemctl list-timers vps-webdav-backup.timer

# 检查日志
journalctl -u vps-webdav-backup.service -n 50
```

### 输出给用户

完成后提供：
1. 状态摘要（已安装/已配置/已测试）
2. 下次定时备份时间
3. 如何手动触发备份
4. 如何查看日志

---

## 场景 B：从备份恢复

### 前提条件

**重要：** 用户必须先部署备份服务（场景 A）以配置 WebDAV 凭据。

### 用户提示模板

```
使用 VPS WebDAV Backup 从备份恢复。

仓库：https://github.com/USER/vps-webdav-backup

选项 A - 下载最新备份并恢复：
- 恢复所有项目

选项 B - 恢复指定备份文件：
- 备份文件：backup_YYYYMMDD_HHMMSS.tar.xz（已下载或 WebDAV URL）

目标目录：
- /home/user/apps/project1
- /home/user/apps/project2

需要恢复的额外文件：
- /etc/caddy/Caddyfile
```

### Agent 执行步骤

#### 1. 检查配置

验证 WebDAV 配置是否存在：

```bash
if [[ -f /etc/vps-webdav-backup.conf ]]; then
    source /etc/vps-webdav-backup.conf
    echo "WebDAV URL: $WEBDAV_URL"
    echo "WebDAV Path: $WEBDAV_PATH"
else
    echo "未找到配置文件，请先部署备份服务。"
    exit 1
fi
```

#### 2. 下载备份（如需要）

```bash
# 列出可用备份
curl -s -X PROPFIND \
    -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
    -H "Depth: 1" \
    "${WEBDAV_URL}${WEBDAV_PATH}/" | grep tar.xz

# 下载最新备份
LATEST_BACKUP=$(curl -s -X PROPFIND \
    -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
    -H "Depth: 1" \
    "${WEBDAV_URL}${WEBDAV_PATH}/" | \
    grep -oP 'backup_[0-9_]+\.tar\.xz' | \
    sort -r | head -1)

curl -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
    -O "${WEBDAV_URL}${WEBDAV_PATH}/${LATEST_BACKUP}"
```

#### 3. 解压备份

```bash
# 创建临时目录
mkdir -p /tmp/restore
cd /tmp/restore

# 解压
tar -xJf /path/to/backup_*.tar.xz

# 查看内容
ls -la backup/dirs/
ls -la backup/files/
```

#### 4. 恢复目录

对用户请求中的每个项目：

```bash
PROJECT_NAME="project1"
SOURCE_DIR="/tmp/restore/backup/dirs/${PROJECT_NAME}"
TARGET_DIR="/home/user/apps/${PROJECT_NAME}"

# 检查目标是否存在
if [[ -d "$TARGET_DIR" ]]; then
    echo "警告：$TARGET_DIR 已存在"
    # 询问用户：覆盖/跳过/备份现有目录
fi

# 恢复
mkdir -p "$TARGET_DIR"
rsync -av "$SOURCE_DIR/" "$TARGET_DIR/"
```

#### 5. 恢复额外文件

```bash
# 恢复 Caddyfile
sudo cp /tmp/restore/backup/files/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

#### 6. 启动 Docker 服务

```bash
cd /home/user/apps/project1
docker compose pull
docker compose up -d
docker compose ps
```

#### 7. 清理

```bash
rm -rf /tmp/restore
rm -f /path/to/downloaded/backup.tar.xz
```

### 输出给用户

完成后提供：
1. 已恢复的项目和文件列表
2. Docker 容器状态
3. 服务健康检查结果
4. 任何警告或需要手动操作的步骤

---

## 约束与指南

### 两个场景通用

1. **权限处理**
   - 系统目录始终使用 `sudo`
   - 复制后检查所有权：`chown -R user:user /path`

2. **错误处理**
   - 复制前检查目录是否存在
   - 验证下载是否成功完成（`curl -f` 或检查退出码）
   - 验证 tar 解压

3. **用户交互**
   - 提示缺失的值
   - 覆盖现有文件前询问用户
   - 提供清晰的状态信息

4. **安全**
   - 不要在日志中记录密码
   - 推荐安全的凭据处理方式
   - 警告 `.env` 文件权限问题

### 恢复场景专用

1. **恢复前检查**
   - 目标目录已存在时发出警告
   - 检查端口冲突
   - 验证 Docker 是否运行

2. **恢复后验证**
   - 检查容器健康状况
   - 验证服务可访问性
   - 检查日志中的错误

---

## 快速参考命令

### 部署

```bash
# 安装
sudo cp src/vps-webdav-backup.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/vps-webdav-backup.sh
sudo cp src/vps-webdav-backup.conf /etc/
sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now vps-webdav-backup.timer

# 配置
sudo nano /etc/vps-webdav-backup.conf

# 测试
sudo systemctl start vps-webdav-backup.service
journalctl -u vps-webdav-backup.service -f

# 状态
systemctl list-timers vps-webdav-backup.timer
```

### 恢复

```bash
# 下载最新备份
source /etc/vps-webdav-backup.conf
LATEST=$(curl -s -X PROPFIND -u "${WEBDAV_USER}:${WEBDAV_PASS}" -H "Depth: 1" "${WEBDAV_URL}${WEBDAV_PATH}/" | grep -oP 'backup_[0-9_]+\.tar\.xz' | sort -r | head -1)
curl -u "${WEBDAV_USER}:${WEBDAV_PASS}" -O "${WEBDAV_URL}${WEBDAV_PATH}/${LATEST}"

# 解压
mkdir -p /tmp/restore && tar -xJf ${LATEST} -C /tmp/restore

# 恢复
rsync -av /tmp/restore/backup/dirs/project1/ /home/user/apps/project1/
sudo cp /tmp/restore/backup/files/Caddyfile /etc/caddy/

# 启动
cd /home/user/apps/project1 && docker compose up -d

# 清理
rm -rf /tmp/restore ${LATEST}
```

---

## 文件路径参考

| 文件 | 系统路径 |
|------|----------|
| 脚本 | `/usr/local/bin/vps-webdav-backup.sh` |
| 配置 | `/etc/vps-webdav-backup.conf` |
| 服务 | `/etc/systemd/system/vps-webdav-backup.service` |
| 定时器 | `/etc/systemd/system/vps-webdav-backup.timer` |
| 日志 | `journalctl -u vps-webdav-backup.service` |

---

## 更多帮助

如有问题，请参考：
- [DEPLOY.md](docs/DEPLOY.md) 部署相关问题
- [RESTORE.md](docs/RESTORE.md) 恢复相关问题
