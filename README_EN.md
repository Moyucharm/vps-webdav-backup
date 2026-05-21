# VPS WebDAV Backup

A lightweight backup solution for VPS that backs up Docker Compose projects and configuration files to WebDAV with automatic rotation.

## Features

- **Zero Service Interruption** - Backups run without stopping containers
- **WebDAV Support** - Upload backups to any WebDAV-compatible storage
- **Automatic Rotation** - Keep only specified number of backups
- **Configurable Exclusions** - Exclude patterns (e.g., `.git`, `node_modules`, `*.log`)
- **Systemd Integration** - Weekly scheduled backups via systemd timer
- **Simple Recovery** - Easy restoration on new devices

## Quick Start

### 1. Download

```bash
git clone https://github.com/your-username/vps-webdav-backup.git
cd vps-webdav-backup
```

### 2. Install

```bash
sudo make install
```

### 3. Configure

```bash
sudo nano /etc/vps-webdav-backup.conf
```

Edit the following required fields:

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

### 4. Enable Timer

```bash
sudo systemctl enable --now vps-webdav-backup.timer
```

### 5. Test Backup

```bash
sudo systemctl start vps-webdav-backup.service
journalctl -u vps-webdav-backup.service -f
```

## Documentation

- [DEPLOY.md](docs/DEPLOY.md) - Detailed deployment guide
- [RESTORE.md](docs/RESTORE.md) - Recovery and restoration guide
- [AGENTS.md](AGENTS.md) - AI Agent instructions for automated deployment

## Configuration

| Variable | Required | Description |
|----------|----------|-------------|
| `WEBDAV_URL` | Yes | WebDAV server URL |
| `WEBDAV_USER` | Yes | WebDAV username |
| `WEBDAV_PASS` | Yes | WebDAV password or token |
| `WEBDAV_PATH` | Yes | Remote backup directory (e.g., `/backup`) |
| `KEEP_COUNT` | No | Number of backups to keep (default: 5) |
| `BACKUP_DIRS` | Yes* | Directories to backup (Docker Compose projects) |
| `EXTRA_FILES` | No | Additional files to backup |
| `EXCLUDE_PATTERNS` | No | Patterns to exclude from backup |

*Either `BACKUP_DIRS` or `EXTRA_FILES` should be configured.

## Backup Structure

```
backup_YYYYMMDD_HHMMSS.tar.xz
├── dirs/
│   ├── home__user__apps__project1/
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── data/
│   └── home__user__apps__project2/
│       └── docker-compose.yml
└── files/
    ├── etc__caddy__Caddyfile
    └── etc__nginx__nginx.conf
```

## Requirements

- Linux with systemd
- Docker (for Docker Compose projects)
- `rsync`, `curl`, `tar` (usually pre-installed)
- WebDAV-compatible storage service

## License

MIT License - see [LICENSE](LICENSE)
