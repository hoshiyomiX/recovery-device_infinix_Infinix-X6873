#!/vendor/bin/sh
#
# Automatic TA (Trusted Application) Update Script for Infinix X6873
# This script runs at boot-time before TEE initialization
# to detect and update TA files if firmware has changed
#
# Version: 1.0
# Part of: Dynamic TA Update Implementation
#
# Integration: Called by ta_auto_check service in init.recovery.mt6897.rc
# Timing: Runs BEFORE TEE kernel module is loaded
#

SCRIPT_VERSION="1.0"
DEVICE="X6873"

# Paths
VENDOR_TA_DIR="/vendor/app/mcRegistry"
PERSIST_TA_DIR="/mnt/vendor/persist/mcRegistry"
BACKUP_DIR="/mnt/vendor/persist/ta_backup"
LOGFILE="/tmp/ta_auto_update.log"
VERSION_FILE="/mnt/vendor/persist/ta_version.txt"
EXTERNAL_TA_DIR="/sdcard/firmware/mcRegistry"

# Critical TA files for decryption (must be valid for successful decryption)
CRITICAL_TAS="
06090000000000000000000000000000.drbin
06090000000000000000000000000000.tlbin
08050000000000000000000000003419.drbin
08050000000000000000000000003419.tlbin
07210000000000000000000000000000.drbin
07210000000000000000000000000000.tlbin
40188311faf343488db888ad39496f9a.drbin
40188311faf343488db888ad39496f9a.tlbin
5020170115e016302017012521300000.drbin
5020170115e016302017012521300000.tlbin
"

# State tracking
MISMATCH_COUNT=0
UPDATE_NEEDED=0
UPDATE_SOURCE=""

# ========================================
# Logging Functions
# ========================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
    echo "$1"
}

log_info() {
    log "[INFO] $1"
}

log_warn() {
    log "[WARN] $1"
}

log_error() {
    log "[ERROR] $1"
}

# ========================================
# SHA256 Checksum Function
# ========================================
get_sha256() {
    if [ -f "$1" ]; then
        sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    else
        echo ""
    fi
}

# ========================================
# Phase 1: Detection
# Compare vendor TA with persist TA
# ========================================
detect_ta_mismatch() {
    log_info "Phase 1: Detecting TA mismatch..."
    
    MISMATCH_COUNT=0
    
    # Check if persist TA directory exists
    if [ ! -d "$PERSIST_TA_DIR" ]; then
        log_warn "Persist TA directory not found: $PERSIST_TA_DIR"
        log_info "Cannot detect mismatch - using bundled TA"
        return 1
    fi
    
    # Check each critical TA
    for ta in $CRITICAL_TAS; do
        vendor_file="$VENDOR_TA_DIR/$ta"
        persist_file="$PERSIST_TA_DIR/$ta"
        
        if [ -f "$persist_file" ]; then
            if [ -f "$vendor_file" ]; then
                vendor_sha=$(get_sha256 "$vendor_file")
                persist_sha=$(get_sha256 "$persist_file")
                
                if [ "$vendor_sha" != "$persist_sha" ]; then
                    log_warn "TA mismatch: $ta"
                    log "  Vendor SHA256: $vendor_sha"
                    log "  Persist SHA256: $persist_sha"
                    MISMATCH_COUNT=$((MISMATCH_COUNT + 1))
                else
                    log_info "TA match: $ta"
                fi
            else
                log_warn "TA missing in vendor: $ta"
                MISMATCH_COUNT=$((MISMATCH_COUNT + 1))
            fi
        else
            log_info "TA not in persist: $ta (skipping)"
        fi
    done
    
    log_info "Total TA mismatches detected: $MISMATCH_COUNT"
    
    # Require at least 3 mismatches to trigger update (avoid false positives)
    if [ $MISMATCH_COUNT -ge 3 ]; then
        UPDATE_NEEDED=1
        UPDATE_SOURCE="$PERSIST_TA_DIR"
        log_warn "Update threshold reached - update needed"
        return 0
    elif [ $MISMATCH_COUNT -gt 0 ]; then
        log_warn "Mismatches detected but below threshold - manual intervention may be needed"
    fi
    
    # Check external source if available
    if [ -d "$EXTERNAL_TA_DIR" ]; then
        log_info "Checking external TA source..."
        external_count=$(ls -1 "$EXTERNAL_TA_DIR"/*.tlbin 2>/dev/null | wc -l)
        if [ $external_count -gt 8 ]; then
            log_info "External TA source available: $external_count files"
            # Could prompt user or use as alternative source
        fi
    fi
    
    return 1
}

# ========================================
# Phase 2: Validation
# Validate TA files before update
# ========================================
validate_ta_source() {
    local source_dir="$1"
    
    log_info "Phase 2: Validating TA source: $source_dir"
    
    if [ ! -d "$source_dir" ]; then
        log_error "Source directory not found"
        return 1
    fi
    
    # Count TA files
    local drbin_count=$(ls -1 "$source_dir"/*.drbin 2>/dev/null | wc -l)
    local tlbin_count=$(ls -1 "$source_dir"/*.tlbin 2>/dev/null | wc -l)
    local tabin_count=$(ls -1 "$source_dir"/*.tabin 2>/dev/null | wc -l)
    
    log_info "TA files found: $drbin_count drivers, $tlbin_count apps, $tabin_count tabin"
    
    # Require minimum TA count
    if [ $drbin_count -lt 10 ] || [ $tlbin_count -lt 10 ]; then
        log_error "Insufficient TA files in source"
        return 1
    fi
    
    # Verify critical TAs exist
    local missing_critical=0
    for ta in $CRITICAL_TAS; do
        if [ ! -f "$source_dir/$ta" ]; then
            log_warn "Critical TA missing in source: $ta"
            missing_critical=$((missing_critical + 1))
        fi
    done
    
    if [ $missing_critical -gt 4 ]; then
        log_error "Too many critical TAs missing - aborting update"
        return 1
    fi
    
    log_info "TA source validation passed"
    return 0
}

# ========================================
# Phase 3: Backup
# Create backup of current TA
# ========================================
backup_current_ta() {
    log_info "Phase 3: Creating backup of current TA files..."
    
    if [ ! -d "$VENDOR_TA_DIR" ]; then
        log_warn "Vendor TA directory not found - nothing to backup"
        return 0
    fi
    
    # Create backup directory with timestamp
    local backup_ts="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_ts"
    
    # Copy current TA files
    local count=0
    for file in "$VENDOR_TA_DIR"/*.drbin "$VENDOR_TA_DIR"/*.tlbin "$VENDOR_TA_DIR"/*.tabin; do
        if [ -f "$file" ]; then
            cp "$file" "$backup_ts/"
            count=$((count + 1))
        fi
    done
    
    # Create backup metadata
    echo "Backup Date: $(date)" > "$backup_ts/metadata.txt"
    echo "Device: $DEVICE" >> "$backup_ts/metadata.txt"
    echo "Firmware: $(getprop ro.build.fingerprint)" >> "$backup_ts/metadata.txt"
    echo "Files: $count" >> "$backup_ts/metadata.txt"
    
    # Also update main backup directory
    mkdir -p "$BACKUP_DIR/latest"
    cp -r "$VENDOR_TA_DIR"/* "$BACKUP_DIR/latest/" 2>/dev/null
    
    log_info "Backup created: $backup_ts ($count files)"
    
    # Cleanup old backups (keep last 5)
    local backup_count=$(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)
    if [ $backup_count -gt 5 ]; then
        local oldest=$(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | head -1)
        rm -rf "$oldest"
        log_info "Cleaned up old backup: $oldest"
    fi
    
    return 0
}

# ========================================
# Phase 4: Update
# Copy TA from source to vendor
# ========================================
perform_ta_update() {
    local source_dir="$1"
    
    log_info "Phase 4: Performing TA update from: $source_dir"
    
    # Try to remount vendor as RW
    mount -o remount,rw /vendor 2>/dev/null
    if [ $? -ne 0 ]; then
        log_warn "Could not remount vendor as RW - trying alternative method"
        # Alternative: update in ramdisk overlay
        mkdir -p /tmp/mcRegistry_update
        cp -r "$source_dir"/* /tmp/mcRegistry_update/
        
        # Create symlink overlay
        for file in /tmp/mcRegistry_update/*; do
            if [ -f "$file" ]; then
                local filename=$(basename "$file")
                local target="$VENDOR_TA_DIR/$filename"
                if [ -f "$target" ]; then
                    rm -f "$target"
                fi
                cp "$file" "$VENDOR_TA_DIR/" 2>/dev/null || true
            fi
        done
        
        log_info "TA update attempted via copy method"
    else
        # Direct copy to vendor
        local updated=0
        for file in "$source_dir"/*.drbin "$source_dir"/*.tlbin "$source_dir"/*.tabin; do
            if [ -f "$file" ]; then
                local filename=$(basename "$file")
                cp "$file" "$VENDOR_TA_DIR/"
                chmod 644 "$VENDOR_TA_DIR/$filename"
                updated=$((updated + 1))
            fi
        done
        
        # Remount vendor as RO
        mount -o remount,ro /vendor 2>/dev/null
        
        log_info "Updated $updated TA files"
    fi
    
    return 0
}

# ========================================
# Phase 5: Verify
# Verify updated TA files
# ========================================
verify_ta_update() {
    log_info "Phase 5: Verifying TA update..."
    
    local verify_failed=0
    
    for ta in $CRITICAL_TAS; do
        if [ -f "$VENDOR_TA_DIR/$ta" ]; then
            local size=$(stat -c%s "$VENDOR_TA_DIR/$ta" 2>/dev/null)
            if [ "$size" -gt 0 ]; then
                log_info "Verified: $ta ($size bytes)"
            else
                log_error "Zero-size file: $ta"
                verify_failed=$((verify_failed + 1))
            fi
        else
            log_error "Missing after update: $ta"
            verify_failed=$((verify_failed + 1))
        fi
    done
    
    if [ $verify_failed -gt 0 ]; then
        log_error "Verification failed: $verify_failed files"
        return 1
    fi
    
    log_info "TA update verification passed"
    return 0
}

# ========================================
# Phase 6: Fallback
# Restore from backup if needed
# ========================================
restore_from_backup() {
    log_info "Phase 6: Attempting restore from backup..."
    
    local latest_backup="$BACKUP_DIR/latest"
    
    if [ ! -d "$latest_backup" ]; then
        log_error "No backup found for restore"
        return 1
    fi
    
    # Try to remount vendor as RW
    mount -o remount,rw /vendor 2>/dev/null
    
    # Restore from backup
    local restored=0
    for file in "$latest_backup"/*.drbin "$latest_backup"/*.tlbin "$latest_backup"/*.tabin; do
        if [ -f "$file" ]; then
            cp "$file" "$VENDOR_TA_DIR/"
            restored=$((restored + 1))
        fi
    done
    
    mount -o remount,ro /vendor 2>/dev/null
    
    log_info "Restored $restored files from backup"
    return 0
}

# ========================================
# Version Tracking
# ========================================
update_version_file() {
    local source_dir="$1"
    
    log_info "Updating version tracking..."
    
    # Create version file
    echo "TA Version: auto_update_v${SCRIPT_VERSION}" > "$VERSION_FILE"
    echo "Update Date: $(date)" >> "$VERSION_FILE"
    echo "Source: $source_dir" >> "$VERSION_FILE"
    echo "Firmware: $(getprop ro.build.fingerprint)" >> "$VERSION_FILE"
    
    # Add checksums of critical TAs
    echo "" >> "$VERSION_FILE"
    echo "Critical TA Checksums:" >> "$VERSION_FILE"
    for ta in $CRITICAL_TAS; do
        if [ -f "$VENDOR_TA_DIR/$ta" ]; then
            local sha=$(get_sha256 "$VENDOR_TA_DIR/$ta")
            echo "  $ta: $sha" >> "$VERSION_FILE"
        fi
    done
    
    log_info "Version file updated: $VERSION_FILE"
}

# ========================================
# Main Entry Point
# ========================================
main() {
    log "=========================================="
    log "TA Auto Update Script v${SCRIPT_VERSION}"
    log "Device: $DEVICE"
    log "=========================================="
    
    # Initialize properties
    setprop ro.vendor.ta.check_running 1
    setprop ro.vendor.ta.ready 0
    setprop ro.vendor.ta.updated 0
    setprop ro.vendor.ta.update_failed 0
    
    # Phase 1: Detection
    if detect_ta_mismatch; then
        # Phase 2: Validation
        if validate_ta_source "$UPDATE_SOURCE"; then
            # Phase 3: Backup
            if backup_current_ta; then
                # Phase 4: Update
                if perform_ta_update "$UPDATE_SOURCE"; then
                    # Phase 5: Verify
                    if verify_ta_update; then
                        # Success!
                        update_version_file "$UPDATE_SOURCE"
                        setprop ro.vendor.ta.updated 1
                        setprop ro.vendor.ta.ready 1
                        log_info "TA UPDATE SUCCESSFUL"
                    else
                        # Verification failed - try fallback
                        log_error "Verification failed - attempting fallback"
                        if restore_from_backup; then
                            setprop ro.vendor.ta.update_failed 1
                            setprop ro.vendor.ta.ready 1
                            log_warn "TA UPDATE FAILED - RESTORED FROM BACKUP"
                        else
                            setprop ro.vendor.ta.update_failed 1
                            setprop ro.vendor.ta.ready 1
                            log_error "TA UPDATE FAILED - BACKUP RESTORE ALSO FAILED"
                        fi
                    fi
                else
                    log_error "Update operation failed"
                    setprop ro.vendor.ta.update_failed 1
                    setprop ro.vendor.ta.ready 1
                fi
            else
                log_error "Backup failed - aborting update"
                setprop ro.vendor.ta.update_failed 1
                setprop ro.vendor.ta.ready 1
            fi
        else
            log_error "Source validation failed"
            setprop ro.vendor.ta.update_failed 1
            setprop ro.vendor.ta.ready 1
        fi
    else
        log_info "No TA update needed"
        setprop ro.vendor.ta.ready 1
    fi
    
    setprop ro.vendor.ta.check_running 0
    
    log "=========================================="
    log "TA Auto Update Complete"
    log "Updated: $(getprop ro.vendor.ta.updated)"
    log "Failed: $(getprop ro.vendor.ta.update_failed)"
    log "Ready: $(getprop ro.vendor.ta.ready)"
    log "=========================================="
    
    return 0
}

# Run main
main
exit $?
