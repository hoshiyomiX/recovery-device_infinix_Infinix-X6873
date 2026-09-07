#
# Copyright (C) 2025 The Android Open Source Project
# Copyright (C) 2025 TWRP Device Tree for Infinix X6873
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_X6873.mk

# Lunch choices — include both legacy 2-part format (TWRP 12.1 / A12 and earlier)
# and new 3-part format (TWRP 14+/OrangeFox fox_14.1 / A14+ which requires
# <product>-<release>-<variant>). The release qualifier maps to API level:
#   ap1a = Android 12L (API 32)
#   ap2a = Android 13 (API 33)
#   ap3a = Android 14 (API 34)
#   ap4a = Android 15 (API 35)
# Build #53 (commit 7da435b) failed with "Invalid lunch combo: twrp_X6873-eng"
# under OrangeFox fox_14.1 manifest (A14) because A14+ requires the 3-part format.
COMMON_LUNCH_CHOICES := \
    twrp_X6873-eng \
    twrp_X6873-ap2a-eng \
    twrp_X6873-ap3a-eng \
    twrp_X6873-ap4a-eng
