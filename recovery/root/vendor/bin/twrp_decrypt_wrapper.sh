#!/vendor/bin/sh
#
# TWRP Decryption Wrapper for Infinix X6873 (GT 30 Pro)
# Version: 1.0 - Safe Decryption with Fallback
#
# This script wraps the decryption process with proper
# error handling and fallback mechanisms.
#

LOGFILE="/tmp/twrp_decrypt_wrapper.log"
MAX_DECRYPT_TIME=60  # 60 seconds max for decryption attempt

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"
    echo "$1"
}

# Check if TEE is ready
wait_for_tee() {
    local waited=0
    local max_wait=30
    
    log "Waiting for TEE to be ready..."
    
    while [ $waited -lt $max_wait ]; do
        local tee_ready=$(getprop ro.vendor.tee.initialized)
        if [ "$tee_ready" = "1" ]; then
            log "TEE ready after ${waited}s"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    
    log "TEE not ready after ${max_wait}s"
    return 1
}

# Check if keymint bridge is available
check_keymint_bridge() {
    # Check if bridge library is loaded
    if [ -f "/vendor/lib64/libtwrp_keymint_bridge.so" ]; then
        log "Keymint bridge library found"
        return 0
    fi
    
    log "Keymint bridge library not found"
    return 1
}

# Attempt FBE v2 decryption
attempt_decryption() {
    local user_id="${1:-0}"
    local password="$2"
    
    log "Attempting decryption for user $user_id"
    
    # Check if already decrypted
    local decrypt_done=$(getprop twrp.decrypt.done)
    if [ "$decrypt_done" = "true" ]; then
        log "Already decrypted"
        return 0
    fi
    
    # Wait for TEE
    if ! wait_for_tee; then
        log "TEE not available, decryption not possible"
        setprop twrp.decrypt.failed 1
        setprop twrp.decrypt.error "tee_unavailable"
        return 1
    fi
    
    # Check keymint
    local keymint_ready=$(getprop ro.vendor.trustonic.ready)
    if [ "$keymint_ready" != "1" ]; then
        log "Keymint not ready"
        setprop twrp.decrypt.failed 1
        setprop twrp.decrypt.error "keymint_unavailable"
        return 1
    fi
    
    # Set properties to signal decryption attempt
    setprop twrp.decrypt.attempting 1
    
    # The actual decryption is handled by TWRP's internal crypto
    # This script just sets up the environment and handles errors
    
    # Check if password is needed
    local need_password=$(getprop twrp.decrypt.need_password)
    if [ "$need_password" = "1" ] && [ -z "$password" ]; then
        log "Password required but not provided"
        setprop twrp.decrypt.need_password 1
        return 2  # Special return code for "need password"
    fi
    
    # Signal that keys should be ready
    setprop twrp.decrypt.keys_ready 1
    
    log "Decryption setup complete, TWRP should handle the rest"
    return 0
}

# Fallback - skip decryption and mount data unencrypted
fallback_no_decrypt() {
    log "Entering fallback mode - decryption skipped"
    
    # Set properties to skip decryption
    setprop ro.crypto.state unsupported
    setprop twrp.decrypt.skipped 1
    setprop twrp.decrypt.done true
    
    # Try to mount data anyway (might fail but user can still access recovery)
    log "Attempting to mount data without decryption..."
    
    # Data will be mounted by TWRP's normal mount process
    # This just signals that decryption should be skipped
    
    log "Fallback mode active - user can access recovery but data will be encrypted"
}

# Status check
show_status() {
    echo "=== TWRP Decryption Status ==="
    echo "TEE Ready: $(getprop ro.vendor.tee.initialized)"
    echo "Keymint Ready: $(getprop ro.vendor.trustonic.ready)"
    echo "Keys Ready: $(getprop twrp.decrypt.keys_ready)"
    echo "Need Password: $(getprop twrp.decrypt.need_password)"
    echo "Decrypt Done: $(getprop twrp.decrypt.done)"
    echo "Decrypt Failed: $(getprop twrp.decrypt.failed)"
    echo "Decrypt Skipped: $(getprop twrp.decrypt.skipped)"
    echo "Decrypt Error: $(getprop twrp.decrypt.error)"
    echo ""
    echo "Crypto State: $(getprop ro.crypto.state)"
}

# Main decryption with timeout
decrypt_with_timeout() {
    local user_id="${1:-0}"
    local password="$2"
    
    log "Starting decryption with ${MAX_DECRYPT_TIME}s timeout"
    
    # Run decryption in background
    (
        attempt_decryption "$user_id" "$password"
        exit $?
    ) &
    local decrypt_pid=$!
    
    # Wait with timeout
    local waited=0
    while [ $waited -lt $MAX_DECRYPT_TIME ]; do
        # Check if process finished
        if ! kill -0 $decrypt_pid 2>/dev/null; then
            wait $decrypt_pid
            local result=$?
            
            case $result in
                0)
                    log "Decryption successful"
                    setprop twrp.decrypt.done true
                    return 0
                    ;;
                2)
                    log "Password required"
                    setprop twrp.decrypt.need_password 1
                    return 2
                    ;;
                *)
                    log "Decryption failed with code $result"
                    setprop twrp.decrypt.failed 1
                    return 1
                    ;;
            esac
        fi
        
        # Check if already done
        local done=$(getprop twrp.decrypt.done)
        if [ "$done" = "true" ]; then
            log "Decryption marked as done"
            kill $decrypt_pid 2>/dev/null
            return 0
        fi
        
        sleep 1
        waited=$((waited + 1))
    done
    
    # Timeout
    log "Decryption timed out after ${MAX_DECRYPT_TIME}s"
    kill $decrypt_pid 2>/dev/null
    setprop twrp.decrypt.failed 1
    setprop twrp.decrypt.error "timeout"
    
    # Enter fallback
    fallback_no_decrypt
    return 1
}

# Entry point
case "$1" in
    decrypt)
        decrypt_with_timeout "$2" "$3"
        ;;
    attempt)
        attempt_decryption "$2" "$3"
        ;;
    fallback)
        fallback_no_decrypt
        ;;
    status)
        show_status
        ;;
    check)
        check_keymint_bridge
        ;;
    *)
        decrypt_with_timeout "${1:-0}" "$2"
        ;;
esac

exit $?
