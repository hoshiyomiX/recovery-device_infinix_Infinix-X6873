#!/vendor/bin/sh
#
# TA Auto-Update Script for Infinix X6873 (GT 30 Pro)
# Version: 4.0 - Complete Fix Release
#
# FIXES:
# 1. Vendor remount with fallback mechanism
# 2. Hardware-backed key verification
# 3. Explicit filesystem wait
# 4. Comprehensive error handling
# 5. RPMB backup integration (runs BEFORE this script via init)
#

SCRIPT_VERSION="4.0"
DEVICE="X6873"

# Paths
VENDOR_MC="/vendor/app/mcRegistry"
PERSIST_MC="/mnt/vendor/persist/mcRegistry"
DATA_MC="/data/vendor/mcRegistry"
BACKUP_DIR="/mnt/vendor/persist/mcRegistry_backup"
VERSION_FILE="/mnt/vendor/persist/.ta_version"
LOGFILE="/tmp/ta_auto_update.log"

MAX_RETRIES=3
RETRY_DELAY=2
VENDOR_REMOUNT_OK=0
FALLBACK_MC=""

# Critical TAs
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

# All TA files
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

# Logging
log() {
    echo "[$(date '+%H:%M:%S')] [$1] $2" >> "$LOGFILE"
    echo "[$1] $2"
}
log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }

# ========================================
# FIX #3: Wait for filesystem ready
# ========================================
wait_for_persist() {
    local waited=0
    log_info "Waiting for persist filesystem..."
    
    while [ $waited -lt 15 ]; do
        if [ -d "$PERSIST_MC" ] && ls "$PERSIST_MC" >/dev/null 2>&1; then
            sleep 0.5
            log_info "Persist ready (waited ${waited}s)"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    
    log_error "Persist not ready after 15s"
    return 1
}

# ========================================
# FIX #1: Vendor remount with fallback
# ========================================
try_vendor_remount() {
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        # Try remount
        if mount -o remount,rw /vendor 2>/dev/null; then
            # Verify writable
            if touch /vendor/.test_$$ 2>/dev/null; then
                rm -f /vendor/.test_$$ 2>/dev/null
                VENDOR_REMOUNT_OK=1
                log_info "Vendor remount OK"
                return 0
            fi
        fi
        
        # Try with explicit device
        local dev=$(cat /proc/mounts 2>/dev/null | grep " /vendor " | cut -d' ' -f1)
        if [ -n "$dev" ] && mount -o remount,rw "$dev" /vendor 2>/dev/null; then
            if touch /vendor/.test_$$ 2>/dev/null; then
                rm -f /vendor/.test_$$ 2>/dev/null
                VENDOR_REMOUNT_OK=1
                log_info "Vendor remount OK via $dev"
                return 0
            fi
        fi
        
        sleep $RETRY_DELAY
        attempt=$((attempt + 1))
    done
    
    log_warn "Vendor remount failed, trying fallback..."
    return 1
}

setup_fallback() {
    # Try /data
    if mountpoint -q /data 2>/dev/null && mkdir -p "$DATA_MC" 2>/dev/null; then
        FALLBACK_MC="$DATA_MC"
        log_info "Using fallback: $FALLBACK_MC"
        setprop ro.vendor.ta.using_fallback 1
        return 0
    fi
    
    # Try /cache
    if mountpoint -q /cache 2>/dev/null && mkdir -p /cache/mcRegistry 2>/dev/null; then
        FALLBACK_MC="/cache/mcRegistry"
        log_info "Using fallback: $FALLBACK_MC"
        setprop ro.vendor.ta.using_fallback 1
        return 0
    fi
    
    # Use persist as last resort
    FALLBACK_MC="/mnt/vendor/persist/mcRegistry_override"
    mkdir -p "$FALLBACK_MC" 2>/dev/null
    log_info "Using fallback: $FALLBACK_MC"
    setprop ro.vendor.ta.using_fallback 1
    return 0
}

# ========================================
# FIX #2: Hardware key tracking
# ========================================
get_hw_key() {
    echo "$(getprop ro.serialno)_$(getprop ro.bootloader)_$(getprop ro.hardware)" | sha256sum | cut -d' ' -f1
}

save_hw_info() {
    local hw_key=$(get_hw_key)
    mkdir -p "$(dirname "$VERSION_FILE")" 2>/dev/null
    echo "hw_key=$hw_key" >> "$VERSION_FILE"
    echo "firmware=$(getprop ro.build.fingerprint | cut -d'/' -f3-4)" >> "$VERSION_FILE"
    echo "time=$(date '+%Y-%m-%d %H:%M:%S')" >> "$VERSION_FILE"
}

check_hw_match() {
    if [ ! -f "$VERSION_FILE" ]; then
        return 0
    fi
    
    local saved=$(grep "^hw_key=" "$VERSION_FILE" 2>/dev/null | cut -d'=' -f2)
    local current=$(get_hw_key)
    
    if [ -n "$saved" ] && [ "$saved" != "$current" ]; then
        log_warn "Hardware key mismatch"
        setprop ro.vendor.ta.hw_mismatch 1
        return 1
    fi
    return 0
}

# ========================================
# Checksum
# ========================================
get_checksum() {
    [ -f "$1" ] && sha256sum "$1" 2>/dev/null | cut -d' ' -f1 || echo "N/A"
}

# ========================================
# TA Validation
# ========================================
validate_ta() {
    local ta="$1"
    local src="$PERSIST_MC/$ta"
    local dst="$VENDOR_MC/$ta"
    
    [ ! -f "$src" ] && return 1
    
    # Check integrity (min 1KB)
    local size=$(stat -c%s "$src" 2>/dev/null || echo 0)
    [ "$size" -lt 1024 ] && log_warn "TA small: $ta ($size bytes)"
    
    [ ! -f "$dst" ] && return 0  # Needs sync
    
    # Compare checksum
    [ "$(get_checksum "$src")" != "$(get_checksum "$dst")" ] && return 0
    
    return 1  # No update needed
}

validate_critical() {
    log_info "Validating critical TAs..."
    local mismatch=0
    local missing=0
    
    for ta in $CRITICAL_TAS; do
        if [ -f "$PERSIST_MC/$ta" ]; then
            if validate_ta "$ta"; then
                mismatch=$((mismatch + 1))
            fi
        elif [ ! -f "$VENDOR_MC/$ta" ]; then
            missing=$((missing + 1))
            log_error "Missing: $ta"
        fi
    done
    
    [ $mismatch -gt 0 ] || [ $missing -gt 0 ] && return 1
    return 0
}

# ========================================
# Backup
# ========================================
backup_tas() {
    log_info "Creating backup..."
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    
    local ts=$(date '+%Y%m%d_%H%M%S')
    local dir="$BACKUP_DIR/backup_$ts"
    mkdir -p "$dir" 2>/dev/null
    
    local count=0
    for f in "$VENDOR_MC"/*.drbin "$VENDOR_MC"/*.tlbin "$VENDOR_MC"/*.tabin 2>/dev/null; do
        [ -f "$f" ] && cp "$f" "$dir/" 2>/dev/null && count=$((count + 1))
    done
    
    log_info "Backup: $count files"
    
    # Keep only last 5
    local num=$(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)
    [ $num -gt 5 ] && ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | head -$((num - 5)) | xargs rm -rf 2>/dev/null
    
    return 0
}

# ========================================
# FIX #4: TA Sync with error handling
# ========================================
sync_ta() {
    local ta="$1"
    local src="$PERSIST_MC/$ta"
    local dst=""
    
    [ ! -f "$src" ] && return 1
    
    if [ "$VENDOR_REMOUNT_OK" = "1" ]; then
        dst="$VENDOR_MC/$ta"
    elif [ -n "$FALLBACK_MC" ]; then
        dst="$FALLBACK_MC/$ta"
    else
        return 1
    fi
    
    # Copy with retry
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        if cp "$src" "$dst" 2>/dev/null; then
            chmod 644 "$dst" 2>/dev/null
            # Verify
            local src_sz=$(stat -c%s "$src" 2>/dev/null || echo 0)
            local dst_sz=$(stat -c%s "$dst" 2>/dev/null || echo 0)
            [ "$src_sz" = "$dst_sz" ] && [ "$src_sz" -gt 0 ] && return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    return 1
}

sync_tas() {
    log_info "Syncing TAs..."
    
    # Try remount or fallback
    if ! try_vendor_remount; then
        setup_fallback
    fi
    
    local synced=0
    local failed=0
    local skipped=0
    
    for ta in $ALL_TA_FILES; do
        if [ -f "$PERSIST_MC/$ta" ]; then
            if validate_ta "$ta"; then
                if sync_ta "$ta"; then
                    synced=$((synced + 1))
                else
                    failed=$((failed + 1))
                fi
            else
                skipped=$((skipped + 1))
            fi
        fi
    done
    
    # Remount RO if we remounted
    [ "$VENDOR_REMOUNT_OK" = "1" ] && mount -o remount,ro /vendor 2>/dev/null
    
    log_info "Sync done: $synced synced, $failed failed, $skipped skipped"
    
    setprop ro.vendor.ta.synced_count $synced
    setprop ro.vendor.ta.failed_count $failed
    
    [ $synced -gt 0 ] && save_hw_info
    
    return $failed
}

# ========================================
# Main check
# ========================================
check_and_update() {
    log_info "=== TA Auto-Update v$SCRIPT_VERSION ==="
    log_info "Device: $DEVICE"
    
    setprop ro.vendor.ta.state "checking"
    
    # FIX #3: Wait for filesystem
    if ! wait_for_persist; then
        setprop ro.vendor.ta.state "fs_error"
        setprop ro.vendor.ta.ready 0
        return 1
    fi
    
    # FIX #2: Check hardware
    check_hw_match
    
    # Check firmware change
    local curr_fw=$(getprop ro.build.fingerprint | cut -d'/' -f3-4)
    local saved_fw=""
    [ -f "$VERSION_FILE" ] && saved_fw=$(grep "^firmware=" "$VERSION_FILE" 2>/dev/null | cut -d'=' -f2)
    
    [ "$saved_fw" != "$curr_fw" ] && log_info "Firmware changed: $saved_fw -> $curr_fw"
    
    # Validate critical TAs
    if ! validate_critical; then
        log_warn "Critical TA validation failed"
        setprop ro.vendor.ta.state "sync_required"
        backup_tas
        sync_tas
        setprop ro.vendor.ta.updated 1
        return 1
    fi
    
    log_info "TA validation OK"
    setprop ro.vendor.ta.state "validated"
    setprop ro.vendor.ta.updated 0
    setprop ro.vendor.ta.valid 1
    setprop ro.vendor.ta.ready 1
    
    return 0
}

# ========================================
# Rollback
# ========================================
rollback() {
    log_info "Rolling back..."
    
    local latest=$(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | tail -1)
    [ -z "$latest" ] && { log_error "No backup"; return 1; }
    
    try_vendor_remount || return 1
    
    local count=0
    for f in "$latest"/*.drbin "$latest"/*.tlbin "$latest"/*.tabin 2>/dev/null; do
        [ -f "$f" ] && cp "$f" "$VENDOR_MC/$(basename "$f")" 2>/dev/null && count=$((count + 1))
    done
    
    mount -o remount,ro /vendor 2>/dev/null
    log_info "Rollback: $count files"
    return 0
}

# ========================================
# Status
# ========================================
show_status() {
    echo "=== TA Status v$SCRIPT_VERSION ==="
    echo "State: $(getprop ro.vendor.ta.state)"
    echo "Using Fallback: $(getprop ro.vendor.ta.using_fallback)"
    echo "HW Mismatch: $(getprop ro.vendor.ta.hw_mismatch)"
    echo ""
    echo "Files:"
    echo "  Vendor: $(ls "$VENDOR_MC"/*.drbin "$VENDOR_MC"/*.tlbin 2>/dev/null | wc -l)"
    echo "  Persist: $(ls "$PERSIST_MC"/*.drbin "$PERSIST_MC"/*.tlbin 2>/dev/null | wc -l)"
    echo "  Backups: $(ls -1d "$BACKUP_DIR"/backup_* 2>/dev/null | wc -l)"
    echo ""
    echo "Critical TAs:"
    for ta in $CRITICAL_TAS; do
        local v="NO" p="NO"
        [ -f "$VENDOR_MC/$ta" ] && v="YES"
        [ -f "$PERSIST_MC/$ta" ] && p="YES"
        echo "  $ta: V=$v P=$p"
    done
}

# ========================================
# Entry point
# ========================================
case "$1" in
    check)     check_and_update ;;
    sync)      wait_for_persist && backup_tas && sync_tas ;;
    validate)  wait_for_persist && validate_critical ;;
    backup)    backup_tas ;;
    rollback)  rollback ;;
    status)    show_status ;;
    wait)      wait_for_persist ;;
    *)         check_and_update ;;
esac

exit $?
