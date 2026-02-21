#!/system/bin/sh
#
# TA (Trusted Application) Extraction Script for Infinix X6873
# This script extracts TA files from a firmware image or dump
#
# Part of FIX for: TA Version Mismatch
#
# Usage:
#   ta_extract.sh <firmware_directory_or_image>
#
# The script will:
#   1. Find and extract TA files from vendor partition
#   2. Compare with current TA files
#   3. Create backup of old TA files
#   4. Install new TA files
#

SCRIPT_VERSION="1.0"
DEVICE="X6873"
PLATFORM="mt6897"

# Colors for output (if terminal supports)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
CURRENT_TA_DIR="/vendor/app/mcRegistry"
BACKUP_DIR="/sdcard/ta_backup_$(date +%Y%m%d_%H%M%S)"
EXTRACT_DIR="/tmp/ta_extract"

# Required TA files for decryption
REQUIRED_TA="
06090000000000000000000000000000.drbin
06090000000000000000000000000000.tlbin
07210000000000000000000000000000.drbin
07210000000000000000000000000000.tlbin
08050000000000000000000000003419.drbin
08050000000000000000000000003419.tlbin
40188311faf343488db888ad39496f9a.drbin
40188311faf343488db888ad39496f9a.tlbin
5020170115e016302017012521300000.drbin
5020170115e016302017012521300000.tlbin
020f0000000000000000000000000000.drbin
020f0000000000000000000000000000.tlbin
"

log_info() {
    echo "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    echo "TA Extraction Script v${SCRIPT_VERSION}"
    echo "For Infinix ${DEVICE} (${PLATFORM})"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  extract <firmware_dir>   Extract TA files from firmware directory"
    echo "  backup                   Backup current TA files"
    echo "  compare <dir1> <dir2>    Compare TA files between two directories"
    echo "  verify                   Verify current TA files integrity"
    echo "  install <ta_dir>         Install TA files from directory"
    echo "  info                     Show TA file information"
    echo ""
    echo "Example:"
    echo "  $0 extract /sdcard/firmware_dump"
    echo "  $0 backup"
    echo "  $0 verify"
}

# Backup current TA files
backup_current_ta() {
    log_info "Backing up current TA files..."
    
    if [ ! -d "$CURRENT_TA_DIR" ]; then
        log_error "Current TA directory not found: $CURRENT_TA_DIR"
        return 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    if cp -r "$CURRENT_TA_DIR"/* "$BACKUP_DIR/"; then
        log_info "Backup created: $BACKUP_DIR"
        
        # Create version info
        echo "Backup Date: $(date)" > "$BACKUP_DIR/backup_info.txt"
        echo "Device: $DEVICE" >> "$BACKUP_DIR/backup_info.txt"
        echo "Firmware: $(getprop ro.build.fingerprint)" >> "$BACKUP_DIR/backup_info.txt"
        
        return 0
    else
        log_error "Failed to create backup"
        return 1
    fi
}

# Extract TA files from firmware
extract_ta_from_firmware() {
    local firmware_dir="$1"
    
    log_info "Extracting TA files from: $firmware_dir"
    
    if [ ! -d "$firmware_dir" ]; then
        log_error "Firmware directory not found: $firmware_dir"
        return 1
    fi
    
    mkdir -p "$EXTRACT_DIR"
    
    # Look for vendor partition image
    local vendor_img=""
    
    # Check common locations
    for path in "$firmware_dir/vendor.img" "$firmware_dir/vendor.bin" \
                "$firmware_dir/images/vendor.img" "$firmware_dir/vendor partition.img"; do
        if [ -f "$path" ]; then
            vendor_img="$path"
            break
        fi
    done
    
    if [ -z "$vendor_img" ]; then
        # Try to find vendor image automatically
        vendor_img=$(find "$firmware_dir" -name "vendor*.img" -o -name "vendor*.bin" 2>/dev/null | head -1)
    fi
    
    if [ -n "$vendor_img" ] && [ -f "$vendor_img" ]; then
        log_info "Found vendor image: $vendor_img"
        
        # Mount vendor image (requires root)
        mkdir -p /tmp/vendor_mount
        
        # Try different mount methods
        if mount -o loop,ro "$vendor_img" /tmp/vendor_mount 2>/dev/null; then
            log_info "Mounted vendor image"
            
            # Copy TA files
            if [ -d "/tmp/vendor_mount/app/mcRegistry" ]; then
                cp -r /tmp/vendor_mount/app/mcRegistry/* "$EXTRACT_DIR/"
                log_info "TA files extracted: $(ls -1 $EXTRACT_DIR | wc -l) files"
            else
                log_error "mcRegistry directory not found in vendor image"
            fi
            
            umount /tmp/vendor_mount
        else
            log_warn "Could not mount vendor image directly"
            log_info "Trying to extract using 7zip or similar..."
            
            # Try using 7z or other extraction tools
            if command -v 7z > /dev/null; then
                7z x "$vendor_img" -o/tmp/vendor_extract -y > /dev/null 2>&1
                if [ -d "/tmp/vendor_extract/app/mcRegistry" ]; then
                    cp -r /tmp/vendor_extract/app/mcRegistry/* "$EXTRACT_DIR/"
                    log_info "TA files extracted using 7z"
                fi
            fi
        fi
    else
        # Check if TA files are already extracted
        if [ -d "$firmware_dir/mcRegistry" ]; then
            log_info "Found mcRegistry directory in firmware dump"
            cp -r "$firmware_dir/mcRegistry"/* "$EXTRACT_DIR/"
        elif [ -d "$firmware_dir/vendor/app/mcRegistry" ]; then
            log_info "Found vendor mcRegistry in firmware dump"
            cp -r "$firmware_dir/vendor/app/mcRegistry"/* "$EXTRACT_DIR/"
        else
            log_error "Could not find TA files in firmware directory"
            return 1
        fi
    fi
    
    # Verify extraction
    local ta_count=$(ls -1 "$EXTRACT_DIR"/*.drbin "$EXTRACT_DIR"/*.tlbin 2>/dev/null | wc -l)
    
    if [ $ta_count -gt 0 ]; then
        log_info "Successfully extracted $ta_count TA files"
        return 0
    else
        log_error "No TA files extracted"
        return 1
    fi
}

# Compare TA files between directories
compare_ta() {
    local dir1="$1"
    local dir2="$2"
    
    log_info "Comparing TA files..."
    log_info "Directory 1: $dir1"
    log_info "Directory 2: $dir2"
    
    if [ ! -d "$dir1" ] || [ ! -d "$dir2" ]; then
        log_error "Both directories must exist"
        return 1
    fi
    
    echo ""
    echo "File comparison:"
    echo "----------------"
    
    for file in "$dir1"/*.drbin "$dir1"/*.tlbin "$dir1"/*.tabin; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local file2="$dir2/$filename"
            
            if [ -f "$file2" ]; then
                # Compare MD5
                local md5_1=$(md5sum "$file" | awk '{print $1}')
                local md5_2=$(md5sum "$file2" | awk '{print $1}')
                
                if [ "$md5_1" = "$md5_2" ]; then
                    echo "  [MATCH]     $filename"
                else
                    echo "  [DIFFER]    $filename"
                    echo "              Old: $md5_1"
                    echo "              New: $md5_2"
                fi
            else
                echo "  [MISSING]   $filename (not in directory 2)"
            fi
        fi
    done
    
    # Check for new files in dir2
    for file in "$dir2"/*.drbin "$dir2"/*.tlbin "$dir2"/*.tabin; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local file1="$dir1/$filename"
            
            if [ ! -f "$file1" ]; then
                echo "  [NEW]       $filename (only in directory 2)"
            fi
        fi
    done
    
    return 0
}

# Verify current TA files
verify_ta() {
    log_info "Verifying current TA files..."
    
    if [ ! -d "$CURRENT_TA_DIR" ]; then
        log_error "TA directory not found: $CURRENT_TA_DIR"
        return 1
    fi
    
    echo ""
    echo "Checking required TA files:"
    echo "--------------------------"
    
    local missing=0
    local found=0
    
    for ta in $REQUIRED_TA; do
        if [ -f "$CURRENT_TA_DIR/$ta" ]; then
            local size=$(stat -c%s "$CURRENT_TA_DIR/$ta" 2>/dev/null)
            local md5=$(md5sum "$CURRENT_TA_DIR/$ta" 2>/dev/null | awk '{print $1}')
            echo "  [OK]   $ta (${size} bytes)"
            echo "         MD5: $md5"
            found=$((found + 1))
        else
            echo "  [MISSING] $ta"
            missing=$((missing + 1))
        fi
    done
    
    echo ""
    echo "Summary:"
    echo "--------"
    echo "  Found: $found"
    echo "  Missing: $missing"
    
    local total=$(ls -1 "$CURRENT_TA_DIR"/*.drbin "$CURRENT_TA_DIR"/*.tlbin 2>/dev/null | wc -l)
    echo "  Total TA files: $total"
    
    if [ $missing -gt 0 ]; then
        log_warn "$missing required TA files are missing!"
        return 1
    else
        log_info "All required TA files are present"
        return 0
    fi
}

# Install TA files
install_ta() {
    local ta_dir="$1"
    
    log_info "Installing TA files from: $ta_dir"
    
    if [ ! -d "$ta_dir" ]; then
        log_error "TA directory not found: $ta_dir"
        return 1
    fi
    
    # Backup current TA first
    backup_current_ta
    
    # Check if we need root
    if [ "$(id -u)" != "0" ]; then
        log_warn "Not running as root, may not be able to write to vendor partition"
    fi
    
    # Remount vendor as RW if possible
    mount -o remount,rw /vendor 2>/dev/null
    
    # Copy new TA files
    local copied=0
    for file in "$ta_dir"/*.drbin "$ta_dir"/*.tlbin "$ta_dir"/*.tabin; do
        if [ -f "$file" ]; then
            cp "$file" "$CURRENT_TA_DIR/"
            copied=$((copied + 1))
        fi
    done
    
    # Set permissions
    chmod 644 "$CURRENT_TA_DIR"/*.drbin "$CURRENT_TA_DIR"/*.tlbin "$CURRENT_TA_DIR"/*.tabin 2>/dev/null
    chown root:root "$CURRENT_TA_DIR"/*.drbin "$CURRENT_TA_DIR"/*.tlbin "$CURRENT_TA_DIR"/*.tabin 2>/dev/null
    
    # Remount vendor as RO
    mount -o remount,ro /vendor 2>/dev/null
    
    log_info "Installed $copied TA files"
    
    # Verify installation
    verify_ta
    
    return $?
}

# Show TA information
show_ta_info() {
    log_info "TA Information"
    
    echo ""
    echo "Device: $DEVICE"
    echo "Platform: $PLATFORM"
    echo "TA Directory: $CURRENT_TA_DIR"
    echo ""
    
    if [ -d "$CURRENT_TA_DIR" ]; then
        echo "Installed TA Files:"
        echo "-------------------"
        
        echo ""
        echo "Drivers (.drbin):"
        ls -lh "$CURRENT_TA_DIR"/*.drbin 2>/dev/null | awk '{print "  " $NF ": " $5}'
        
        echo ""
        echo "Trusted Apps (.tlbin):"
        ls -lh "$CURRENT_TA_DIR"/*.tlbin 2>/dev/null | awk '{print "  " $NF ": " $5}'
        
        echo ""
        echo "Tabin files (.tabin):"
        ls -lh "$CURRENT_TA_DIR"/*.tabin 2>/dev/null | awk '{print "  " $NF ": " $5}'
    else
        log_error "TA directory not accessible"
    fi
    
    echo ""
    echo "Firmware Version: $(getprop ro.build.fingerprint)"
    echo "Vendor Version: $(getprop ro.vendor.build.fingerprint)"
    
    return 0
}

# Main entry point
case "$1" in
    extract)
        extract_ta_from_firmware "$2"
        ;;
    backup)
        backup_current_ta
        ;;
    compare)
        compare_ta "$2" "$3"
        ;;
    verify)
        verify_ta
        ;;
    install)
        install_ta "$2"
        ;;
    info)
        show_ta_info
        ;;
    *)
        show_usage
        ;;
esac

exit $?
