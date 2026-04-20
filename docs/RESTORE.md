# Restoration Guide

This guide covers how to restore from backups created by VPS WebDAV Backup.

## Prerequisites

- A new or existing Linux server
- Docker and Docker Compose installed
- Access to your WebDAV storage (or local backup file)

## Quick Restore

### 1. Download Backup from WebDAV

```bash
# List available backups
curl -u "username:password" -X PROPFIND "https://your-webdav-server.com/backup-folder/" | grep tar.xz

# Download specific backup
curl -u "username:password" -O "https://your-webdav-server.com/backup-folder/backup_YYYYMMDD_HHMMSS.tar.xz"
```

### 2. Extract Backup

```bash
# Extract to temporary directory
mkdir -p /tmp/restore
tar -xJf backup_YYYYMMDD_HHMMSS.tar.xz -C /tmp/restore

# View backup contents
ls -la /tmp/restore/backup/
```

### 3. Restore Files

```bash
# Restore Docker Compose projects
cp -r /tmp/restore/backup/dirs/project1 /home/user/apps/

# Restore configuration files
sudo cp /tmp/restore/backup/files/Caddyfile /etc/caddy/Caddyfile
```

### 4. Start Services

```bash
# Navigate to project directory
cd /home/user/apps/project1

# Start Docker Compose services
docker compose up -d
```

### 5. Cleanup

```bash
# Remove temporary files
rm -rf /tmp/restore
rm backup_YYYYMMDD_HHMMSS.tar.xz
```

## Detailed Restoration

### Step 1: Download Backup

#### From WebDAV

```bash
# Download with authentication
curl -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
    -O "${WEBDAV_URL}${WEBDAV_PATH}/backup_YYYYMMDD_HHMMSS.tar.xz"
```

#### From Local File

If you already have the backup file locally:

```bash
# No download needed, proceed to extraction
```

### Step 2: Extract and Inspect

```bash
# Create temporary directory
mkdir -p /tmp/restore
cd /tmp/restore

# Extract (tar.xz format)
tar -xJf /path/to/backup_YYYYMMDD_HHMMSS.tar.xz

# View structure
tree /tmp/restore/backup/
```

**Expected structure:**

```
backup/
├── dirs/
│   └── project_name/
│       ├── docker-compose.yml
│       ├── .env
│       ├── Dockerfile (if any)
│       └── data/ (persistent volumes)
└── files/
    ├── Caddyfile
    └── nginx.conf
```

### Step 3: Verify Contents

```bash
# Check which projects are in the backup
ls /tmp/restore/backup/dirs/

# Check extra files
ls /tmp/restore/backup/files/
```

### Step 4: Restore Project Directories

For each project you want to restore:

```bash
# Example: Restore project named 'myapp'
PROJECT_NAME="myapp"
TARGET_DIR="/home/user/apps/${PROJECT_NAME}"

# Create target directory if not exists
mkdir -p "${TARGET_DIR}"

# Copy files
rsync -av /tmp/restore/backup/dirs/${PROJECT_NAME}/ "${TARGET_DIR}/"

# Check .env file
cat "${TARGET_DIR}/.env"
```

### Step 5: Restore Configuration Files

```bash
# Restore Caddy configuration
sudo cp /tmp/restore/backup/files/Caddyfile /etc/caddy/Caddyfile

# Restore Nginx configuration (if applicable)
sudo cp /tmp/restore/backup/files/nginx.conf /etc/nginx/nginx.conf

# Reload web server
sudo systemctl reload caddy
# or
sudo systemctl reload nginx
```

### Step 6: Start Docker Services

```bash
# For each restored project
cd /home/user/apps/project_name

# Pull images first (if using remote images)
docker compose pull

# Start services
docker compose up -d

# Check status
docker compose ps
docker compose logs -f
```

### Step 7: Verify Restoration

```bash
# Check running containers
docker ps

# Check container logs
docker compose logs -f

# Test web server
curl -I http://localhost:8080

# Check web server config
sudo caddy validate --config /etc/caddy/Caddyfile
```

## Selective Restoration

You don't have to restore everything. Here's how to restore selectively:

### Restore Specific Project Only

```bash
# Only restore 'specific-project'
PROJECT_NAME="specific-project"
rsync -av /tmp/restore/backup/dirs/${PROJECT_NAME}/ /home/user/apps/${PROJECT_NAME}/
```

### Restore Only Configuration Files

```bash
# Only restore Caddyfile
sudo cp /tmp/restore/backup/files/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

### Restore Only Data Directory

```bash
# Only restore data directory from a project
rsync -av /tmp/restore/backup/dirs/myapp/data/ /home/user/apps/myapp/data/
docker compose restart myapp
```

## Cross-Device Restoration

When restoring on a different server:

### 1. Environment Differences

```bash
# Check for hardcoded paths in docker-compose.yml
grep -r "/home/" /tmp/restore/backup/dirs/*/docker-compose.yml

# Check for hardcoded IPs
grep -r "192.168\|10.\|172." /tmp/restore/backup/dirs/
```

### 2. Adjust Configuration

```bash
# Edit docker-compose.yml if paths differ
nano /home/user/apps/project/docker-compose.yml

# Update .env file for new server
nano /home/user/apps/project/.env
```

### 3. Port Conflicts

```bash
# Check used ports
ss -tulpn

# If port conflicts, modify docker-compose.yml
# ports:
#   - "127.0.0.1:NEW_PORT:8080"
```

### 4. Docker Volume Paths

```bash
# If using named volumes, verify they exist
docker volume ls

# Create volumes if needed
docker volume create my_volume
```

## Automation with AI Agent

For automated restoration using an AI coding agent, see [AGENTS.md](../AGENTS.md) which provides:
- Complete context for the agent
- Step-by-step restoration prompts
- Dependency handling instructions

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `Permission denied` | Use `sudo` or adjust ownership with `chown` |
| `Port already in use` | Change port in `docker-compose.yml` |
| `Volume not found` | Create volume: `docker volume create <name>` |
| `.env file missing` | Check if `.env` is in backup, create from `.env.example` |
| `Image not found` | Check if image exists: `docker pull <image>` |

### Database Restoration

If your backup contains databases (SQLite, MySQL, PostgreSQL):

```bash
# SQLite files are typically in data/ directory
# Just restore and restart the container

# For MySQL/PostgreSQL, restore from dumps:
docker exec -i db_container mysql -u user -ppass dbname < dump.sql
docker exec -i db_container psql -U user -d dbname < dump.sql
```

### Rollback

If restoration fails or causes issues:

```bash
# Stop containers
docker compose down

# Remove restored files
rm -rf /home/user/apps/project_name

# Start fresh or restore from another backup
```

## Post-Restoration Checklist

- [ ] All Docker containers are running (`docker ps`)
- [ ] Services are accessible via web browser
- [ ] Configuration files are correct
- [ ] Environment variables are set (`.env` files)
- [ ] Persistent data is intact
- [ ] Logs show no errors (`docker compose logs`)
- [ ] Web server config validated and reloaded