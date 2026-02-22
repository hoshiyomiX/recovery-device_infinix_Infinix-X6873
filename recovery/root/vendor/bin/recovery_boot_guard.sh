#!/vendor/bin/sh
#
# Recovery Boot Guard for Infinix X6873 (GT 30 Pro)
# Version: 1.0 - Splash Logo Stuck Prevention
#
# This script monitors boot progress and forces recovery UI
# if any stage gets stuck for too long.
#

LOGFILE="/tmp/recovery_boot_guard.log"
MAX_BOOT_TIME=120  # 2 minutes max total boot time
STUCK_THRESHOLD=30 # 30 seconds without progress = stuck

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"
    echo "$1"
}

# Get current boot progress
get_progress() {
    getprop ro.vendor.boot.progress 2>/dev/null || echo "0"
}

# Check if TEE is stuck
check_tee_stuck() {
    local progress=$(get_progress)
    local tee_init=$(getprop ro.vendor.tee.initialized)
    local boot_stuck=$(getprop ro.vendor.boot.stuck)
    
    # Already marked as stuck
    [ "$boot_stuck" = "1" ] && return 0
    
    # TEE initialized properly
    [ "$tee_init" = "1" ] && return 1
    
    # Check progress - if stuck at same value for too long
    local last_progress_file="/tmp/.last_progress"
    local last_time_file="/tmp/.last_progress_time"
    
    if [ -f "$last_progress_file" ]; then
        local last_progress=$(cat "$last_progress_file" 2>/dev/null)
        local last_time=$(cat "$last_time_file" 2>/dev/null)
        local current_time=$(date +%s)
        
        if [ "$progress" = "$last_progress" ] && [ "$progress" != "100" ]; then
            local elapsed=$((current_time - last_time))
            if [ $elapsed -gt $STUCK_THRESHOLD ]; then
                log "Boot stuck at progress $progress for ${elapsed}s"
                return 0
            fi
        fi
    fi
    
    # Update tracking
    echo "$progress" > "$last_progress_file"
    date +%s > "$last_time_file"
    
    return 1
}

# Force recovery UI to show
force_recovery_ui() {
    log "Forcing recovery UI - decryption will be unavailable"
    
    # Set stuck flag
    setprop ro.vendor.boot.stuck 1
    
    # Stop TEE services that might be hanging
    stop mobicore 2>/dev/null
    stop vendor.keymint-trustonic 2>/dev/null
    stop vendor.trustonic-tee 2>/dev/null
    stop keystore2_recovery 2>/dev/null
    stop tee_health_check 2>/dev/null
    
    # Set crypto state to unsupported so TWRP proceeds
    setprop ro.crypto.state unsupported
    setprop twrp.decrypt.failed 1
    setprop twrp.decrypt.skipped 1
    setprop twrp.decrypt.done true
    
    # Force boot completed
    setprop sys.boot_completed 1
    setprop ro.vendor.boot.progress 100
    
    log "Recovery UI should now be visible"
}

# Watchdog main loop
watchdog() {
    log "Boot guard watchdog started"
    log "Max boot time: ${MAX_BOOT_TIME}s, Stuck threshold: ${STUCK_THRESHOLD}s"
    
    local start_time=$(date +%s)
    local elapsed=0
    
    while [ $elapsed -lt $MAX_BOOT_TIME ]; do
        # Check if boot completed normally
        local boot_completed=$(getprop sys.boot_completed)
        local decrypt_done=$(getprop twrp.decrypt.done)
        
        if [ "$boot_completed" = "1" ] || [ "$decrypt_done" = "true" ]; then
            log "Boot completed normally after ${elapsed}s"
            exit 0
        fi
        
        # Check if stuck
        if check_tee_stuck; then
            force_recovery_ui
            exit 0
        fi
        
        # Log progress periodically
        local progress=$(get_progress)
        if [ $((elapsed % 10)) -eq 0 ]; then
            log "Boot progress: $progress%, elapsed: ${elapsed}s"
        fi
        
        sleep 2
        elapsed=$(($(date +%s) - start_time))
    done
    
    # Total timeout reached
    log "Total boot timeout reached (${MAX_BOOT_TIME}s)"
    force_recovery_ui
}

# Emergency skip - can be triggered manually
emergency_skip() {
    log "Emergency skip triggered manually"
    setprop ro.vendor.boot.emergency 1
    force_recovery_ui
}

# Status check
status() {
    echo "=== Recovery Boot Guard Status ==="
    echo "Progress: $(get_progress)%"
    echo "TEE Initialized: $(getprop ro.vendor.tee.initialized)"
    echo "Boot Stuck: $(getprop ro.vendor.boot.stuck)"
    echo "Boot Completed: $(getprop sys.boot_completed)"
    echo "Decrypt Done: $(getprop twrp.decrypt.done)"
    echo "Decrypt Failed: $(getprop twrp.decrypt.failed)"
    echo "Decrypt Skipped: $(getprop twrp.decrypt.skipped)"
    echo ""
    echo "Service Status:"
    echo "  mobicore: $(getprop init.svc.mobicore)"
    echo "  keymint: $(getprop init.svc.vendor.keymint-trustonic)"
    echo "  keystore2: $(getprop init.svc.keystore2_recovery)"
}

# Entry point
case "$1" in
    watchdog)
        watchdog
        ;;
    skip)
        emergency_skip
        ;;
    status)
        status
        ;;
    *)
        watchdog
        ;;
esac

exit 0
