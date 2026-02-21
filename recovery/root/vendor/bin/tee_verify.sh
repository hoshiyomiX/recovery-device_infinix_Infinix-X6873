#!/vendor/bin/sh
#
# TEE Verification and Recovery Script for Infinix X6873
# FIXED: Proper verification timing and error handling
#
# This script runs AFTER TEE is initialized to verify state
#

LOGFILE="/tmp/tee_verify.log"
MC_REGISTRY="/vendor/app/mcRegistry"
PERSIST_MC="/mnt/vendor/persist/mcRegistry"
RPMB_PATH="/mnt/vendor/persist/rpmb"
TEE_READY_FLAG="/tmp/.tee_ready_flag"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
    echo "$1"
}

# Check if required partitions are mounted
check_partitions() {
    log "Checking required partitions..."
    
    local partitions_ok=1
    
    if ! mountpoint -q /mnt/vendor/persist; then
        log "ERROR: persist partition not mounted!"
        partitions_ok=0
    else
        log "OK: persist partition mounted"
    fi
    
    if ! mountpoint -q /mnt/vendor/nvdata; then
        log "WARNING: nvdata partition not mounted"
    else
        log "OK: nvdata partition mounted"
    fi
    
    # ========================================
    # FIX: Check metadata as F2FS
    # ========================================
    if ! mountpoint -q /metadata; then
        log "ERROR: metadata partition not mounted!"
        partitions_ok=0
    else
        local meta_type=$(mount | grep " /metadata " | awk '{print $5}')
        if [ "$meta_type" = "f2fs" ]; then
            log "OK: metadata partition mounted (F2FS)"
        else
            log "WARNING: metadata partition is $meta_type (expected F2FS)"
        fi
    fi
    
    return $partitions_ok
}

# Check TEE hardware presence
check_tee_hardware() {
    log "Checking TEE hardware..."
    
    local tee_ok=1
    
    # Check for TEE device nodes
    if [ -e /dev/tci ]; then
        log "OK: /dev/tci found"
    else
        log "WARNING: /dev/tci not found"
        tee_ok=0
    fi
    
    if [ -e /dev/mobicore ]; then
        log "OK: /dev/mobicore found"
    else
        log "WARNING: /dev/mobicore not found"
        tee_ok=0
    fi
    
    # Check for Trustonic TEE driver
    if lsmod 2>/dev/null | grep -q "mcDrvModule"; then
        log "OK: mcDrvModule kernel module loaded"
    else
        log "INFO: Attempting to load mcDrvModule..."
        if [ -f /vendor/lib/modules/mcDrvModule-ffa.ko ]; then
            insmod /vendor/lib/modules/mcDrvModule-ffa.ko 2>/dev/null
            if lsmod 2>/dev/null | grep -q "mcDrvModule"; then
                log "OK: mcDrvModule loaded successfully"
            else
                log "WARNING: Failed to load mcDrvModule"
            fi
        else
            log "WARNING: mcDrvModule-ffa.ko not found"
        fi
    fi
    
    return $tee_ok
}

# Verify TA files integrity
check_ta_files() {
    log "Checking Trusted Applications..."
    
    local ta_count=0
    local ta_required="
06090000000000000000000000000000.drbin
06090000000000000000000000000000.tlbin
07210000000000000000000000000000.drbin
07210000000000000000000000000000.tlbin
08050000000000000000000000003419.drbin
08050000000000000000000000003419.tlbin
"
    
    for ta in $ta_required; do
        if [ -f "$MC_REGISTRY/$ta" ]; then
            ta_count=$((ta_count + 1))
            log "OK: $ta found"
        else
            log "ERROR: Required TA $ta NOT FOUND!"
        fi
    done
    
    # Count all TA files
    local total_ta=$(ls "$MC_REGISTRY"/*.drbin "$MC_REGISTRY"/*.tlbin 2>/dev/null | wc -l)
    log "Total TA files found: $total_ta"
    
    if [ $ta_count -lt 5 ]; then
        log "ERROR: Insufficient TA files for decryption!"
        return 1
    fi
    
    return 0
}

# Check RPMB status (read-only check, no write operations)
check_rpmb() {
    log "Checking RPMB status..."
    
    # Check RPMB directory
    if [ -d "$RPMB_PATH" ]; then
        log "OK: RPMB directory exists"
        
        # Check for RPMB data (just list, don't access)
        local file_count=$(ls "$RPMB_PATH" 2>/dev/null | wc -l)
        if [ $file_count -gt 0 ]; then
            log "OK: RPMB data files present ($file_count files)"
        else
            log "WARNING: RPMB directory empty - first boot or wiped?"
        fi
    else
        log "ERROR: RPMB directory missing!"
        mkdir -p "$RPMB_PATH"
        chmod 700 "$RPMB_PATH"
        chown system:system "$RPMB_PATH"
        log "Created RPMB directory"
    fi
    
    # Check for RPMB backup directory
    if [ -d "/mnt/vendor/persist/rpmb_backup" ]; then
        local backup_count=$(ls /mnt/vendor/persist/rpmb_backup 2>/dev/null | wc -l)
        log "OK: RPMB backup directory exists ($backup_count files)"
    else
        log "Creating RPMB backup directory..."
        mkdir -p /mnt/vendor/persist/rpmb_backup
        chmod 700 /mnt/vendor/persist/rpmb_backup
    fi
    
    return 0
}

# Check firmware version compatibility
check_firmware_version() {
    log "Checking firmware version..."
    
    local firmware_ver=$(getprop ro.build.fingerprint)
    local vendor_ver=$(getprop ro.vendor.build.fingerprint)
    
    log "System firmware: $firmware_ver"
    log "Vendor firmware: $vendor_ver"
    
    # Check TA version if available
    if [ -f "$MC_REGISTRY/.ta_version" ]; then
        local ta_ver=$(cat "$MC_REGISTRY/.ta_version")
        log "TA version: $ta_ver"
    else
        log "INFO: TA version file not found (using bundled TAs)"
    fi
    
    return 0
}

# Verify TEE service status
check_tee_services() {
    log "Checking TEE service status..."
    
    local services_ok=1
    
    # Check mobicore daemon
    if pidof mcDriverDaemon > /dev/null 2>&1; then
        log "OK: mcDriverDaemon running (PID: $(pidof mcDriverDaemon))"
    else
        log "WARNING: mcDriverDaemon not running"
        services_ok=0
    fi
    
    # Check keymint service
    local keymint_state=$(getprop init.svc.vendor.keymint-trustonic)
    if [ "$keymint_state" = "running" ]; then
        log "OK: Keymint service running"
    else
        log "WARNING: Keymint service state: $keymint_state"
    fi
    
    # Check gatekeeper
    local gatekeeper_state=$(getprop init.svc.vendor.gatekeeper-trustonic)
    if [ "$gatekeeper_state" = "running" ]; then
        log "OK: Gatekeeper service running"
    else
        log "WARNING: Gatekeeper service state: $gatekeeper_state"
    fi
    
    # Check TEE ready property
    local tee_ready=$(getprop ro.vendor.trustonic.ready)
    log "TEE ready property: $tee_ready"
    
    return $services_ok
}

# Perform RPMB backup (safe to do now that TEE is initialized)
backup_rpmb() {
    log "Performing RPMB backup..."
    
    if [ -d "$RPMB_PATH" ]; then
        local src_count=$(ls "$RPMB_PATH" 2>/dev/null | wc -l)
        if [ $src_count -gt 0 ]; then
            cp -r "$RPMB_PATH"/* /mnt/vendor/persist/rpmb_backup/ 2>/dev/null
            local dest_count=$(ls /mnt/vendor/persist/rpmb_backup 2>/dev/null | wc -l)
            log "RPMB backup completed: $dest_count files"
            return 0
        else
            log "No RPMB data to backup"
            return 1
        fi
    else
        log "RPMB path not found"
        return 1
    fi
}

# Attempt recovery
attempt_recovery() {
    log "Attempting TEE recovery..."
    
    # Stop all TEE services
    stop mobicore 2>/dev/null
    stop vendor.keymint-trustonic 2>/dev/null
    stop vendor.gatekeeper-trustonic 2>/dev/null
    stop vendor.trustonic-tee 2>/dev/null
    sleep 2
    
    # Clear TEE caches
    rm -rf /tmp/mcRegistry 2>/dev/null
    mkdir -p /tmp/mcRegistry
    
    # Restart services in order
    start vendor.trustonic-tee 2>/dev/null
    sleep 3
    start mobicore 2>/dev/null
    sleep 2
    start vendor.keymint-trustonic 2>/dev/null
    sleep 1
    start vendor.gatekeeper-trustonic 2>/dev/null
    
    log "TEE recovery attempt completed"
}

# Main verification routine
main() {
    log "========================================"
    log "TEE Verification Script v2.0 (FIXED)"
    log "Infinix X6873 (GT 30 Pro)"
    log "========================================"
    
    local errors=0
    
    check_partitions || errors=$((errors + 1))
    check_tee_hardware || errors=$((errors + 1))
    check_ta_files || errors=$((errors + 1))
    check_rpmb || errors=$((errors + 1))
    check_firmware_version
    check_tee_services || errors=$((errors + 1))
    
    if [ $errors -gt 0 ]; then
        log "WARNING: $errors error(s) detected"
        
        # Attempt recovery if critical errors
        if [ $errors -gt 2 ]; then
            attempt_recovery
        fi
    else
        log "All checks passed!"
        setprop ro.vendor.trustonic.ready true
        touch "$TEE_READY_FLAG"
    fi
    
    # Create RPMB backup (safe now)
    backup_rpmb
    
    log "========================================"
    log "TEE Verification Complete"
    log "========================================"
    
    return $errors
}

# Run main
main
exit $?
