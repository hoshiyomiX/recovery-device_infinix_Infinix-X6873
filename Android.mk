#
# Copyright (C) 2025 The Android Open Source Project
# Copyright (C) 2025 TWRP Device Tree for Infinix X6873
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),X6873)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
