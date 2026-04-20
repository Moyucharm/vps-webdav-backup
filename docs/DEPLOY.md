# Deployment Guide

This guide covers how to deploy VPS WebDAV Backup on your server.

## Prerequisites

- Linux server with systemd
- Docker and Docker Compose (if backing up Docker projects)
- `rsync`, `curl`, `tar` (usually pre-installed on most Linux distributions)
- WebDAV-compatible storage (e.g., Nextcloud, ownCloud, Synology NAS,坚果云)

## Installation

### Option 1: Manual Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/your-username/vps-webdav-backup.git
cd vps-webdav-backup
```

#### 2. Install Script and Configuration

```bash
# Install the backup script
sudo cp src/vps-webdav-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/vps-webdav-backup.sh

# Install the configuration template
sudo cp src/vps-webdav-backup.conf /etc/vps-webdav-backup.conf

# Install systemd units
sudo cp systemd/vps-webdav-backup.service /etc/systemd/system/
sudo cp systemd/vps-webdav-backup.timer /etc/systemd/system/
```

#### 3. Configure

Edit the configuration file:

```bash
sudo nano /etc/vps-webdav-backup.conf
```

**Required Fields:**

```bash
# WebDAV Configuration
WEBDAV_URL="https://your-webdav-server.com"
WEBDAV_USER="your_username"
WEBDAV_PASS="your_password_or_token"
WEBDAV_PATH="/your-backup-folder"

# Directories to backup
BACKUP_DIRS=(
    "/home/user/apps/docker-project1"
    "/home/user/apps/docker-project2"
    "/home/user/develop/project3"
)
```

**Optional Fields:**

```bash
# Extra files (e.g., web server configs)
EXTRA_FILES=(
    "/etc/caddy/Caddyfile"
    "/etc/nginx/nginx.conf"
)

# Exclude patterns
EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    "*.log"
    "__pycache__"
)

# Rotation count
KEEP_COUNT=3
```

#### 4. Enable and Start Timer

```bash
# Reload systemd daemon
sudo systemctl daemon-reload

# Enable the timer (starts automatically on boot)
sudo systemctl enable vps-webdav-backup.timer

# Start the timer
sudo systemctl start vps-webdav-backup.timer
```

### Option 2: Using Makefile

```bash
# Install everything
sudo make install

# Edit configuration
sudo nano /etc/vps-webdav-backup.conf

# Enable timer
sudo systemctl enable --now vps-webdav-backup.timer
```

## Testing

### Manual Test Run

```bash
# Run backup manually
sudo systemctl start vps-webdav-backup.service

# View logs
journalctl -u vps-webdav-backup.service -f
```

### Verify Upload

Check your WebDAV storage to confirm the backup file was uploaded:

```bash
# List remote backups
curl -u "username:password" -X PROPFIND "https://your-webdav-server.com/your-backup-folder/" | grep tar.xz
```

## Configuration Reference

### WebDAV Settings

| Variable | Description | Example |
|----------|-------------|---------|
| `WEBDAV_URL` | WebDAV server base URL | `https://dav.example.com` |
| `WEBDAV_USER` | WebDAV username | `admin` |
| `WEBDAV_PASS` | WebDAV password or app token | `secret_token` |
| `WEBDAV_PATH` | Remote backup directory | `/backup/vps1` |

### Backup Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `BACKUP_DIRS` | Array of directories to backup | (required) |
| `EXTRA_FILES` | Array of additional files/directories | (empty) |
| `EXCLUDE_PATTERNS` | rsync-style exclude patterns | `.git`, `node_modules`, etc. |
| `KEEP_COUNT` | Number of backups to retain | `3` |
| `TMP_DIR` | Temporary directory for archive creation | `/tmp` |

## Scheduling

By default, the timer runs every Monday at 03:00 AM.

### Change Schedule

Edit the timer file:

```bash
sudo nano /etc/systemd/system/vps-webdav-backup.timer
```

Modify `OnCalendar`:

```ini
# Every day at 2:00 AM
OnCalendar=*-*-* 02:00:00

# Every Sunday at 4:00 AM
OnCalendar=Sun *-*-* 04:00:00

# First day of every month at 3:00 AM
OnCalendar=*-*-01 03:00:00
```

After changes:

```bash
sudo systemctl daemon-reload
sudo systemctl restart vps-webdav-backup.timer
```

### View Next Scheduled Run

```bash
systemctl list-timers vps-webdav-backup.timer
```

## Troubleshooting

### Check Service Status

```bash
# Check if timer is active
sudo systemctl status vps-webdav-backup.timer

# Check service logs
journalctl -u vps-webdav-backup.service -n 50
```

### Common Issues

| Issue | Solution |
|-------|----------|
| `Permission denied` | Run with `sudo` or check file permissions |
| `WebDAV upload failed` | Verify credentials and URL; check network connectivity |
| `No space left on device` | Clean `/tmp` or change `TMP_DIR` in config |
| `rsync: command not found` | Install rsync: `sudo apt install rsync` |

### Debug Mode

Run the script directly for debugging:

```bash
sudo bash -x /usr/local/bin/vps-webdav-backup.sh
```

## Uninstallation

```bash
# Stop and disable timer
sudo systemctl stop vps-webdav-backup.timer
sudo systemctl disable vps-webdav-backup.timer

# Remove files
sudo rm /usr/local/bin/vps-webdav-backup.sh
sudo rm /etc/vps-webdav-backup.conf
sudo rm /etc/systemd/system/vps-webdav-backup.service
sudo rm /etc/systemd/system/vps-webdav-backup.timer

# Reload systemd
sudo systemctl daemon-reload
```

Or using Makefile:

```bash
sudo make uninstall
```