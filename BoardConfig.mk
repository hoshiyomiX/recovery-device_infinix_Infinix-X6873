#
# Copyright (C) 2025 The Android Open Source Project
# Copyright (C) 2025 TWRP Device Tree for Infinix X6873
#
# SPDX-License-Identifier: Apache-2.0
#
# BoardConfig template adapted from Andrikurn/twrp_device_infinix_X6728
# Hardware values remain X6873-native (MT6897, UFS 4.0, armv8-2a, 1080x2400).
#

DEVICE_PATH := device/infinix/X6873

# Architecture
TARGET_ARCH                := arm64
TARGET_ARCH_VARIANT        := armv8-2a
TARGET_CPU_ABI             := arm64-v8a
TARGET_CPU_ABI2            :=
TARGET_CPU_VARIANT         := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a715

TARGET_2ND_ARCH                := arm
TARGET_2ND_ARCH_VARIANT        := armv8-2a
TARGET_2ND_CPU_ABI             := armeabi-v7a
TARGET_2ND_CPU_ABI2            := armeabi
TARGET_2ND_CPU_VARIANT         := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_USES_64_BIT_BINDER := true

# Power
ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Assert
TARGET_OTA_ASSERT_DEVICE := Infinix-X6873,X6873

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := X6873
TARGET_NO_BOOTLOADER         := true
TARGET_USES_UEFI             := true

# Build hacks
ALLOW_MISSING_DEPENDENCIES                   := true
BUILD_BROKEN_DUP_RULES                       := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_NINJA_USES_ENV_VARS             += RTIC_MPGEN
BUILD_BROKEN_PLUGIN_VALIDATION               := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# DTBO
BOARD_KERNEL_SEPARATED_DTBO := true

# Kernel
BOARD_RAMDISK_USE_LZ4 := true
TARGET_NO_KERNEL      := true

BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE    := 0x40078000
BOARD_VENDOR_CMDLINE := bootopt=64S3,32N2,64N2 buildvariant=user
BOARD_PAGE_SIZE      := 4096
BOARD_KERNEL_OFFSET  := 0x00008000
BOARD_RAMDISK_OFFSET := 0x11088000
BOARD_TAGS_OFFSET    := 0x07c08000
BOARD_DTB_OFFSET     := 0x07c08000

BOARD_MKBOOTIMG_ARGS += --vendor_cmdline $(BOARD_VENDOR_CMDLINE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_PAGE_SIZE) --board ""
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

# DTB - prebuilt
TARGET_PREBUILT_DTB  := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)

# AVB
BOARD_AVB_ENABLE                           := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS           += --flags 3
BOARD_AVB_ROLLBACK_INDEX                   := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ALGORITHM               := SHA256_RSA4096
BOARD_AVB_RECOVERY_KEY_PATH                := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ROLLBACK_INDEX          := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# Hardware
BOARD_USES_MTK_HARDWARE := true

# Partitions
BOARD_FLASH_BLOCK_SIZE                        := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE                := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE         := $(BOARD_BOOTIMAGE_PARTITION_SIZE)
BOARD_HAS_LARGE_FILESYSTEM                    := true
BOARD_SUPER_PARTITION_SIZE                    := 9126805504
BOARD_SUPER_PARTITION_GROUPS                  := infinix_dynamic_partitions
BOARD_INFINIX_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor product system_ext odm
BOARD_INFINIX_DYNAMIC_PARTITIONS_SIZE         := 9122611200
BOARD_USES_METADATA_PARTITION                 := true
BOARD_ROOT_EXTRA_FOLDERS                      += metadata

BOARD_INFINIX_DYNAMIC_PARTITIONS_PARTITION_LIST += \
    product \
    system \
    system_ext \
    vendor \
    odm

TARGET_COPY_OUT_ODM        := odm
TARGET_COPY_OUT_PRODUCT    := product
TARGET_COPY_OUT_SYSTEM     := system
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR     := vendor

# File systems
TARGET_USERIMAGES_USE_F2FS := true

BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE    := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE     := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE   := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE     := ext4
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE        := ext4
TARGET_USERIMAGES_USE_EXT4             := true
TARGET_USERIMAGES_USE_F2FS             := true

# Platform
TARGET_BOARD_PLATFORM := mt6897

# Recovery
TARGET_NO_RECOVERY              := true
BOARD_SUPPRESS_SECURE_ERASE     := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_HAS_NO_SELECT_BUTTON      := true
TARGET_RECOVERY_PIXEL_FORMAT    := RGBX_8888
TARGET_RECOVERY_FSTAB           := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab

# Vendor Boot
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE      := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT  := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Treble
BOARD_VNDK_VERSION := current

# Hack
PLATFORM_SECURITY_PATCH      := 2099-12-31
PLATFORM_VERSION             := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
VENDOR_SECURITY_PATCH        := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH          := $(PLATFORM_SECURITY_PATCH)

# Debug
TARGET_USES_LOGD := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
TARGET_RECOVERY_DEVICE_MODULES += strace
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace

# Display
TARGET_SCREEN_WIDTH   := 1080
TARGET_SCREEN_HEIGHT  := 2400
TARGET_SCREEN_DENSITY := 480

# Init
TARGET_INIT_VENDOR_LIB         := libinit_X6873
TARGET_RECOVERY_DEVICE_MODULES := libinit_X6873

# NOTE: All TW_* and OF_* flags have been moved to twrp.mk and fox.mk
# respectively, per fox_14.1 template structure. See device/infinix/X6873/twrp.mk
# for TWRP config and device/infinix/X6873/fox.mk for OrangeFox config.
