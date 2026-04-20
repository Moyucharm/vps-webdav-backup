# AGENTS.md - AI Agent Operation Guide

This file provides complete context and instructions for AI coding agents (such as Claude, GPT-4, etc.) to automate deployment and restoration of VPS WebDAV Backup.

## Overview

VPS WebDAV Backup is a lightweight backup solution that:
- Backs up Docker Compose projects and configuration files
- Uploads to WebDAV-compatible storage
- Automatically rotates old backups
- Uses systemd timer for weekly scheduled backups

## Repository Structure

```
vps-webdav-backup/
├── README.md                 # Quick start guide
├── AGENTS.md                 # This file
├── src/
│   ├── vps-webdav-backup.sh  # Main backup script
│   └── vps-webdav-backup.conf # Configuration template
├── systemd/
│   ├── vps-webdav-backup.service
│   └── vps-webdav-backup.timer
└── docs/
    ├── DEPLOY.md             # Deployment documentation
    └── RESTORE.md            # Restoration documentation
```

---

## Scenario A: Deploy Backup Service

### User Prompt Template

```
Deploy the VPS WebDAV Backup service from https://github.com/USER/vps-webdav-backup

My WebDAV credentials:
- WEBDAV_URL: <url>
- WEBDAV_USER: <username>
- WEBDAV_PASS: <password>
- WEBDAV_PATH: /backup-folder

Directories to backup:
- /home/user/apps/project1
- /home/user/apps/project2
- /home/user/develop/project3

Extra files:
- /etc/caddy/Caddyfile

Schedule: Weekly on Monday at 03:00
```

### Agent Execution Steps

#### 1. Environment Check

```bash
# Check required tools
which docker docker-compose rsync curl tar systemctl

# Check systemd
systemctl --version
```

If any tool is missing, prompt user to install before proceeding.

#### 2. Clone Repository

```bash
git clone https://github.com/USER/vps-webdav-backup.git /tmp/vps-webdav-backup
cd /tmp/vps-webdav-backup
```

#### 3. Install Files

```bash
# Install script
sudo cp src/vps-webdav-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/vps-webdav-backup.sh

# Install configuration
sudo cp src/vps-webdav-backup.conf /etc/vps-webdav-backup.conf

# Install systemd units
sudo cp systemd/vps-webdav-backup.service /etc/systemd/system/
sudo cp systemd/vps-webdav-backup.timer /etc/systemd/system/
```

#### 4. Configure

Create `/etc/vps-webdav-backup.conf` with user-provided values:

```bash
# WebDAV Configuration
WEBDAV_URL="<user_provided>"
WEBDAV_USER="<user_provided>"
WEBDAV_PASS="<user_provided>"
WEBDAV_PATH="<user_provided>"

# Backup Rotation
KEEP_COUNT=3

# Directories to backup
BACKUP_DIRS=(
    "/home/user/apps/project1"
    "/home/user/apps/project2"
)

# Extra files
EXTRA_FILES=(
    "/etc/caddy/Caddyfile"
)

# Exclude patterns
EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    "*.log"
)
```

#### 5. Enable Timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable vps-webdav-backup.timer
sudo systemctl start vps-webdav-backup.timer
```

#### 6. Test Backup

```bash
sudo systemctl start vps-webdav-backup.service
journalctl -u vps-webdav-backup.service -f
```

#### 7. Verify

```bash
# Check timer status
systemctl list-timers vps-webdav-backup.timer

# Check logs
journalctl -u vps-webdav-backup.service -n 50
```

### Output to User

After completion, provide:
1. Status summary (installed/configured/tested)
2. Next scheduled backup time
3. How to manually trigger backup
4. How to view logs

---

## Scenario B: Restore from Backup

### Prerequisites

**IMPORTANT:** User must first deploy the backup service (Scenario A) to have WebDAV credentials configured.

### User Prompt Template

```
Restore from backup using VPS WebDAV Backup.

Repository: https://github.com/USER/vps-webdav-backup

Option A - Download latest backup and restore:
- Restore all projects

Option B - Restore specific backup file:
- Backup file: backup_YYYYMMDD_HHMMSS.tar.xz (already downloaded or WebDAV URL)

Target directories:
- /home/user/apps/project1
- /home/user/apps/project2

Extra files to restore:
- /etc/caddy/Caddyfile
```

### Agent Execution Steps

#### 1. Check Configuration

Verify WebDAV config exists:

```bash
if [[ -f /etc/vps-webdav-backup.conf ]]; then
    source /etc/vps-webdav-backup.conf
    echo "WebDAV URL: $WEBDAV_URL"
    echo "WebDAV Path: $WEBDAV_PATH"
else
    echo "Config not found. Please deploy backup service first."
    exit 1
fi
```

#### 2. Download Backup (if needed)

```bash
# List available backups
curl -s -X PROPFIND \
    -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
    -H "Depth: 1" \
    "${WEBDAV_URL}${WEBDAV_PATH}/" | grep tar.xz

# Download latest backup
LATEST_BACKUP=$(curl -s -X PROPFIND \
    -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
    -H "Depth: 1" \
    "${WEBDAV_URL}${WEBDAV_PATH}/" | \
    grep -oP 'backup_[0-9_]+\.tar\.xz' | \
    sort -r | head -1)

curl -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
    -O "${WEBDAV_URL}${WEBDAV_PATH}/${LATEST_BACKUP}"
```

#### 3. Extract Backup

```bash
# Create temp directory
mkdir -p /tmp/restore
cd /tmp/restore

# Extract
tar -xJf /path/to/backup_*.tar.xz

# Show contents
ls -la backup/dirs/
ls -la backup/files/
```

#### 4. Restore Directories

For each project in user's request:

```bash
PROJECT_NAME="project1"
SOURCE_DIR="/tmp/restore/backup/dirs/${PROJECT_NAME}"
TARGET_DIR="/home/user/apps/${PROJECT_NAME}"

# Check if target exists
if [[ -d "$TARGET_DIR" ]]; then
    echo "Warning: $TARGET_DIR already exists"
    # Ask user: overwrite/skip/backup_existing
fi

# Restore
mkdir -p "$TARGET_DIR"
rsync -av "$SOURCE_DIR/" "$TARGET_DIR/"
```

#### 5. Restore Extra Files

```bash
# Restore Caddyfile
sudo cp /tmp/restore/backup/files/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

#### 6. Start Docker Services

```bash
cd /home/user/apps/project1
docker compose pull
docker compose up -d
docker compose ps
```

#### 7. Cleanup

```bash
rm -rf /tmp/restore
rm -f /path/to/downloaded/backup.tar.xz
```

### Output to User

After completion, provide:
1. List of restored projects and files
2. Docker container status
3. Service health check results
4. Any warnings or manual steps needed

---

## Constraints and Guidelines

### For Both Scenarios

1. **Permission Handling**
   - Always use `sudo` for system directories
   - Check ownership after copy: `chown -R user:user /path`

2. **Error Handling**
   - Check if directories exist before copying
   - Verify downloads completed successfully (`curl -f` or check exit code)
   - Validate tar extraction

3. **User Interaction**
   - Prompt for missing values
   - Ask before overwriting existing files
   - Provide clear status messages

4. **Security**
   - Do not log passwords
   - Recommend secure credential handling
   - Warn about `.env` file permissions

### Restoration Specific

1. **Pre-restoration Check**
   - Warn if target directories exist
   - Check for port conflicts
   - Verify Docker is running

2. **Post-restoration Verification**
   - Check container health
   - Verify service accessibility
   - Check logs for errors

---

## Quick Reference Commands

### Deployment

```bash
# Install
sudo cp src/vps-webdav-backup.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/vps-webdav-backup.sh
sudo cp src/vps-webdav-backup.conf /etc/
sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now vps-webdav-backup.timer

# Configure
sudo nano /etc/vps-webdav-backup.conf

# Test
sudo systemctl start vps-webdav-backup.service
journalctl -u vps-webdav-backup.service -f

# Status
systemctl list-timers vps-webdav-backup.timer
```

### Restoration

```bash
# Download latest backup
source /etc/vps-webdav-backup.conf
LATEST=$(curl -s -X PROPFIND -u "${WEBDAV_USER}:${WEBDAV_PASS}" -H "Depth: 1" "${WEBDAV_URL}${WEBDAV_PATH}/" | grep -oP 'backup_[0-9_]+\.tar\.xz' | sort -r | head -1)
curl -u "${WEBDAV_USER}:${WEBDAV_PASS}" -O "${WEBDAV_URL}${WEBDAV_PATH}/${LATEST}"

# Extract
mkdir -p /tmp/restore && tar -xJf ${LATEST} -C /tmp/restore

# Restore
rsync -av /tmp/restore/backup/dirs/project1/ /home/user/apps/project1/
sudo cp /tmp/restore/backup/files/Caddyfile /etc/caddy/

# Start
cd /home/user/apps/project1 && docker compose up -d

# Cleanup
rm -rf /tmp/restore ${LATEST}
```

---

## File Paths Reference

| File | System Path |
|------|-------------|
| Script | `/usr/local/bin/vps-webdav-backup.sh` |
| Config | `/etc/vps-webdav-backup.conf` |
| Service | `/etc/systemd/system/vps-webdav-backup.service` |
| Timer | `/etc/systemd/system/vps-webdav-backup.timer` |
| Logs | `journalctl -u vps-webdav-backup.service` |

---

## Contact

For issues or questions, refer to:
- [DEPLOY.md](docs/DEPLOY.md) for deployment issues
- [RESTORE.md](docs/RESTORE.md) for restoration issues