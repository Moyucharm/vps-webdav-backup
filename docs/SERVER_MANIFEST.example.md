# VPS WebDAV Backup Deployment Manifest

This file should be copied to the target server and kept in sync with the live deployment.

## Host

- Hostname:
- OS:
- Deployed by:
- Deployed at:

## Installed Files

- Script: `/usr/local/bin/vps-webdav-backup.sh`
- Config: `/etc/vps-webdav-backup.conf`
- Service: `/etc/systemd/system/vps-webdav-backup.service`
- Timer: `/etc/systemd/system/vps-webdav-backup.timer`

## WebDAV

- WEBDAV_URL:
- WEBDAV_PATH:
- Host backup folder: `<WEBDAV_PATH>/<hostname>/`
- KEEP_COUNT: `5`

## Schedule

- Timer unit: `vps-webdav-backup.timer`
- OnCalendar:
- Persistent:
- RandomizedDelaySec:

## Reverse Proxy

- Type: `none`
- Config files:
- Reload command:
- Validation command:
- Notes:

## Certificates

- Provider: `none`
- Config files:
- Renewal method:
- Renewal timer or service:
- Notes:

## Backup Scope

### BACKUP_DIRS

- Source:
- Stored as:
- Restore target:
- Notes:

### EXTRA_FILES

- Source:
- Stored as:
- Restore target:
- Notes:

## Verification

- Last manual backup:
- Last successful upload:
- Last restore check:
- Notes:
