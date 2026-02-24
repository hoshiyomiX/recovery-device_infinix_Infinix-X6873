#!/system/bin/sh
#
# OTG Hotplug Handler for Infinix X6873
# MediaTek MT6897 Platform
#
# This script handles USB OTG connection state changes
# and triggers appropriate actions for device/host mode switching
#

LOG_TAG="OTG_Hotplug"
LOG_FILE="/tmp/otg_hotplug.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG: $1" >> $LOG_FILE
    log -t "$LOG_TAG" "$1" 2>/dev/null
}

# Find the extcon device for USB OTG detection
find_extcon_device() {
    for extcon in /sys/class/extcon/*/; do
        if [ -f "${extcon}name" ]; then
            name=$(cat "${extcon}name" 2>/dev/null)
            case "$name" in
                *usb*|*otg*|*dwc3*)
                    echo "${extcon}state"
                    return 0
                    ;;
            esac
        fi
    done
    # Fallback to first extcon device
    if [ -f /sys/class/extcon/extcon0/state ]; then
        echo "/sys/class/extcon/extcon0/state"
        return 0
    fi
    return 1
}

# Parse extcon state to detect USB mode
parse_usb_state() {
    local state="$1"

    # USB=1 means USB connected in device mode
    # USB_HOST=1 means USB host mode (OTG flash drive connected)
    if echo "$state" | grep -q "USB_HOST=1"; then
        echo "host"
    elif echo "$state" | grep -q "USB=1"; then
        echo "device"
    else
        echo "disconnected"
    fi
}

# Handle device mode connection
handle_device_mode() {
    log_message "USB device mode connected"
    setprop sys.usb.otg.connected 1
    setprop sys.usb.otg.host_mode 0

    # Ensure USB controller is in peripheral mode
    for udc in /sys/class/udc/*/device/../mode; do
        if [ -f "$udc" ]; then
            echo "peripheral" > "$udc" 2>/dev/null
            log_message "Set USB controller to peripheral mode"
        fi
    done
}

# Handle host mode connection (OTG flash drive)
handle_host_mode() {
    log_message "USB host mode detected - OTG device connected"
    setprop sys.usb.otg.connected 1
    setprop sys.usb.otg.host_mode 1

    # Set USB controller to host mode
    for udc in /sys/class/udc/*/device/../mode; do
        if [ -f "$udc" ]; then
            echo "host" > "$udc" 2>/dev/null
            log_message "Set USB controller to host mode"
        fi
    done

    # Wait for USB storage device to appear
    sleep 2

    # Try to mount USB storage
    mount_usb_storage
}

# Handle disconnection
handle_disconnect() {
    log_message "USB disconnected"
    setprop sys.usb.otg.connected 0
    setprop sys.usb.otg.host_mode 0

    # Unmount any USB storage
    if mountpoint -q /mnt/usb_otg 2>/dev/null; then
        umount /mnt/usb_otg
        log_message "Unmounted /mnt/usb_otg"
    fi
    setprop twrp.otg.mounted 0
}

# Mount USB storage device
mount_usb_storage() {
    local mounted=0

    # Create mount point if it doesn't exist
    mkdir -p /mnt/usb_otg

    # Try different block devices
    for device in /dev/block/sd*; do
        if [ -b "$device" ]; then
            # Skip if it's the internal storage (sda/sdb/sdc on UFS devices)
            case "$device" in
                /dev/block/sda|/dev/block/sda[0-9]*)
                    # This could be internal UFS, check size
                    ;;
                *)
                    # Try to mount
                    if mount -t vfat -o rw,umask=0000 "$device" /mnt/usb_otg 2>/dev/null; then
                        log_message "Mounted $device to /mnt/usb_otg"
                        setprop twrp.otg.mounted 1
                        setprop sys.usb.otg.device_attached 1
                        mounted=1
                        break
                    fi
                    ;;
            esac
        fi
    done

    # Also try partitions (sd*1, sd*2, etc.)
    if [ $mounted -eq 0 ]; then
        for device in /dev/block/sd[defgh][1-9]; do
            if [ -b "$device" ]; then
                if mount -t vfat -o rw,umask=0000 "$device" /mnt/usb_otg 2>/dev/null; then
                    log_message "Mounted $device to /mnt/usb_otg"
                    setprop twrp.otg.mounted 1
                    setprop sys.usb.otg.device_attached 1
                    mounted=1
                    break
                fi
            fi
        done
    fi

    # Try exFAT and NTFS as fallback
    if [ $mounted -eq 0 ]; then
        for device in /dev/block/sd[defgh]*; do
            if [ -b "$device" ]; then
                # Try exFAT
                if mount -t exfat -o rw,umask=0000 "$device" /mnt/usb_otg 2>/dev/null; then
                    log_message "Mounted $device (exFAT) to /mnt/usb_otg"
                    setprop twrp.otg.mounted 1
                    setprop sys.usb.otg.device_attached 1
                    mounted=1
                    break
                fi
                # Try NTFS
                if ntfs-3g "$device" /mnt/usb_otg 2>/dev/null; then
                    log_message "Mounted $device (NTFS) to /mnt/usb_otg"
                    setprop twrp.otg.mounted 1
                    setprop sys.usb.otg.device_attached 1
                    mounted=1
                    break
                fi
            fi
        done
    fi

    if [ $mounted -eq 0 ]; then
        log_message "No mountable USB storage found"
    fi
}

# Main monitoring loop
main() {
    log_message "OTG Hotplug Handler started"

    EXTCON_STATE=$(find_extcon_device)
    if [ -z "$EXTCON_STATE" ]; then
        log_message "Warning: No extcon device found, using alternative detection"

        # Alternative: Monitor via USB device filesystem
        while true; do
            # Check for USB devices in host mode
            usb_devices=$(ls /dev/bus/usb/*/* 2>/dev/null | wc -l)

            if [ "$usb_devices" -gt 0 ]; then
                current_mode=$(getprop sys.usb.otg.host_mode)
                if [ "$current_mode" != "1" ]; then
                    handle_host_mode
                fi
            else
                current_mode=$(getprop sys.usb.otg.host_mode)
                if [ "$current_mode" = "1" ]; then
                    handle_disconnect
                fi
            fi

            sleep 1
        done
    else
        log_message "Using extcon device: $EXTCON_STATE"

        last_state=""

        while true; do
            current_state=$(cat "$EXTCON_STATE" 2>/dev/null)

            if [ "$current_state" != "$last_state" ]; then
                log_message "State changed: $current_state"
                last_state="$current_state"

                mode=$(parse_usb_state "$current_state")

                case "$mode" in
                    host)
                        handle_host_mode
                        ;;
                    device)
                        handle_device_mode
                        ;;
                    disconnected)
                        handle_disconnect
                        ;;
                esac
            fi

            sleep 1
        done
    fi
}

# Handle script termination
trap 'log_message "OTG Hotplug Handler stopped"; exit 0' TERM INT

# Run main function
main
