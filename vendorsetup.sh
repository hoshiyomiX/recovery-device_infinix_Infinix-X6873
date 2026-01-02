#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2024-2025 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

#set -o xtrace
FDEVICE="X6873"

# Clone to fix build on minimal manifest
git clone https://android.googlesource.com/platform/external/gflags/ -b android-12.1.0_r4 external/gflags

export FOX_USE_SPECIFIC_MAGISK_ZIP=~/Magisk/Magisk-v28.1.zip
export FOX_VIRTUAL_AB_DEVICE=1
export FOX_VANILLA_BUILD=1
export FOX_ENABLE_APP_MANAGER=1
export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"
export FOX_USE_BASH_SHELL=1
export FOX_ASH_IS_BASH=1
export FOX_USE_TAR_BINARY=1
export FOX_USE_LZ4_BINARY=1
export FOX_USE_SED_BINARY=1
export FOX_USE_XZ_UTILS=1
export FOX_USE_ZSTD_BINARY=1
export FOX_USE_NANO_EDITOR=1
export FOX_DELETE_AROMAFM=1
export OF_DEFAULT_KEYMASTER_VERSION=4.1

# screen settings
export OF_SCREEN_H=2460
export OF_STATUS_H=95
export OF_STATUS_INDENT_LEFT=48
export OF_STATUS_INDENT_RIGHT=48
export OF_ALLOW_DISABLE_NAVBAR=0
export OF_CLOCK_POS=1

# other stuff
export OF_QUICK_BACKUP_LIST="/boot:/data"
export OF_ENABLE_LPTOOLS=1
export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
export FOX_USE_BASH_SHELL=1
export FOX_USE_NANO_EDITOR=1

# number of list options before scrollbar creation
export OF_OPTIONS_LIST_NUM=9

# ----- data format stuff -----
# ensure that /sdcard is bind-unmounted before f2fs data repair or format
export OF_UNBIND_SDCARD_F2FS=1

# automatically wipe /metadata after data format
export OF_WIPE_METADATA_AFTER_DATAFORMAT=1

# avoid MTP issues after data format
export OF_BIND_MOUNT_SDCARD_ON_FORMAT=1

# don't spam the console with loop errors
export OF_LOOP_DEVICE_ERRORS_TO_LOG=1

# lz4 compression
export OF_USE_LZ4_COMPRESSION=1

# build all the partition tools
export OF_ENABLE_ALL_PARTITION_TOOLS=1

# variant
export OF_MAINTAINER="Guzram"

# no flashlight
export OF_FLASHLIGHT_ENABLE=0

	# ccache
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_MAXSIZE="5G"
export CCACHE_DIR=".ccache"

if [ ! -d ${CCACHE_DIR} ]; then
	mkdir $CCACHE_DIR
fi