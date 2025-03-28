#!/bin/bash

# Backup Manager Script
# Creates timestamped backups, implements rotation policy, verifies integrity, and logs operations

# Configuration
BACKUP_DIRS=("/etc" "/home" "/var/www")  # Directories to back up
DEST_DIR="/backups"                      # Where to store backups
RETENTION_DAYS=7                         # Keep backups for X days
COMPRESSION="gz"                        # Options: gz, bz2, xz, zst
LOG_FILE="/var/log/backup_manager.log"
INTEGRITY_CHECK=true                     # Verify backup integrity
EMAIL_NOTIFY="obasorokunle@gmail.com"         # Leave empty to disable email
MAX_BACKUP_SIZE=$((10 * 1024 * 1024))    # 10MB max size for individual files

# Create required directories
mkdir -p "$DEST_DIR"
touch "$LOG_FILE"

# Logging function
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    if [ -n "$EMAIL_NOTIFY" ]; then
        echo "Backup failed: $1" | mail -s "Backup Failure Alert" "$EMAIL_NOTIFY"
    fi
    exit 1
}

# Determine compression tool
set_compression() {
    case "$COMPRESSION" in
        gz)
            COMPRESS_CMD="gzip"
            EXT=".gz"
            ;;
        bz2)
            COMPRESS_CMD="bzip2"
            EXT=".bz2"
            ;;
        xz)
            COMPRESS_CMD="xz"
            EXT=".xz"
            ;;
        zst)
            if command -v zstd &>/dev/null; then
                COMPRESS_CMD="zstd"
                EXT=".zst"
            else
                log "zstd not found, falling back to gzip"
                COMPRESS_CMD="gzip"
                EXT=".gz"
                COMPRESSION="gz"
            fi
            ;;
        *)
            error_exit "Invalid compression type: $COMPRESSION"
            ;;
    esac
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    log "Verifying backup integrity: $backup_file"
    
    case "$COMPRESSION" in
        gz)
            if ! gzip -t "$backup_file"; then
                error_exit "Backup integrity check failed for $backup_file"
            fi
            ;;
        bz2)
            if ! bzip2 -t "$backup_file"; then
                error_exit "Backup integrity check failed for $backup_file"
            fi
            ;;
        xz)
            if ! xz -t "$backup_file"; then
                error_exit "Backup integrity check failed for $backup_file"
            fi
            ;;
        zst)
            if ! zstd -t "$backup_file"; then
                error_exit "Backup integrity check failed for $backup_file"
            fi
            ;;
    esac
    
    log "Backup integrity verified: $backup_file"
}

# Create timestamped backup
create_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="backup_${timestamp}.tar"
    local backup_path="${DEST_DIR}/${backup_name}${EXT}"
    
    log "Starting new backup: $backup_path"
    
    # Check for large files
    for dir in "${BACKUP_DIRS[@]}"; do
        while IFS= read -r file; do
            local size=$(stat -c%s "$file" 2>/dev/null)
            if [ "$size" -gt "$MAX_BACKUP_SIZE" ]; then
                log "WARNING: Large file detected (${file} - $(($size/1024/1024))MB), excluding from backup"
                BACKUP_EXCLUDE+=" --exclude=${file#/}"
            fi
        done < <(find "$dir" -type f -size +"$MAX_BACKUP_SIZE"c 2>/dev/null)
    done
    
    # Create backup
    if ! tar --exclude-backups --exclude-caches --exclude-vcs $BACKUP_EXCLUDE \
         -cf - "${BACKUP_DIRS[@]}" | $COMPRESS_CMD > "$backup_path"; then
        error_exit "Backup creation failed"
    fi
    
    log "Backup created successfully: $backup_path ($(du -h "$backup_path" | cut -f1))"
    
    if [ "$INTEGRITY_CHECK" = true ]; then
        verify_backup "$backup_path"
    fi
    
    echo "$backup_path" >> "${DEST_DIR}/backup_manifest.txt"
}

# Rotate old backups
rotate_backups() {
    log "Rotating backups older than $RETENTION_DAYS days"
    
    # Find and delete old backups
    find "$DEST_DIR" -name "backup_*" -type f -mtime +$RETENTION_DAYS -print0 | while IFS= read -r -d $'\0' backup; do
        log "Deleting old backup: $backup"
        rm -f "$backup"
        
        # Cleanup manifest entries
        sed -i "\|${backup##*/}|d" "${DEST_DIR}/backup_manifest.txt"
    done
    
    # Keep at least one backup even if it's old
    if [ -z "$(ls -A "$DEST_DIR"/backup_* 2>/dev/null)" ]; then
        log "Warning: No backups found after rotation"
    fi
}

# Main execution
main() {
    log "=== Starting Backup Manager ==="
    set_compression
    create_backup
    rotate_backups
    log "=== Backup Completed Successfully ==="
    
    if [ -n "$EMAIL_NOTIFY" ]; then
        echo "Backup completed successfully at $(date)" | mail -s "Backup Success Notification" "$EMAIL_NOTIFY"
    fi
}
