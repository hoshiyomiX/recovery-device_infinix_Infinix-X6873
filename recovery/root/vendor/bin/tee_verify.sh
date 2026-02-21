#!/vendor/bin/sh
#
# TEE Verification and Recovery Script for Infinix X6873
# This script handles Trustonic TEE state verification and fallback
#
# Part of FIX for:
# - Trustonic TEE Binding
# - TA Version Mismatch
# - RPMB Critical
#

LOGFILE="/tmp/tee_verify.log"
MC_REGISTRY="/vendor/app/mcRegistry"
PERSIST_MC="/mnt/vendor/persist/mcRegistry"
RPMB_PATH="/mnt/vendor/persist/rpmb"

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
    
    if ! mountpoint -q /metadata; then
        log "ERROR: metadata partition not mounted!"
        partitions_ok=0
    else
        log "OK: metadata partition mounted"
    fi
    
    return $partitions_ok
}

# Check TEE hardware presence
check_tee_hardware() {
    log "Checking TEE hardware..."
    
    # Check for TEE device nodes
    if [ -e /dev/tci ]; then
        log "OK: /dev/tci found"
    else
        log "WARNING: /dev/tci not found"
    fi
    
    if [ -e /dev/mobicore ]; then
        log "OK: /dev/mobicore found"
    else
        log "WARNING: /dev/mobicore not found"
    fi
    
    # Check for Trustonic TEE driver
    if lsmod | grep -q "mcDrvModule"; then
        log "OK: mcDrvModule kernel module loaded"
    else
        log "WARNING: mcDrvModule not loaded, attempting to load..."
        insmod /vendor/lib/modules/mcDrvModule-ffa.ko 2>/dev/null
    fi
    
    return 0
}

# Verify TA files integrity
check_ta_files() {
    log "Checking Trusted Applications..."
    
    local ta_count=0
    local ta_required="
06090000000000000000000000000000.drbin
07210000000000000000000000000000.drbin
08050000000000000000000000003419.drbin
06090000000000000000000000000000.tlbin
07210000000000000000000000000000.tlbin
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

# Check RPMB status
check_rpmb() {
    log "Checking RPMB status..."
    
    # Check RPMB directory
    if [ -d "$RPMB_PATH" ]; then
        log "OK: RPMB directory exists"
        
        # Check for RPMB data
        if ls "$RPMB_PATH"/* 2>/dev/null; then
            log "OK: RPMB data files present"
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
    
    # Check for RPMB backup
    if [ -d "/mnt/vendor/persist/rpmb_backup" ]; then
        log "OK: RPMB backup directory exists"
    else
        log "Creating RPMB backup directory..."
        mkdir -p /mnt/vendor/persist/rpmb_backup
        chmod 700 /mnt/vendor/persist/rpmb_backup
    fi
    
    return 0
}

# Backup RPMB data
backup_rpmb() {
    log "Creating RPMB backup..."
    
    if [ -d "$RPMB_PATH" ] && ls "$RPMB_PATH"/* 2>/dev/null; then
        cp -r "$RPMB_PATH"/* /mnt/vendor/persist/rpmb_backup/ 2>/dev/null
        log "RPMB backup created successfully"
        return 0
    else
        log "No RPMB data to backup"
        return 1
    fi
}

# Check firmware version compatibility
check_firmware_version() {
    log "Checking firmware version..."
    
    local firmware_ver=$(getprop ro.build.fingerprint)
    local vendor_ver=$(getprop ro.vendor.build.fingerprint)
    
    log "System firmware: $firmware_ver"
    log "Vendor firmware: $vendor_ver"
    
    # Get TA version from firmware
    if [ -f "/vendor/app/mcRegistry/.ta_version" ]; then
        local ta_ver=$(cat /vendor/app/mcRegistry/.ta_version)
        log "TA version: $ta_ver"
    else
        log "WARNING: TA version file not found"
    fi
    
    return 0
}

# Verify TEE service status
check_tee_services() {
    log "Checking TEE service status..."
    
    # Check mobicore daemon
    if pidof mcDriverDaemon > /dev/null; then
        log "OK: mcDriverDaemon running"
    else
        log "WARNING: mcDriverDaemon not running"
    fi
    
    # Check keymint service
    if getprop | grep -q "init.svc.vendor.keymint-trustonic=running"; then
        log "OK: Keymint service running"
    else
        log "WARNING: Keymint service not running"
    fi
    
    # Check gatekeeper
    if getprop | grep -q "init.svc.vendor.gatekeeper-trustonic=running"; then
        log "OK: Gatekeeper service running"
    else
        log "WARNING: Gatekeeper service not running"
    fi
    
    return 0
}

# Attempt recovery
attempt_recovery() {
    log "Attempting TEE recovery..."
    
    # Stop all TEE services
    stop mobicore
    stop vendor.keymint-trustonic
    stop vendor.gatekeeper-trustonic
    stop vendor.trustonic-tee
    sleep 2
    
    # Clear TEE caches
    rm -rf /tmp/mcRegistry 2>/dev/null
    mkdir -p /tmp/mcRegistry
    
    # Restart services in order
    start vendor.trustonic-tee
    sleep 3
    start mobicore
    sleep 2
    start vendor.keymint-trustonic
    sleep 1
    start vendor.gatekeeper-trustonic
    
    log "TEE recovery attempt completed"
}

# Main verification routine
main() {
    log "========================================"
    log "TEE Verification Script v1.0"
    log "Infinix X6873 (GT 30 Pro)"
    log "========================================"
    
    local errors=0
    
    check_partitions || errors=$((errors + 1))
    check_tee_hardware || errors=$((errors + 1))
    check_ta_files || errors=$((errors + 1))
    check_rpmb || errors=$((errors + 1))
    check_firmware_version
    check_tee_services
    
    if [ $errors -gt 0 ]; then
        log "WARNING: $errors error(s) detected"
        
        # Attempt recovery if critical errors
        if [ $errors -gt 2 ]; then
            attempt_recovery
        fi
    else
        log "All checks passed!"
        setprop ro.vendor.trustonic.ready true
    fi
    
    # Create RPMB backup
    backup_rpmb
    
    log "========================================"
    log "TEE Verification Complete"
    log "========================================"
    
    return $errors
}

# Run main
main
exit $?
