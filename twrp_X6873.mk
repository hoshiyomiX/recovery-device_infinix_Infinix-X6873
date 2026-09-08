#
# Copyright (C) 2025 The Android Open Source Project
# Copyright (C) 2025 TWRP Device Tree for Infinix X6873
#
# SPDX-License-Identifier: Apache-2.0
#
# Product makefile aligned with X6728 fox_14.1 template pattern.
# Previous version inherited core_64_bit + full_base_telephony + gsi_keys +
# emulated_storage from tecno_LH8n reference (AOSP 14-based), but OrangeFox
# fox_14.1 is AOSP 13-based and does NOT have gsi_keys.mk or emulated_storage.mk.
# Build #55 failed: "build/make/target/product/gsi_keys.mk does not exist"
# Fix: remove all 4 AOSP 14+ inherit-product calls, match fox_14.1 minimal pattern.
#

# Inherit from X6873 device
$(call inherit-product, device/infinix/X6873/device.mk)

# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_DEVICE := X6873
PRODUCT_NAME := twrp_X6873
PRODUCT_BRAND := INFINIX
PRODUCT_MODEL := Infinix GT 30 Pro
PRODUCT_MANUFACTURER := Infinix

PRODUCT_GMS_CLIENTID_BASE := android-infinix

# Hide Reflash TWRP & FUSE passthrough
PRODUCT_PROPERTY_OVERRIDES += \
    ro.twrp.vendor_boot=true \
    persist.sys.fuse.passthrough.enable=true
