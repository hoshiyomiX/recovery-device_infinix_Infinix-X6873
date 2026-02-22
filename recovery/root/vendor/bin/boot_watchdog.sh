#!/vendor/bin/sh
#
# Boot Watchdog and Fallback Manager for Infinix X6873 (GT 30 Pro)
# Version: 1.0 - Anti-Stuck Protection
#
# This script monitors boot progress and provides fallback
# if any service chain gets stuck, ensuring recovery always boots
#

LOGFILE="/tmp/boot_watchdog.log"
MAX_BOOT_TIME=60  # Maximum seconds to wait for TEE chain

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"
    echo "$1"
}

# Check if a service is running
is_service_running() {
    local svc="$1"
    [ "$(getprop init.svc.$svc)" = "running" ]
}

# Check if a service has stopped (completed for oneshot)
is_service_stopped() {
    local svc="$1"
    local state="$(getprop init.svc.$svc)"
    [ "$state" = "stopped" ] || [ "$state" = "crashed" ]
}

# Main watchdog function
watch_boot_chain() {
    log "=== Boot Watchdog Started ==="
    
    local waited=0
    local tee_initialized=0
    local last_progress=0
    
    while [ $waited -lt $MAX_BOOT_TIME ]; do
        # Check if TEE is initialized - SUCCESS!
        tee_initialized=$(getprop ro.vendor.tee.initialized 2>/dev/null)
        if [ "$tee_initialized" = "1" ]; then
            log "SUCCESS: TEE initialized after ${waited}s"
            setprop ro.vendor.boot.watchdog "success"
            return 0
        fi
        
        # Check progress at various stages
        local progress=""
        
        # Stage 1: crypto.ready
        if [ "$(getprop crypto.ready)" = "1" ]; then
            progress="crypto_ready"
        fi
        
        # Stage 2: TA ready
        if [ "$(getprop ro.vendor.ta.ready)" = "1" ]; then
            progress="ta_ready"
        fi
        
        # Stage 3: TEE module loaded
        if is_service_stopped tee_module_loader; then
            progress="module_loaded"
        fi
        
        # Stage 4: mobicore running
        if is_service_running mobicore; then
            progress="mobicore_running"
        fi
        
        # Stage 5: mobicore ready
        if [ "$(getprop ro.vendor.mobicore.ready)" = "1" ]; then
            progress="mobicore_ready"
        fi
        
        # Stage 6: keymint running
        if is_service_running vendor.keymint-trustonic; then
            progress="keymint_running"
        fi
        
        # Log progress changes
        if [ "$progress" != "$last_progress" ]; then
            log "Progress: $progress (waited ${waited}s)"
            last_progress="$progress"
        fi
        
        sleep 1
        waited=$((waited + 1))
    done
    
    # TIMEOUT - Implement fallback
    log "TIMEOUT after ${MAX_BOOT_TIME}s - Implementing fallback"
    
    # Determine where we got stuck
    local stuck_at="unknown"
    if [ -z "$last_progress" ]; then
        stuck_at="early_init"
    elif [ "$last_progress" = "crypto_ready" ]; then
        stuck_at="ta_check"
    elif [ "$last_progress" = "ta_ready" ]; then
        stuck_at="module_load"
    elif [ "$last_progress" = "module_loaded" ]; then
        stuck_at="mobicore_start"
    elif [ "$last_progress" = "mobicore_running" ]; then
        stuck_at="mobicore_init"
    elif [ "$last_progress" = "mobicore_ready" ]; then
        stuck_at="keymint_start"
    elif [ "$last_progress" = "keymint_running" ]; then
        stuck_at="keymint_init"
    fi
    
    log "Stuck at: $stuck_at"
    setprop ro.vendor.boot.stuck_at "$stuck_at"
    
    # Implement fallback based on stuck point
    case "$stuck_at" in
        early_init|ta_check|module_load)
            # TEE not starting - skip TEE entirely
            log "FALLBACK: Skipping TEE - decryption unavailable"
            setprop ro.vendor.tee.fallback "skip_tee"
            setprop ro.vendor.tee.initialized 0
            setprop ro.crypto.state unencrypted
            ;;
            
        mobicore_start|mobicore_init|mobicore_running)
            # Mobicore stuck - try restart
            log "FALLBACK: Restarting mobicore"
            stop mobicore
            sleep 2
            start mobicore
            # If still fails after restart, skip TEE
            sleep 10
            if ! is_service_running mobicore; then
                log "FALLBACK: Mobicore restart failed - skipping TEE"
                setprop ro.vendor.tee.fallback "mobicore_failed"
                setprop ro.vendor.tee.initialized 0
                setprop ro.crypto.state unencrypted
            fi
            ;;
            
        keymint_start|keymint_init|keymint_running)
            # Keymint stuck - try fallback gatekeeper
            log "FALLBACK: Keymint stuck - using fallback"
            setprop ro.vendor.tee.fallback "keymint_timeout"
            setprop ro.vendor.trustonic.ready 0
            start vendor.gatekeeper-fallback
            # Allow limited functionality
            setprop ro.vendor.tee.initialized 1
            setprop twrp.decrypt.keys_ready 0
            setprop twrp.decrypt.unavailable 1
            ;;
    esac
    
    setprop ro.vendor.boot.watchdog "fallback"
    log "Fallback complete - recovery should continue"
    return 1
}

# Skip decryption mode - force recovery to boot without TEE
skip_decryption_mode() {
    log "Skip decryption mode activated"
    
    # Stop all TEE services
    stop mobicore 2>/dev/null
    stop vendor.keymint-trustonic 2>/dev/null
    stop vendor.gatekeeper-trustonic 2>/dev/null
    stop vendor.trustonic-tee 2>/dev/null
    
    # Set properties to skip decryption
    setprop ro.vendor.tee.initialized 0
    setprop ro.vendor.tee.fallback "user_skip"
    setprop ro.crypto.state unsupported
    setprop twrp.decrypt.keys_ready 0
    setprop twrp.decrypt.unavailable 1
    setprop twrp.decrypt.skip 1
    
    log "Decryption skipped - recovery mode only"
}

# Check if user requested skip (via volume key or other trigger)
check_skip_request() {
    # Check for skip property (can be set by user via adb or trigger)
    if [ "$(getprop twrp.decrypt.skip_requested)" = "1" ]; then
        skip_decryption_mode
        return 0
    fi
    
    # Check for timeout on splash screen (detected via property)
    local splash_time=$(getprop ro.vendor.splash.time 2>/dev/null)
    if [ -n "$splash_time" ] && [ "$splash_time" -gt 30 ]; then
        log "Splash timeout detected (${splash_time}s) - forcing continue"
        skip_decryption_mode
        return 0
    fi
    
    return 1
}

# Emergency recovery - always allows boot
emergency_recovery() {
    log "EMERGENCY: Forcing recovery boot"
    
    # Kill any stuck processes
    killall mcDriverDaemon 2>/dev/null
    
    # Force all properties to allow boot
    setprop ro.vendor.tee.initialized 1
    setprop ro.vendor.tee.fallback "emergency"
    setprop ro.vendor.tee.health "emergency"
    setprop ro.crypto.state unsupported
    setprop twrp.decrypt.keys_ready 0
    setprop twrp.decrypt.unavailable 1
    setprop twrp.decrypt.emergency 1
    
    log "Emergency mode active - all features except decryption available"
}

# Main entry point
case "$1" in
    watch)
        watch_boot_chain
        ;;
    skip)
        skip_decryption_mode
        ;;
    emergency)
        emergency_recovery
        ;;
    check)
        check_skip_request
        ;;
    status)
        echo "Boot Watchdog Status:"
        echo "  TEE Initialized: $(getprop ro.vendor.tee.initialized)"
        echo "  TEE Fallback: $(getprop ro.vendor.tee.fallback)"
        echo "  Stuck At: $(getprop ro.vendor.boot.stuck_at)"
        echo "  Watchdog: $(getprop ro.vendor.boot.watchdog)"
        ;;
    *)
        watch_boot_chain
        ;;
esac

exit $?
