#
# Copyright (C) 2025 The Android Open Source Project
# Copyright (C) 2025 OrangeFox Device Tree for Infinix X6873
#
# SPDX-License-Identifier: Apache-2.0
#
# Product makefile aligned with X6728 fox_14.1 template pattern.
# Uses fox_* naming convention (OrangeFox standard) and inherits
# fox.mk + twrp.mk separate config files per fox_14.1 template structure.
#

# Inherit from X6873 device
$(call inherit-product, device/infinix/X6873/device.mk)

# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)

# Include TWRP props.
$(call inherit-product, device/infinix/X6873/twrp.mk)

# Include Fox props.
$(call inherit-product, device/infinix/X6873/fox.mk)

# Product Specifics
PRODUCT_DEVICE := X6873
PRODUCT_NAME := fox_X6873
PRODUCT_BRAND := INFINIX
PRODUCT_MODEL := Infinix GT 30 Pro
PRODUCT_MANUFACTURER := Infinix

PRODUCT_GMS_CLIENTID_BASE := android-infinix

# Hide Reflash TWRP & FUSE passthrough
PRODUCT_PROPERTY_OVERRIDES += \
    ro.twrp.vendor_boot=true \
    persist.sys.fuse.passthrough.enable=true
