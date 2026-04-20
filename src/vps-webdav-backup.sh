#!/bin/bash
#
# VPS WebDAV Backup Script
# Backups specified directories and files to WebDAV with automatic rotation
#

set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/etc/vps-webdav-backup.conf}"
LOG_TAG="vps-webdav-backup"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    logger -t "$LOG_TAG" "$1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    error_exit "Config file not found: $CONFIG_FILE"
fi

source "$CONFIG_FILE"

: "${WEBDAV_URL:?WEBDAV_URL is required}"
: "${WEBDAV_USER:?WEBDAV_USER is required}"
: "${WEBDAV_PASS:?WEBDAV_PASS is required}"
: "${WEBDAV_PATH:?WEBDAV_PATH is required}"
: "${KEEP_COUNT:=3}"
: "${TMP_DIR:=/tmp}"

BACKUP_NAME="backup_$(date '+%Y%m%d_%H%M%S')"
WORK_DIR="${TMP_DIR}/vps-webdav-backup-$$"
BACKUP_DIR="${WORK_DIR}/backup"
ARCHIVE_FILE="${TMP_DIR}/${BACKUP_NAME}.tar.xz"

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
    rm -f "$ARCHIVE_FILE"
}

trap cleanup EXIT

log "Starting backup: $BACKUP_NAME"
log "Work directory: $WORK_DIR"

mkdir -p "$BACKUP_DIR/dirs"
mkdir -p "$BACKUP_DIR/files"

RSYNC_EXCLUDE_ARGS=()
if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]]; then
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        RSYNC_EXCLUDE_ARGS+=(--exclude="$pattern")
    done
fi

for backup_dir in "${BACKUP_DIRS[@]:-}"; do
    if [[ -z "$backup_dir" ]]; then
        continue
    fi
    
    if [[ ! -d "$backup_dir" ]]; then
        log "WARNING: Directory not found: $backup_dir"
        continue
    fi

    dir_name=$(basename "$backup_dir")
    log "Processing directory: $dir_name"

    dest_dir="${BACKUP_DIR}/dirs/${dir_name}"
    mkdir -p "$dest_dir"

    if [[ ${#RSYNC_EXCLUDE_ARGS[@]} -gt 0 ]]; then
        rsync -a "${RSYNC_EXCLUDE_ARGS[@]}" "$backup_dir/" "$dest_dir/" 2>/dev/null || \
            cp -r "$backup_dir" "${BACKUP_DIR}/dirs/"
    else
        rsync -a "$backup_dir/" "$dest_dir/" 2>/dev/null || \
            cp -r "$backup_dir" "${BACKUP_DIR}/dirs/"
    fi
done

for extra_file in "${EXTRA_FILES[@]:-}"; do
    if [[ -z "$extra_file" ]]; then
        continue
    fi

    if [[ ! -e "$extra_file" ]]; then
        log "WARNING: File not found: $extra_file"
        continue
    fi

    log "Backing up extra file: $extra_file"
    
    file_name=$(basename "$extra_file")
    if [[ -f "$extra_file" ]]; then
        cp "$extra_file" "${BACKUP_DIR}/files/${file_name}"
    elif [[ -d "$extra_file" ]]; then
        cp -r "$extra_file" "${BACKUP_DIR}/files/"
    fi
done

num_dirs=$(find "${BACKUP_DIR}/dirs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
num_files=$(find "${BACKUP_DIR}/files" -type f 2>/dev/null | wc -l)
log "Backup contains: $num_dirs directories, $num_files extra files"

log "Creating compressed archive..."
cd "$WORK_DIR"
tar -cJf "$ARCHIVE_FILE" backup
ARCHIVE_SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
log "Archive created: ${BACKUP_NAME}.tar.xz (${ARCHIVE_SIZE})"

upload_to_webdav() {
    local file="$1"
    local remote_path="${WEBDAV_PATH}/${BACKUP_NAME}.tar.xz"
    local url="${WEBDAV_URL}${remote_path}"
    
    local attempt=1
    local max_attempts=3
    
    while [[ $attempt -le $max_attempts ]]; do
        log "Uploading to WebDAV (attempt $attempt/$max_attempts)..."
        
        local http_code
        http_code=$(curl -s -w "%{http_code}" -o /dev/null \
            -T "$file" \
            -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
            -H "Content-Type: application/octet-stream" \
            "$url")
        
        if [[ "$http_code" == "201" || "$http_code" == "200" || "$http_code" == "204" ]]; then
            log "Upload successful: $url"
            return 0
        fi
        
        log "Upload failed with HTTP $http_code"
        ((attempt++))
        sleep 5
    done
    
    return 1
}

if ! upload_to_webdav "$ARCHIVE_FILE"; then
    error_exit "Failed to upload backup after $max_attempts attempts"
fi

log "Cleaning up old backups on WebDAV..."

list_webdav_files() {
    local url="${WEBDAV_URL}${WEBDAV_PATH}/"
    
    curl -s -X PROPFIND \
        -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
        -H "Depth: 1" \
        -H "Content-Type: application/xml; charset=utf-8" \
        -d '<?xml version="1.0"?><propfind xmlns="DAV:"><prop></prop></propfind>' \
        "$url" 2>/dev/null | \
    grep -oP '(?<=<d:href>)[^<]+\.tar\.xz' | \
    sed 's/%20/ /g' | \
    while read -r href; do
        basename "$href"
    done | sort -r
}

backup_files=$(list_webdav_files)
backup_count=$(echo "$backup_files" | grep -c . || true)

if [[ $backup_count -gt $KEEP_COUNT ]]; then
    delete_count=$((backup_count - KEEP_COUNT))
    log "Found $backup_count backups, removing $delete_count old backup(s)..."
    
    echo "$backup_files" | tail -n "$delete_count" | while read -r old_file; do
        if [[ -n "$old_file" ]]; then
            delete_url="${WEBDAV_URL}${WEBDAV_PATH}/${old_file}"
            log "Deleting: $old_file"
            curl -s -X DELETE \
                -u "${WEBDAV_USER}:${WEBDAV_PASS}" \
                "$delete_url" > /dev/null
        fi
    done
fi

log "Backup completed successfully!"
log "Remote location: ${WEBDAV_URL}${WEBDAV_PATH}/${BACKUP_NAME}.tar.xz"

exit 0