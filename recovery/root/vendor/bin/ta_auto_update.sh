#!/vendor/bin/sh
#
# TA Auto-Update Script for Infinix X6873 (GT 30 Pro)
# Version: 2.0 - Cross-Firmware Compatibility
#
# This script handles automatic TA (Trusted Application) synchronization
# to ensure decryption works across all firmware versions.
#
# Features:
# - SHA256 checksum validation (not just size)
# - Automatic TA sync from persist to vendor
# - TA backup before update
# - Version tracking for rollback
# - Works across firmware updates
#

SCRIPT_VERSION="2.0"
DEVICE="X6873"
PLATFORM="mt6897"

# Paths
VENDOR_MC="/vendor/app/mcRegistry"
PERSIST_MC="/mnt/vendor/persist/mcRegistry"
BACKUP_DIR="/mnt/vendor/persist/mcRegistry_backup"
VERSION_FILE="/mnt/vendor/persist/.ta_version"
VENDOR_VERSION_FILE="/vendor/app/mcRegistry/.ta_version"
LOGFILE="/tmp/ta_auto_update.log"
CHECKSUM_DIR="/mnt/vendor/persist/.ta_checksums"

# Critical TAs for decryption - these MUST match
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
020f0000000000000000000000000000.drbin
020f0000000000000000000000000000.tlbin
"

# All TA files to sync
ALL_TA_FILES="
020b0000000000000000000000000000.drbin
020f0000000000000000000000000000.drbin
020f0000000000000000000000000000.tlbin
030b0000000000000000000000000000.drbin
030c0000000000000000000000000000.drbin
03100000000000000000000000000000.drbin
031c0000000000000000000000000000.drbin
031c0000000000000000000000000000.tlbin
032c0000000000000000000000000000.drbin
033c0000000000000000000000000000.drbin
034c0000000000000000000000000000.drbin
035c0000000000000000000000000000.drbin
036c0000000000000000000000000000.drbin
037c0000000000000000000000000000.drbin
05070000000000000000000000000000.drbin
05070000000000000000000000000000.tlbin
05120000000000000000000000000000.drbin
05120000000000000000000000000001.drbin
05120000000000000000000000000001.tlbin
05160000000000000000000000000000.drbin
06090000000000000000000000000000.drbin
06090000000000000000000000000000.tlbin
07150000000000000000000000000000.drbin
07150000000000000000000000000000.tlbin
07170000000000000000000000000000.drbin
07170000000000000000000000000000.tlbin
07210000000000000000000000000000.drbin
07210000000000000000000000000000.tlbin
08050000000000000000000000003419.drbin
08050000000000000000000000003419.tlbin
40188311faf343488db888ad39496f9a.drbin
40188311faf343488db888ad39496f9a.tlbin
5020170115e016302017012521300000.drbin
5020170115e016302017012521300000.tlbin
"

# ========================================
# Logging Functions
# ========================================
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOGFILE"
    echo "[$level] $*"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { log "DEBUG" "$@"; }

# ========================================
# Checksum Functions (SHA256)
# ========================================
compute_checksum() {
    local file="$1"
    if [ -f "$file" ]; then
        sha256sum "$file" 2>/dev/null | cut -d' ' -f1
    else
        echo "FILE_NOT_FOUND"
    fi
}

save_checksum() {
    local file="$1"
    local checksum="$2"
    local checksum_file="$CHECKSUM_DIR/$(basename "$file").checksum"
    
    mkdir -p "$CHECKSUM_DIR"
    echo "$checksum" > "$checksum_file"
}

get_saved_checksum() {
    local file="$1"
    local checksum_file="$CHECKSUM_DIR/$(basename "$file").checksum"
    
    if [ -f "$checksum_file" ]; then
        cat "$checksum_file"
    else
        echo "NO_SAVED_CHECKSUM"
    fi
}

# ========================================
# Version Management
# ========================================
get_firmware_version() {
    getprop ro.build.fingerprint 2>/dev/null | cut -d'/' -f3-4
}

get_ta_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

save_ta_version() {
    local version="$1"
    local firmware=$(get_firmware_version)
    echo "ta_version=$version" > "$VERSION_FILE"
    echo "firmware=$firmware" >> "$VERSION_FILE"
    echo "update_time=$(date '+%Y-%m-%d %H:%M:%S')" >> "$VERSION_FILE"
}

# ========================================
# TA Validation Functions
# ========================================
validate_ta_file() {
    local ta_file="$1"
    local source_dir="$2"
    local target_dir="$3"
    
    local source_file="$source_dir/$ta_file"
    local target_file="$target_dir/$ta_file"
    
    # Check if source exists
    if [ ! -f "$source_file" ]; then
        log_debug "Source TA not found: $source_file"
        return 1
    fi
    
    # If target doesn't exist, source is newer
    if [ ! -f "$target_file" ]; then
        log_info "Target TA missing: $ta_file - needs update"
        return 0  # Needs update
    fi
    
    # Compare SHA256 checksums
    local source_checksum=$(compute_checksum "$source_file")
    local target_checksum=$(compute_checksum "$target_file")
    
    if [ "$source_checksum" != "$target_checksum" ]; then
        log_info "Checksum mismatch for $ta_file"
        log_debug "  Source: $source_checksum"
        log_debug "  Target: $target_checksum"
        return 0  # Needs update
    fi
    
    return 1  # No update needed
}

validate_critical_tas() {
    log_info "Validating critical TA files..."
    
    local mismatches=0
    local missing=0
    
    for ta in $CRITICAL_TAS; do
        if [ -f "$PERSIST_MC/$ta" ]; then
            if validate_ta_file "$ta" "$PERSIST_MC" "$VENDOR_MC"; then
                log_warn "CRITICAL TA MISMATCH: $ta"
                mismatches=$((mismatches + 1))
            else
                log_debug "Critical TA OK: $ta"
            fi
        else
            # No persist version, check if vendor has it
            if [ ! -f "$VENDOR_MC/$ta" ]; then
                log_error "CRITICAL TA MISSING: $ta"
                missing=$((missing + 1))
            fi
        fi
    done
    
    if [ $mismatches -gt 0 ] || [ $missing -gt 0 ]; then
        log_warn "TA validation result: $mismatches mismatches, $missing missing"
        return 1
    fi
    
    log_info "All critical TAs validated successfully"
    return 0
}

# ========================================
# Backup Functions
# ========================================
backup_vendor_tas() {
    log_info "Creating backup of vendor TAs..."
    
    mkdir -p "$BACKUP_DIR"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_subdir="$BACKUP_DIR/backup_$timestamp"
    
    mkdir -p "$backup_subdir"
    
    # Copy all TA files
    local count=0
    for ta in "$VENDOR_MC"/*.drbin "$VENDOR_MC"/*.tlbin "$VENDOR_MC"/*.tabin 2>/dev/null; do
        if [ -f "$ta" ]; then
            cp "$ta" "$backup_subdir/"
            count=$((count + 1))
        fi
    done
    
    # Save checksums
    for ta in "$VENDOR_MC"/*.drbin "$VENDOR_MC"/*.tlbin 2>/dev/null; do
        if [ -f "$ta" ]; then
            local checksum=$(compute_checksum "$ta")
            save_checksum "$ta" "$checksum"
        fi
    done
    
    # Save version info
    get_firmware_version > "$backup_subdir/.firmware_version"
    date '+%Y-%m-%d %H:%M:%S' > "$backup_subdir/.backup_time"
    
    log_info "Backup created: $backup_subdir ($count files)"
    
    # Clean old backups (keep last 5)
    local backup_count=$(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)
    if [ $backup_count -gt 5 ]; then
        local to_delete=$((backup_count - 5))
        ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | head -$to_delete | while read old_backup; do
            log_info "Removing old backup: $old_backup"
            rm -rf "$old_backup"
        done
    fi
    
    return 0
}

# ========================================
# TA Sync Functions
# ========================================
sync_single_ta() {
    local ta="$1"
    local source="$PERSIST_MC/$ta"
    local target="$VENDOR_MC/$ta"
    
    if [ ! -f "$source" ]; then
        log_debug "Source not found for sync: $ta"
        return 1
    fi
    
    # Remount vendor as RW
    mount -o remount,rw /vendor 2>/dev/null
    
    # Copy TA file
    if cp "$source" "$target" 2>/dev/null; then
        chmod 644 "$target" 2>/dev/null
        chown root:root "$target" 2>/dev/null
        log_info "Synced: $ta"
        
        # Save checksum
        local checksum=$(compute_checksum "$target")
        save_checksum "$target" "$checksum"
        
        return 0
    else
        log_error "Failed to sync: $ta"
        return 1
    fi
}

sync_tas_from_persist() {
    log_info "Starting TA sync from persist to vendor..."
    
    # Check if persist mcRegistry exists
    if [ ! -d "$PERSIST_MC" ]; then
        log_warn "Persist mcRegistry not found - nothing to sync"
        return 0
    fi
    
    local synced=0
    local failed=0
    local skipped=0
    
    for ta in $ALL_TA_FILES; do
        if [ -f "$PERSIST_MC/$ta" ]; then
            if validate_ta_file "$ta" "$PERSIST_MC" "$VENDOR_MC"; then
                if sync_single_ta "$ta"; then
                    synced=$((synced + 1))
                else
                    failed=$((failed + 1))
                fi
            else
                skipped=$((skipped + 1))
            fi
        fi
    done
    
    # Remount vendor as RO
    mount -o remount,ro /vendor 2>/dev/null
    
    log_info "TA sync complete: $synced synced, $failed failed, $skipped skipped"
    
    if [ $synced -gt 0 ]; then
        # Save new version
        save_ta_version "synced_from_persist"
    fi
    
    return $failed
}

# ========================================
# Auto-Update Logic
# ========================================
check_and_update_tas() {
    log_info "========================================"
    log_info "TA Auto-Update Check - v$SCRIPT_VERSION"
    log_info "Device: $DEVICE ($PLATFORM)"
    log_info "========================================"
    
    # Get current versions
    local current_firmware=$(get_firmware_version)
    local saved_firmware=""
    
    if [ -f "$VERSION_FILE" ]; then
        saved_firmware=$(grep "^firmware=" "$VERSION_FILE" 2>/dev/null | cut -d'=' -f2)
    fi
    
    log_info "Current firmware: $current_firmware"
    log_info "Saved firmware: $saved_firmware"
    
    # Check if firmware changed
    local firmware_changed=0
    if [ -n "$saved_firmware" ] && [ "$saved_firmware" != "$current_firmware" ]; then
        log_info "Firmware change detected!"
        firmware_changed=1
    fi
    
    # Validate critical TAs
    if ! validate_critical_tas; then
        log_warn "Critical TA validation failed - sync required"
        
        # Backup before update
        backup_vendor_tas
        
        # Sync from persist
        sync_tas_from_persist
        
        # Set property for recovery to know
        setprop ro.vendor.ta.updated 1
        setprop ro.vendor.ta.needs_reboot 1
        
        return 1
    fi
    
    # Check for any non-critical TA updates
    if [ $firmware_changed -eq 1 ] || [ -d "$PERSIST_MC" ]; then
        local persist_count=$(ls "$PERSIST_MC"/*.tlbin "$PERSIST_MC"/*.drbin 2>/dev/null | wc -l)
        
        if [ $persist_count -gt 0 ]; then
            log_info "Checking for TA updates from persist ($persist_count files)..."
            
            local needs_update=0
            for ta in $ALL_TA_FILES; do
                if validate_ta_file "$ta" "$PERSIST_MC" "$VENDOR_MC"; then
                    needs_update=1
                    break
                fi
            done
            
            if [ $needs_update -eq 1 ]; then
                log_info "Non-critical TA updates available"
                backup_vendor_tas
                sync_tas_from_persist
            fi
        fi
    fi
    
    # Update version file
    save_ta_version "validated"
    
    log_info "TA validation complete - no updates required"
    setprop ro.vendor.ta.updated 0
    setprop ro.vendor.ta.valid 1
    
    return 0
}

# ========================================
# Rollback Function
# ========================================
rollback_tas() {
    log_info "Attempting TA rollback..."
    
    # Find latest backup
    local latest_backup=$(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | tail -1)
    
    if [ -z "$latest_backup" ] || [ ! -d "$latest_backup" ]; then
        log_error "No backup found for rollback"
        return 1
    fi
    
    log_info "Using backup: $latest_backup"
    
    mount -o remount,rw /vendor 2>/dev/null
    
    local count=0
    for ta in "$latest_backup"/*.drbin "$latest_backup"/*.tlbin "$latest_backup"/*.tabin 2>/dev/null; do
        if [ -f "$ta" ]; then
            local filename=$(basename "$ta")
            cp "$ta" "$VENDOR_MC/$filename"
            count=$((count + 1))
        fi
    done
    
    mount -o remount,ro /vendor 2>/dev/null
    
    log_info "Rollback complete: $count files restored"
    return 0
}

# ========================================
# Status Report
# ========================================
show_status() {
    echo "========================================"
    echo "TA Auto-Update Status Report"
    echo "========================================"
    echo ""
    echo "Device: $DEVICE ($PLATFORM)"
    echo "Script Version: $SCRIPT_VERSION"
    echo ""
    echo "Paths:"
    echo "  Vendor mcRegistry: $VENDOR_MC"
    echo "  Persist mcRegistry: $PERSIST_MC"
    echo "  Backup Directory: $BACKUP_DIR"
    echo ""
    echo "Version Info:"
    echo "  Firmware: $(get_firmware_version)"
    echo "  TA Version: $(get_ta_version)"
    echo ""
    echo "File Counts:"
    echo "  Vendor TAs: $(ls "$VENDOR_MC"/*.drbin "$VENDOR_MC"/*.tlbin 2>/dev/null | wc -l)"
    echo "  Persist TAs: $(ls "$PERSIST_MC"/*.drbin "$PERSIST_MC"/*.tlbin 2>/dev/null | wc -l)"
    echo "  Backups: $(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)"
    echo ""
    echo "Critical TA Status:"
    
    for ta in $CRITICAL_TAS; do
        local vendor_exists="NO"
        local persist_exists="NO"
        local checksum_match="N/A"
        
        [ -f "$VENDOR_MC/$ta" ] && vendor_exists="YES"
        [ -f "$PERSIST_MC/$ta" ] && persist_exists="YES"
        
        if [ "$vendor_exists" = "YES" ] && [ "$persist_exists" = "YES" ]; then
            local v_checksum=$(compute_checksum "$VENDOR_MC/$ta")
            local p_checksum=$(compute_checksum "$PERSIST_MC/$ta")
            [ "$v_checksum" = "$p_checksum" ] && checksum_match="YES" || checksum_match="NO"
        fi
        
        echo "  $ta"
        echo "    Vendor: $vendor_exists | Persist: $persist_exists | Match: $checksum_match"
    done
    
    echo ""
    echo "Properties:"
    echo "  ro.vendor.ta.updated: $(getprop ro.vendor.ta.updated)"
    echo "  ro.vendor.ta.valid: $(getprop ro.vendor.ta.valid)"
    echo "  ro.vendor.ta.needs_reboot: $(getprop ro.vendor.ta.needs_reboot)"
    echo ""
    echo "========================================"
}

# ========================================
# Main Entry Point
# ========================================
case "$1" in
    check)
        check_and_update_tas
        ;;
    sync)
        backup_vendor_tas
        sync_tas_from_persist
        ;;
    validate)
        validate_critical_tas
        ;;
    backup)
        backup_vendor_tas
        ;;
    rollback)
        rollback_tas
        ;;
    status)
        show_status
        ;;
    *)
        # Default: run check and update
        check_and_update_tas
        ;;
esac

exit $?
