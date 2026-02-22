#!/vendor/bin/sh
#
# TEE Service Health Check for Infinix X6873 (GT 30 Pro)
# Version: 2.0 - Improved with Timeout and Fallback
#

LOGFILE="/tmp/tee_health_check.log"
MAX_WAIT=30

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"
    echo "$1"
}

# Check if mobicore is truly ready
check_mobicore_ready() {
    log "Checking mobicore readiness..."
    
    local waited=0
    while [ $waited -lt $MAX_WAIT ]; do
        # Check if process is running
        if ! pgrep -f "mcDriverDaemon" >/dev/null 2>&1; then
            log "Mobicore process not running (waited ${waited}s)"
            sleep 1
            waited=$((waited + 1))
            continue
        fi
        
        # Check if TEE device is accessible
        if [ -e "/dev/mobicore" ] || [ -S "/dev/mobicore" ]; then
            # Additional check: try to verify TEE is responding
            if check_keymint_socket; then
                log "Mobicore ready (waited ${waited}s)"
                return 0
            fi
        fi
        
        # Check alternate TEE device paths
        if [ -e "/dev/.tee_client" ] || ls /dev/tc* >/dev/null 2>&1; then
            log "TEE device found, assuming ready"
            return 0
        fi
        
        sleep 1
        waited=$((waited + 1))
    done
    
    log "Mobicore not ready after ${MAX_WAIT}s - TIMEOUT"
    return 1
}

# Check keymint service availability
check_keymint_socket() {
    # Try multiple methods to detect keymint
    
    # Method 1: Check service list
    if service list 2>/dev/null | grep -q "android.hardware.security.keymint"; then
        return 0
    fi
    
    # Method 2: Check HIDL services
    if lshal 2>/dev/null | grep -q "IKeymasterDevice"; then
        return 0
    fi
    
    # Method 3: Check if process is running
    if pgrep -f "keymint-service.trustonic" >/dev/null 2>&1; then
        return 0
    fi
    
    # Method 4: Check if keymint process exists
    if pgrep -f "android.hardware.security.keymint" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Check gatekeeper availability
check_gatekeeper_ready() {
    log "Checking gatekeeper readiness..."
    
    local waited=0
    while [ $waited -lt $MAX_WAIT ]; do
        if service list 2>/dev/null | grep -q "android.hardware.gatekeeper"; then
            log "Gatekeeper ready (AIDL)"
            return 0
        fi
        
        if lshal 2>/dev/null | grep -q "IGatekeeper"; then
            log "Gatekeeper ready (HIDL)"
            return 0
        fi
        
        if pgrep -f "gatekeeper-service" >/dev/null 2>&1; then
            log "Gatekeeper process running"
            return 0
        fi
        
        sleep 1
        waited=$((waited + 1))
    done
    
    log "Gatekeeper not ready after ${MAX_WAIT}s"
    return 1
}

# Check keystore2 availability
check_keystore2_ready() {
    log "Checking keystore2 readiness..."
    
    local waited=0
    while [ $waited -lt 10 ]; do
        if pgrep -f "keystore2" >/dev/null 2>&1; then
            log "Keystore2 process running"
            return 0
        fi
        
        if service list 2>/dev/null | grep -q "android.system.keystore2"; then
            log "Keystore2 in service list"
            return 0
        fi
        
        sleep 1
        waited=$((waited + 1))
    done
    
    log "Keystore2 not ready (may not be critical)"
    return 1
}

# Full TEE chain check
wait_for_tee_chain() {
    log "=== Starting TEE Chain Check ==="
    local has_error=0
    
    # Step 1: Check mobicore
    if ! check_mobicore_ready; then
        log "ERROR: Mobicore check failed"
        setprop ro.vendor.tee.health "mobicore_failed"
        setprop ro.vendor.mobicore.timeout 1
        has_error=1
    else
        setprop ro.vendor.mobicore.ready 1
        log "Mobicore: OK"
    fi
    
    # Step 2: Wait briefly then check keymint
    sleep 2
    
    local keymint_waited=0
    while [ $keymint_waited -lt 15 ]; do
        if check_keymint_socket; then
            break
        fi
        sleep 1
        keymint_waited=$((keymint_waited + 1))
    done
    
    if [ $keymint_waited -ge 15 ]; then
        log "WARN: Keymint check timeout"
        # Don't fail completely, might still work
    fi
    
    # Step 3: Check gatekeeper (optional)
    if ! check_gatekeeper_ready; then
        log "WARN: Gatekeeper not available"
        setprop ro.vendor.gatekeeper.ready 0
    else
        setprop ro.vendor.gatekeeper.ready 1
        log "Gatekeeper: OK"
    fi
    
    # Step 4: Check keystore2 (optional)
    check_keystore2_ready || true
    
    # Final status
    if [ $has_error -eq 0 ]; then
        setprop ro.vendor.tee.health "ready"
        setprop ro.vendor.tee.initialized 1
        log "TEE Chain: READY"
        return 0
    else
        setprop ro.vendor.tee.health "partial"
        # Still mark as initialized to allow recovery to proceed
        setprop ro.vendor.tee.initialized 1
        log "TEE Chain: PARTIAL (proceeding anyway)"
        return 1
    fi
}

# Quick health check
quick_check() {
    local mobicore=$(getprop init.svc.mobicore)
    local keymint=$(getprop init.svc.vendor.keymint-trustonic)
    local tee_init=$(getprop ro.vendor.tee.initialized)
    
    echo "Mobicore: $mobicore"
    echo "Keymint: $keymint"
    echo "TEE Init: $tee_init"
    echo "Health: $(getprop ro.vendor.tee.health)"
}

# Entry point
case "$1" in
    mobicore)
        check_mobicore_ready
        ;;
    gatekeeper)
        check_gatekeeper_ready
        ;;
    keystore2)
        check_keystore2_ready
        ;;
    keymint)
        check_keymint_socket
        ;;
    tee_chain)
        wait_for_tee_chain
        ;;
    quick)
        quick_check
        ;;
    all|*)
        wait_for_tee_chain
        ;;
esac

exit $?
