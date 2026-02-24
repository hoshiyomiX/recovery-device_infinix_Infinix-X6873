#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Installs gsi keys into ramdisk, to boot a developer GSI with verified boot.
$(call inherit-product, $(SRC_TARGET_DIR)/product/gsi_keys.mk)

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Enable Virtual A/B OTA
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

ENABLE_VIRTUAL_AB := true
AB_OTA_UPDATER := true

AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    lk \
    odm \
    odm_dlkm \
    product \
    system \
    system_ext \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/mtk_plpath_utils \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh

PRODUCT_PROPERTY_OVERRIDES += ro.twrp.vendor_boot=true

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# API
PRODUCT_SHIPPING_API_LEVEL := 31
PRODUCT_TARGET_VNDK_VERSION := 31

# Boot control HAL
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-mtkimpl \
    android.hardware.boot@1.2-mtkimpl.recovery

PRODUCT_PACKAGES_DEBUG += \
    bootctl

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    fastbootd

# Health Hal
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.keymaster@4.1

# Keystore Hal
PRODUCT_PACKAGES += \
    android.system.keystore2

# MTK plpath utils
PRODUCT_PACKAGES += \
    mtk_plpath_utils \
    mtk_plpath_utils.recovery

# Security
PRODUCT_PACKAGES += \
    android.hardware.security.keymint \
    android.hardware.security.secureclock \
    android.hardware.security.sharedsecret

# Update engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# Additional configs - AIDL Security Libraries for Decryption
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.keymaster@4.1 \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.keymint-V1-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.keymint-V3-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.gatekeeper-V1-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.secureclock-V1-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.sharedsecret-V1-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.rkp-V3-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.keymaster-V4-ndk.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/vendor.trustonic.tee@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/vendor.trustonic.tee@1.1.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/vendor.trustonic.tee.tui@1.0.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libMcClient.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libTEECommon.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.system.keystore2-V1-ndk.so

TARGET_RECOVERY_DEVICE_MODULES += \
    android.hardware.keymaster@4.1 \
    android.hardware.security.keymint-V1-ndk \
    android.hardware.security.keymint-V3-ndk \
    android.hardware.gatekeeper-V1-ndk \
    android.hardware.security.secureclock-V1-ndk \
    android.hardware.security.sharedsecret-V1-ndk \
    android.hardware.security.rkp-V3-ndk \
    android.hardware.keymaster-V4-ndk \
    vendor.trustonic.tee@1.0 \
    vendor.trustonic.tee@1.1 \
    vendor.trustonic.tee.tui@1.0 \
    libMcClient \
    libTEECommon \
    android.system.keystore2-V1-ndk

# Fix Boot
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/root/fstab.mt6897:vendor_ramdisk/first_stage_ramdisk/fstab.mt6897 \
    device/infinix/Infinix-X6873/root/fstab.emmc:vendor_ramdisk/first_stage_ramdisk/fstab.emmc \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/8250_mtk.ko:vendor_ramdisk/lib/modules/8250_mtk.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/adaptive-ts.ko:vendor_ramdisk/lib/modules/adaptive-ts.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/adsp.ko:vendor_ramdisk/lib/modules/adsp.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/aee_aed.ko:vendor_ramdisk/lib/modules/aee_aed.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/aee_hangdet.ko:vendor_ramdisk/lib/modules/aee_hangdet.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/aee_rs.ko:vendor_ramdisk/lib/modules/aee_rs.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/arm_dsu_pmu.ko:vendor_ramdisk/lib/modules/arm_dsu_pmu.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/authon.ko:vendor_ramdisk/lib/modules/authon.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/aw86224_light.ko:vendor_ramdisk/lib/modules/aw86224_light.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/aw9620x.ko:vendor_ramdisk/lib/modules/aw9620x.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/blocktag.ko:vendor_ramdisk/lib/modules/blocktag.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/bootprof.ko:vendor_ramdisk/lib/modules/bootprof.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/bus-parity.ko:vendor_ramdisk/lib/modules/bus-parity.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/cache-parity.ko:vendor_ramdisk/lib/modules/cache-parity.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-bringup.ko:vendor_ramdisk/lib/modules/clk-bringup.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clkbuf.ko:vendor_ramdisk/lib/modules/clkbuf.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-chk-mt6897.ko:vendor_ramdisk/lib/modules/clk-chk-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-common.ko:vendor_ramdisk/lib/modules/clk-common.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-dbg-mt6897.ko:vendor_ramdisk/lib/modules/clk-dbg-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-disable-unused.ko:vendor_ramdisk/lib/modules/clk-disable-unused.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-fmeter-mt6897.ko:vendor_ramdisk/lib/modules/clk-fmeter-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-adsp.ko:vendor_ramdisk/lib/modules/clk-mt6897-adsp.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-bus.ko:vendor_ramdisk/lib/modules/clk-mt6897-bus.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-cam.ko:vendor_ramdisk/lib/modules/clk-mt6897-cam.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-ccu.ko:vendor_ramdisk/lib/modules/clk-mt6897-ccu.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-img.ko:vendor_ramdisk/lib/modules/clk-mt6897-img.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897.ko:vendor_ramdisk/lib/modules/clk-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-mdpsys.ko:vendor_ramdisk/lib/modules/clk-mt6897-mdpsys.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-mmsys.ko:vendor_ramdisk/lib/modules/clk-mt6897-mmsys.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-peri.ko:vendor_ramdisk/lib/modules/clk-mt6897-peri.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-vcodec.ko:vendor_ramdisk/lib/modules/clk-mt6897-vcodec.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/clk-mt6897-vlp.ko:vendor_ramdisk/lib/modules/clk-mt6897-vlp.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/cmdq_helper_inf.ko:vendor_ramdisk/lib/modules/cmdq_helper_inf.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/cmdq-platform-mt6897.ko:vendor_ramdisk/lib/modules/cmdq-platform-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/cqhci.ko:vendor_ramdisk/lib/modules/cqhci.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/dbg_error_flag.ko:vendor_ramdisk/lib/modules/dbg_error_flag.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/dbgtop-drm.ko:vendor_ramdisk/lib/modules/dbgtop-drm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/device-apc-common.ko:vendor_ramdisk/lib/modules/device-apc-common.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/device-apc-mt6897.ko:vendor_ramdisk/lib/modules/device-apc-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/drm_display_helper.ko:vendor_ramdisk/lib/modules/drm_display_helper.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/drm_dma_helper.ko:vendor_ramdisk/lib/modules/drm_dma_helper.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/emi.ko:vendor_ramdisk/lib/modules/emi.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/emi-mpu.ko:vendor_ramdisk/lib/modules/emi-mpu.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/emi-slb.ko:vendor_ramdisk/lib/modules/emi-slb.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/et5904.ko:vendor_ramdisk/lib/modules/et5904.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/extcon-mtk-usb.ko:vendor_ramdisk/lib/modules/extcon-mtk-usb.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/extdev_io_class.ko:vendor_ramdisk/lib/modules/extdev_io_class.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/ffa_v10.ko:vendor_ramdisk/lib/modules/ffa_v10.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/focaltech_ft3683g.ko:vendor_ramdisk/lib/modules/focaltech_ft3683g.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/gpueb.ko:vendor_ramdisk/lib/modules/gpueb.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/haptic_drv_hv.ko:vendor_ramdisk/lib/modules/haptic_drv_hv.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/i2c-mt65xx.ko:vendor_ramdisk/lib/modules/i2c-mt65xx.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/industrialio-triggered-buffer.ko:vendor_ramdisk/lib/modules/industrialio-triggered-buffer.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/iommu_debug.ko:vendor_ramdisk/lib/modules/iommu_debug.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/iommu_secure.ko:vendor_ramdisk/lib/modules/iommu_secure.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/irq-dbg.ko:vendor_ramdisk/lib/modules/irq-dbg.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/isee-ffa.ko:vendor_ramdisk/lib/modules/isee-ffa.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/kfifo_buf.ko:vendor_ramdisk/lib/modules/kfifo_buf.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/last_bus.ko:vendor_ramdisk/lib/modules/last_bus.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/leds-mtk-disp.ko:vendor_ramdisk/lib/modules/leds-mtk-disp.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/leds-mtk.ko:vendor_ramdisk/lib/modules/leds-mtk.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/leds-mtk-pwm.ko:vendor_ramdisk/lib/modules/leds-mtk-pwm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/log_store.ko:vendor_ramdisk/lib/modules/log_store.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/low_latency_sched.ko:vendor_ramdisk/lib/modules/low_latency_sched.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mcDrvModule-ffa.ko:vendor_ramdisk/lib/modules/mcDrvModule-ffa.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mcupm.ko:vendor_ramdisk/lib/modules/mcupm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mdp_drv_mt6897.ko:vendor_ramdisk/lib/modules/mdp_drv_mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mediatek-cpufreq-hw.ko:vendor_ramdisk/lib/modules/mediatek-cpufreq-hw.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mediatek-drm-gateic.ko:vendor_ramdisk/lib/modules/mediatek-drm-gateic.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mediatek-drm.ko:vendor_ramdisk/lib/modules/mediatek-drm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mediatek-drm-panel-drv.ko:vendor_ramdisk/lib/modules/mediatek-drm-panel-drv.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mkp.ko:vendor_ramdisk/lib/modules/mkp.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mmprofile.ko:vendor_ramdisk/lib/modules/mmprofile.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mmqos-common.ko:vendor_ramdisk/lib/modules/mmqos-common.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mmqos-mt6897.ko:vendor_ramdisk/lib/modules/mmqos-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/modules.alias:vendor_ramdisk/lib/modules/modules.alias \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/modules.dep:vendor_ramdisk/lib/modules/modules.dep \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/modules.load:vendor_ramdisk/lib/modules/modules.load \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/modules.load.recovery:vendor_ramdisk/lib/modules/modules.load.recovery \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/modules.softdep:vendor_ramdisk/lib/modules/modules.softdep \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/monitor_hang.ko:vendor_ramdisk/lib/modules/monitor_hang.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mrdump.ko:vendor_ramdisk/lib/modules/mrdump.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6315-regulator.ko:vendor_ramdisk/lib/modules/mt6315-regulator.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6338-core.ko:vendor_ramdisk/lib/modules/mt6338-core.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6363-regulator.ko:vendor_ramdisk/lib/modules/mt6363-regulator.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6368-regulator.ko:vendor_ramdisk/lib/modules/mt6368-regulator.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6375-adc.ko:vendor_ramdisk/lib/modules/mt6375-adc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6375-auxadc.ko:vendor_ramdisk/lib/modules/mt6375-auxadc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6375-battery.ko:vendor_ramdisk/lib/modules/mt6375-battery.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6375-charger.ko:vendor_ramdisk/lib/modules/mt6375-charger.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6375.ko:vendor_ramdisk/lib/modules/mt6375.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6685-audclk.ko:vendor_ramdisk/lib/modules/mt6685-audclk.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6685-core.ko:vendor_ramdisk/lib/modules/mt6685-core.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mt6897_dcm.ko:vendor_ramdisk/lib/modules/mt6897_dcm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-afe-external.ko:vendor_ramdisk/lib/modules/mtk-afe-external.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_battery_oc_throttling.ko:vendor_ramdisk/lib/modules/mtk_battery_oc_throttling.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_bp_thl.ko:vendor_ramdisk/lib/modules/mtk_bp_thl.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-cmdq-drv-ext.ko:vendor_ramdisk/lib/modules/mtk-cmdq-drv-ext.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_dcm.ko:vendor_ramdisk/lib/modules/mtk_dcm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_disp_notify.ko:vendor_ramdisk/lib/modules/mtk_disp_notify.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_dramc.ko:vendor_ramdisk/lib/modules/mtk_dramc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-dvfsrc-devfreq.ko:vendor_ramdisk/lib/modules/mtk-dvfsrc-devfreq.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-dvfsrc-helper.ko:vendor_ramdisk/lib/modules/mtk-dvfsrc-helper.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-dvfsrc.ko:vendor_ramdisk/lib/modules/mtk-dvfsrc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-dvfsrc-regulator.ko:vendor_ramdisk/lib/modules/mtk-dvfsrc-regulator.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_dynamic_loading_throttling.ko:vendor_ramdisk/lib/modules/mtk_dynamic_loading_throttling.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-emi.ko:vendor_ramdisk/lib/modules/mtk-emi.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_gpufreq_wrapper.ko:vendor_ramdisk/lib/modules/mtk_gpufreq_wrapper.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_gpu_hal.ko:vendor_ramdisk/lib/modules/mtk_gpu_hal.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-icc-core.ko:vendor_ramdisk/lib/modules/mtk-icc-core.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_iommu.ko:vendor_ramdisk/lib/modules/mtk_iommu.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-kpd.ko:vendor_ramdisk/lib/modules/mtk-kpd.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_low_battery_throttling.ko:vendor_ramdisk/lib/modules/mtk_low_battery_throttling.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mbox.ko:vendor_ramdisk/lib/modules/mtk-mbox.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mbox-mailbox.ko:vendor_ramdisk/lib/modules/mtk-mbox-mailbox.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_mdpm.ko:vendor_ramdisk/lib/modules/mtk_mdpm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mmc-dbg.ko:vendor_ramdisk/lib/modules/mtk-mmc-dbg.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mmc.ko:vendor_ramdisk/lib/modules/mtk-mmc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mmdvfs-debug.ko:vendor_ramdisk/lib/modules/mtk-mmdvfs-debug.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mmdvfs-ftrace.ko:vendor_ramdisk/lib/modules/mtk-mmdvfs-ftrace.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mmdvfs.ko:vendor_ramdisk/lib/modules/mtk-mmdvfs.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mmdvfs-v3.ko:vendor_ramdisk/lib/modules/mtk-mmdvfs-v3.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mmdvfs-v3-start.ko:vendor_ramdisk/lib/modules/mtk-mmdvfs-v3-start.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mminfra-debug.ko:vendor_ramdisk/lib/modules/mtk-mminfra-debug.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mminfra-imax.ko:vendor_ramdisk/lib/modules/mtk-mminfra-imax.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mml.ko:vendor_ramdisk/lib/modules/mtk-mml.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-mml-mt6897.ko:vendor_ramdisk/lib/modules/mtk-mml-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_panel_ext.ko:vendor_ramdisk/lib/modules/mtk_panel_ext.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_pbm.ko:vendor_ramdisk/lib/modules/mtk_pbm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-pm-domain-disable-unused.ko:vendor_ramdisk/lib/modules/mtk-pm-domain-disable-unused.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-pmic-keys.ko:vendor_ramdisk/lib/modules/mtk-pmic-keys.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-pmic-wrap.ko:vendor_ramdisk/lib/modules/mtk-pmic-wrap.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_printk_ctrl.ko:vendor_ramdisk/lib/modules/mtk_printk_ctrl.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_rpmsg_mbox.ko:vendor_ramdisk/lib/modules/mtk_rpmsg_mbox.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-scpsys-bringup.ko:vendor_ramdisk/lib/modules/mtk-scpsys-bringup.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-scpsys.ko:vendor_ramdisk/lib/modules/mtk-scpsys.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-scpsys-mt6897.ko:vendor_ramdisk/lib/modules/mtk-scpsys-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_slbc.ko:vendor_ramdisk/lib/modules/mtk_slbc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-smi-dbg.ko:vendor_ramdisk/lib/modules/mtk-smi-dbg.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-smi.ko:vendor_ramdisk/lib/modules/mtk-smi.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-socinfo.ko:vendor_ramdisk/lib/modules/mtk-socinfo.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-spmi-pmic-adc.ko:vendor_ramdisk/lib/modules/mtk-spmi-pmic-adc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-spmi-pmic.ko:vendor_ramdisk/lib/modules/mtk-spmi-pmic.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-swpm-perf-arm-pmu.ko:vendor_ramdisk/lib/modules/mtk-swpm-perf-arm-pmu.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_sync.ko:vendor_ramdisk/lib/modules/mtk_sync.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_tinysys_ipi.ko:vendor_ramdisk/lib/modules/mtk_tinysys_ipi.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-uart-apdma.ko:vendor_ramdisk/lib/modules/mtk-uart-apdma.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk-vmm-spm.ko:vendor_ramdisk/lib/modules/mtk-vmm-spm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtk_wdt.ko:vendor_ramdisk/lib/modules/mtk_wdt.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mtu3.ko:vendor_ramdisk/lib/modules/mtu3.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/mux_switch.ko:vendor_ramdisk/lib/modules/mux_switch.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/nfc_i2c.ko:vendor_ramdisk/lib/modules/nfc_i2c.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/nvmem_mtk-devinfo.ko:vendor_ramdisk/lib/modules/nvmem_mtk-devinfo.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pca_tfcp_ta.ko:vendor_ramdisk/lib/modules/pca_tfcp_ta.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pd-chk-mt6897.ko:vendor_ramdisk/lib/modules/pd-chk-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pd_dbg_info.ko:vendor_ramdisk/lib/modules/pd_dbg_info.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/phy-mtk-ufs.ko:vendor_ramdisk/lib/modules/phy-mtk-ufs.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/phy-mtk-xsphy.ko:vendor_ramdisk/lib/modules/phy-mtk-xsphy.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pidmap.ko:vendor_ramdisk/lib/modules/pidmap.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pinctrl-mt6897.ko:vendor_ramdisk/lib/modules/pinctrl-mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pinctrl-mtk-common-v2_debug.ko:vendor_ramdisk/lib/modules/pinctrl-mtk-common-v2_debug.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pinctrl-mtk-v2.ko:vendor_ramdisk/lib/modules/pinctrl-mtk-v2.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pmic_lbat_service.ko:vendor_ramdisk/lib/modules/pmic_lbat_service.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pmic_lvsys_notify.ko:vendor_ramdisk/lib/modules/pmic_lvsys_notify.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/ps5170.ko:vendor_ramdisk/lib/modules/ps5170.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/pwm-mtk-disp.ko:vendor_ramdisk/lib/modules/pwm-mtk-disp.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/reboot-mode.ko:vendor_ramdisk/lib/modules/reboot-mode.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/reset-ti-syscon.ko:vendor_ramdisk/lib/modules/reset-ti-syscon.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/rpmb.ko:vendor_ramdisk/lib/modules/rpmb.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/rpmb-mtk.ko:vendor_ramdisk/lib/modules/rpmb-mtk.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/rt4831a_drv.ko:vendor_ramdisk/lib/modules/rt4831a_drv.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/rt5133-regulator.ko:vendor_ramdisk/lib/modules/rt5133-regulator.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/rt6160-regulator.ko:vendor_ramdisk/lib/modules/rt6160-regulator.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/rtc-mt6685.ko:vendor_ramdisk/lib/modules/rtc-mt6685.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/rt_pd_manager.ko:vendor_ramdisk/lib/modules/rt_pd_manager.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/sec.ko:vendor_ramdisk/lib/modules/sec.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/sec-rng.ko:vendor_ramdisk/lib/modules/sec-rng.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/slbc_ipi.ko:vendor_ramdisk/lib/modules/slbc_ipi.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/slbc_mt6897.ko:vendor_ramdisk/lib/modules/slbc_mt6897.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/slbc_trace.ko:vendor_ramdisk/lib/modules/slbc_trace.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/smpu-hook-v1.ko:vendor_ramdisk/lib/modules/smpu-hook-v1.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/smpu.ko:vendor_ramdisk/lib/modules/smpu.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/spi-mt65xx.ko:vendor_ramdisk/lib/modules/spi-mt65xx.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/spmi-mtk-mpu.ko:vendor_ramdisk/lib/modules/spmi-mtk-mpu.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/spmi-mtk-pmif.ko:vendor_ramdisk/lib/modules/spmi-mtk-pmif.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/syscon-reboot-mode.ko:vendor_ramdisk/lib/modules/syscon-reboot-mode.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/system_heap.ko:vendor_ramdisk/lib/modules/system_heap.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_adapter_class.ko:vendor_ramdisk/lib/modules/tc_adapter_class.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_algorithm_class.ko:vendor_ramdisk/lib/modules/tc_algorithm_class.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_ambient_temp_det.ko:vendor_ramdisk/lib/modules/tc_ambient_temp_det.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_audio.ko:vendor_ramdisk/lib/modules/tc_audio.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_auto_test.ko:vendor_ramdisk/lib/modules/tc_auto_test.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_charger_class.ko:vendor_ramdisk/lib/modules/tc_charger_class.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_charger_framework.ko:vendor_ramdisk/lib/modules/tc_charger_framework.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_chg_type_det.ko:vendor_ramdisk/lib/modules/tc_chg_type_det.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_common_class.ko:vendor_ramdisk/lib/modules/tc_common_class.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_gauge.ko:vendor_ramdisk/lib/modules/tc_gauge.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_hl7139a.ko:vendor_ramdisk/lib/modules/tc_hl7139a.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_hvdcp20_algo.ko:vendor_ramdisk/lib/modules/tc_hvdcp20_algo.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_lcd_notify.ko:vendor_ramdisk/lib/modules/tc_lcd_notify.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_misc_intf.ko:vendor_ramdisk/lib/modules/tc_misc_intf.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_otg_ctrl.ko:vendor_ramdisk/lib/modules/tc_otg_ctrl.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tcpc_class.ko:vendor_ramdisk/lib/modules/tcpc_class.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tcpci_late_sync.ko:vendor_ramdisk/lib/modules/tcpci_late_sync.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tcpc_mt6375.ko:vendor_ramdisk/lib/modules/tcpc_mt6375.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_pd_adapter.ko:vendor_ramdisk/lib/modules/tc_pd_adapter.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_pd_algo.ko:vendor_ramdisk/lib/modules/tc_pd_algo.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_pep20.ko:vendor_ramdisk/lib/modules/tc_pep20.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_pep50.ko:vendor_ramdisk/lib/modules/tc_pep50.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_pid_chg_algo.ko:vendor_ramdisk/lib/modules/tc_pid_chg_algo.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_pmic.ko:vendor_ramdisk/lib/modules/tc_pmic.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_port_burning.ko:vendor_ramdisk/lib/modules/tc_port_burning.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_sc8548_charger.ko:vendor_ramdisk/lib/modules/tc_sc8548_charger.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_ta_class.ko:vendor_ramdisk/lib/modules/tc_ta_class.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_tc30_algo.ko:vendor_ramdisk/lib/modules/tc_tc30_algo.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_tcpc.ko:vendor_ramdisk/lib/modules/tc_tcpc.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_temp_forecast.ko:vendor_ramdisk/lib/modules/tc_temp_forecast.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tc_tfcp_ta.ko:vendor_ramdisk/lib/modules/tc_tfcp_ta.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/teeperf.ko:vendor_ramdisk/lib/modules/teeperf.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/thd.ko:vendor_ramdisk/lib/modules/thd.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/thermal_interface.ko:vendor_ramdisk/lib/modules/thermal_interface.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/timer-mediatek.ko:vendor_ramdisk/lib/modules/timer-mediatek.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tinysys-scmi.ko:vendor_ramdisk/lib/modules/tinysys-scmi.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tkv.ko:vendor_ramdisk/lib/modules/tkv.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tkv_recovery.ko:vendor_ramdisk/lib/modules/tkv_recovery.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tnek.ko:vendor_ramdisk/lib/modules/tnek.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_block.ko:vendor_ramdisk/lib/modules/tran_block.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_charge_transfer.ko:vendor_ramdisk/lib/modules/tran_charge_transfer.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_cps4021.ko:vendor_ramdisk/lib/modules/tran_cps4021.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_expand_key.ko:vendor_ramdisk/lib/modules/tran_expand_key.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_perf_util.ko:vendor_ramdisk/lib/modules/tran_perf_util.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran-proc-bootdevice-mod.ko:vendor_ramdisk/lib/modules/tran-proc-bootdevice-mod.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_rhi.ko:vendor_ramdisk/lib/modules/tran_rhi.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_scsi_mod.ko:vendor_ramdisk/lib/modules/tran_scsi_mod.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_sd_mod.ko:vendor_ramdisk/lib/modules/tran_sd_mod.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/transsion_tranlog.ko:vendor_ramdisk/lib/modules/transsion_tranlog.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran-ufshcd-core.ko:vendor_ramdisk/lib/modules/tran-ufshcd-core.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran-ufshcd-pltfrm.ko:vendor_ramdisk/lib/modules/tran-ufshcd-pltfrm.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_usb_ctrl.ko:vendor_ramdisk/lib/modules/tran_usb_ctrl.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_wireless_manager.ko:vendor_ramdisk/lib/modules/tran_wireless_manager.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/tran_wireless_ta.ko:vendor_ramdisk/lib/modules/tran_wireless_ta.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/uarthub_drv.ko:vendor_ramdisk/lib/modules/uarthub_drv.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/ufs-mediatek-dbg.ko:vendor_ramdisk/lib/modules/ufs-mediatek-dbg.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/ufs-mediatek-mod.ko:vendor_ramdisk/lib/modules/ufs-mediatek-mod.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/usb_boost.ko:vendor_ramdisk/lib/modules/usb_boost.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/usb_dp_selector.ko:vendor_ramdisk/lib/modules/usb_dp_selector.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/usb_meta.ko:vendor_ramdisk/lib/modules/usb_meta.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/vcp_status.ko:vendor_ramdisk/lib/modules/vcp_status.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/vtdr6126a_fhdp1224x2720_dsi_vdo_tm_144hz_x6873.ko:vendor_ramdisk/lib/modules/vtdr6126a_fhdp1224x2720_dsi_vdo_tm_144hz_x6873.ko \
    device/infinix/Infinix-X6873/recovery/root/lib/modules/xhci-mtk-hcd-v2.ko:vendor_ramdisk/lib/modules/xhci-mtk-hcd-v2.ko

# Copy AIDL Security Libraries for Decryption
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.security.keymint-V3-ndk.so:vendor/lib64/android.hardware.security.keymint-V3-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.security.keymint-V1-ndk.so:vendor/lib64/android.hardware.security.keymint-V1-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.gatekeeper-V1-ndk.so:vendor/lib64/android.hardware.gatekeeper-V1-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.security.secureclock-V1-ndk.so:vendor/lib64/android.hardware.security.secureclock-V1-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.security.sharedsecret-V1-ndk.so:vendor/lib64/android.hardware.security.sharedsecret-V1-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.security.rkp-V3-ndk.so:vendor/lib64/android.hardware.security.rkp-V3-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.keymaster-V4-ndk.so:vendor/lib64/android.hardware.keymaster-V4-ndk.so

# Copy Keymint Service Binaries
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/android.hardware.security.keymint@3.0-service.trustonic:vendor/bin/hw/android.hardware.security.keymint@3.0-service.trustonic \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/android.hardware.gatekeeper-service.trustonic:vendor/bin/hw/android.hardware.gatekeeper-service.trustonic \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/vendor.trustonic.tee@1.1-service:vendor/bin/hw/vendor.trustonic.tee@1.1-service \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/mcDriverDaemon:vendor/bin/mcDriverDaemon

# Copy Trustonic TEE Libraries
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.trustonic.tee@1.0.so:vendor/lib64/vendor.trustonic.tee@1.0.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.trustonic.tee@1.1.so:vendor/lib64/vendor.trustonic.tee@1.1.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.trustonic.tee.tui@1.0.so:vendor/lib64/vendor.trustonic.tee.tui@1.0.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libTEECommon.so:vendor/lib64/libTEECommon.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libMcClient.so:vendor/lib64/libMcClient.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.system.keystore2-V1-ndk.so:vendor/lib64/android.system.keystore2-V1-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.gatekeeper@1.0.so:vendor/lib64/android.hardware.gatekeeper@1.0.so

# Copy system_ext TEE Libraries
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/system_ext/lib64/libteeservice_client.trustonic.so:system_ext/lib64/libteeservice_client.trustonic.so \
    device/infinix/Infinix-X6873/recovery/root/system_ext/lib64/libTeeClient.so:system_ext/lib64/libTeeClient.so

# Copy mcRegistry Trustlet Files for TEE
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/020f0000000000000000000000000000.drbin:vendor/app/mcRegistry/020f0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/020b0000000000000000000000000000.drbin:vendor/app/mcRegistry/020b0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/030b0000000000000000000000000000.drbin:vendor/app/mcRegistry/030b0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/030c0000000000000000000000000000.drbin:vendor/app/mcRegistry/030c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/03100000000000000000000000000000.drbin:vendor/app/mcRegistry/03100000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/031c0000000000000000000000000000.drbin:vendor/app/mcRegistry/031c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/032c0000000000000000000000000000.drbin:vendor/app/mcRegistry/032c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/033c0000000000000000000000000000.drbin:vendor/app/mcRegistry/033c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/034c0000000000000000000000000000.drbin:vendor/app/mcRegistry/034c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/035c0000000000000000000000000000.drbin:vendor/app/mcRegistry/035c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/036c0000000000000000000000000000.drbin:vendor/app/mcRegistry/036c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/037c0000000000000000000000000000.drbin:vendor/app/mcRegistry/037c0000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/05070000000000000000000000000000.drbin:vendor/app/mcRegistry/05070000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/05120000000000000000000000000000.drbin:vendor/app/mcRegistry/05120000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/05120000000000000000000000000001.drbin:vendor/app/mcRegistry/05120000000000000000000000000001.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/05160000000000000000000000000000.drbin:vendor/app/mcRegistry/05160000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/06090000000000000000000000000000.drbin:vendor/app/mcRegistry/06090000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/07150000000000000000000000000000.drbin:vendor/app/mcRegistry/07150000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/07170000000000000000000000000000.drbin:vendor/app/mcRegistry/07170000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/07210000000000000000000000000000.drbin:vendor/app/mcRegistry/07210000000000000000000000000000.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/08050000000000000000000000003419.drbin:vendor/app/mcRegistry/08050000000000000000000000003419.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/40188311faf343488db888ad39496f9a.drbin:vendor/app/mcRegistry/40188311faf343488db888ad39496f9a.drbin \
    device/infinix/Infinix-X6873/recovery/root/vendor/app/mcRegistry/5020170115e016302017012521300000.drbin:vendor/app/mcRegistry/5020170115e016302017012521300000.drbin
# Copy kmsetkey for Keymint Keybox Support
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/kmsetkey_ca.trustonic:vendor/bin/kmsetkey_ca.trustonic \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libkmsetkey.so:vendor/lib64/libkmsetkey.so

# Copy Transsion Security Service Binaries
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/vendor.transsion.hardware.security.deviceauthen@2.0-service:vendor/bin/hw/vendor.transsion.hardware.security.deviceauthen@2.0-service \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/vendor.transsion.hardware.security.hap@1.0-service:vendor/bin/hw/vendor.transsion.hardware.security.hap@1.0-service \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/vendor.transsion.hardware.security.rpmbservice@1.0-service:vendor/bin/hw/vendor.transsion.hardware.security.rpmbservice@1.0-service \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/vendor.transsion.hardware.security.trancriticalparavfy@1.0-service:vendor/bin/hw/vendor.transsion.hardware.security.trancriticalparavfy@1.0-service

# Copy Transsion Security Libraries
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.transsion.hardware.security.deviceauthen@2.0.so:vendor/lib64/vendor.transsion.hardware.security.deviceauthen@2.0.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.transsion.hardware.security.hap-V1-ndk.so:vendor/lib64/vendor.transsion.hardware.security.hap-V1-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.transsion.hardware.security.rpmbservice@1.0.so:vendor/lib64/vendor.transsion.hardware.security.rpmbservice@1.0.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.transsion.hardware.security.trancriticalparavfy@1.0.so:vendor/lib64/vendor.transsion.hardware.security.trancriticalparavfy@1.0.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libdeviceauthen.so:vendor/lib64/libdeviceauthen.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libhyperion_hap_ca.so:vendor/lib64/libhyperion_hap_ca.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/hw/paytrigger.trustonic.so:vendor/lib64/hw/paytrigger.trustonic.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libsecure_load.so:vendor/lib64/libsecure_load.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libtran_critical_para.so:vendor/lib64/libtran_critical_para.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/hw/gatekeeper.trustonic.so:vendor/lib64/hw/gatekeeper.trustonic.so

# Copy kmsetkey binary
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/kmsetkey_ca.trustonic:vendor/bin/kmsetkey_ca.trustonic \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libkmsetkey.so:vendor/lib64/libkmsetkey.so

# Copy USB HAL Binaries for OTG support
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/android.hardware.usb-aidl-service.mediatekv1.0:vendor/bin/hw/android.hardware.usb-aidl-service.mediatekv1.0 \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/android.hardware.usb.gadget-aidl-service.mediatekv1.0:vendor/bin/hw/android.hardware.usb.gadget-aidl-service.mediatekv1.0

# Copy USB HAL Libraries
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.usb-V1-ndk.so:vendor/lib64/android.hardware.usb-V1-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.usb.gadget-V1-ndk.so:vendor/lib64/android.hardware.usb.gadget-V1-ndk.so

# Copy Vibrator HAL Binary
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/bin/hw/android.hardware.vibrator-service.mediatek:vendor/bin/hw/android.hardware.vibrator-service.mediatek

# Copy Vibrator HAL Libraries
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/android.hardware.vibrator-V2-ndk.so:vendor/lib64/android.hardware.vibrator-V2-ndk.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/hw/vibrator.default.so:vendor/lib64/hw/vibrator.default.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libaacvibrator.so:vendor/lib64/libaacvibrator.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/libvibratorutils.so:vendor/lib64/libvibratorutils.so \
    device/infinix/Infinix-X6873/recovery/root/vendor/lib64/vendor.aac.hardware.richtap.vibrator-V1-ndk.so:vendor/lib64/vendor.aac.hardware.richtap.vibrator-V1-ndk.so

# Copy Vibrator Config
PRODUCT_COPY_FILES += \
    device/infinix/Infinix-X6873/recovery/root/vendor/etc/aac_richtap.config:vendor/etc/aac_richtap.config
