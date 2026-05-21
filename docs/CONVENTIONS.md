# Project Conventions

This repository uses these rules for deployments, backups, and recovery.

## Paths

- Script: `/usr/local/bin/vps-webdav-backup.sh`
- Config: `/etc/vps-webdav-backup.conf`
- Service: `/etc/systemd/system/vps-webdav-backup.service`
- Timer: `/etc/systemd/system/vps-webdav-backup.timer`
- Deployment manifest: `/etc/vps-webdav-backup.manifest.md`

## Backup Layout

- Remote backups are stored under a host-specific folder.
- Remote path format: `<WEBDAV_PATH>/<hostname>/`
- Archive name format: `backup_YYYYMMDD_HHMMSS.tar.xz`
- Default retention: `5`

## Backup Scope Rules

- Every directory or file added to `BACKUP_DIRS` or `EXTRA_FILES` must be recorded in the deployment manifest.
- The manifest must note the original source path, the stored name inside the archive, and the restore target.
- Backups must not rely on memory alone; the manifest is the source of truth.

## Naming Rules

- Use the host name as the stable backup folder name.
- Sanitize host names and archive entries to safe filesystem names.
- Avoid duplicate source basenames when storing paths; preserve identity with path-based names.

## Reverse Proxy And Certificates

- Record the proxy type, config path, reload command, and validation command in the deployment manifest.
- Record the certificate source and renewal method in the deployment manifest.
- If no reverse proxy or certificate layer exists, record `none` explicitly.
- Typical reverse proxy paths to back up when present:
  - Caddy: `/etc/caddy/Caddyfile`
  - Nginx: `/etc/nginx/nginx.conf`, `/etc/nginx/sites-available`, `/etc/nginx/sites-enabled`
- Typical certificate locations to back up when present:
  - Let's Encrypt: `/etc/letsencrypt`
  - acme.sh: `~/.acme.sh`
  - Custom TLS bundles: `/etc/ssl`, `/etc/pki`

## Agent Workflow

Before changing deployment-related files, the agent must read:

- `README.md`
- `AGENTS_PROMPT.md`
- `docs/DEPLOY.md`
- `docs/RESTORE.md`
- `docs/CONVENTIONS.md`
- the deployment manifest on the server, if present

After changing backup scope or schedule, the agent must update the manifest and verify the timer state.
