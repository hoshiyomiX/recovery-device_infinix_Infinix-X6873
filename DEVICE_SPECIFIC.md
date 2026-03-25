# Device-Specific Information for Infinix X6873

This document tracks all device-specific information extracted from the X6873 firmware dump
that MUST NOT be overwritten by reference tree structure.

## Device Identity

| Property | Value | Source |
|----------|-------|--------|
| Device | Infinix GT 30 Pro | Firmware |
| Codename | X6873 | Firmware |
| Platform | MT6897 (Dimensity 8350 Ultimate) | Firmware |
| Android | 15 (AP3A.240905.015.A2) | Firmware |
| TranOS | X6873-15.0.3.116SP01 | Firmware |

## TEE Configuration (Trustonic Kinibi)

### Service Binaries (from firmware)
- `vendor/bin/hw/android.hardware.security.keymint@3.0-service.trustonic` (137KB)
- `vendor/bin/hw/android.hardware.gatekeeper-service.trustonic` (29KB)
- `vendor/bin/hw/vendor.trustonic.tee@1.1-service` (82KB)
- `vendor/bin/mcDriverDaemon`

### Trusted Applications (34 files from firmware mcRegistry)
| UUID | Type | Purpose |
|------|------|---------|
| 020f...0000 | drbin/tlbin | Utils |
| 031c...0000 | drbin/tlbin | SEC |
| 0506...0000 | tabin | Unknown |
| 0507...0000 | drbin/tlbin | Fingerprint (Goodix) |
| 0509...0000 | tabin | Unknown |
| 0512...0000 | drbin/tlbin | SEC Key Provisioning |
| 0512...0001 | drbin/tlbin | SEC Key Provisioning Alt |
| 0609...0000 | drbin/tlbin | DRM Key Install |
| 0614...0000 | tabin | Unknown |
| 0706...004d | tlbin | Video Decoder |
| 0706...0000 | tlbin | Video Decoder Alt |
| 0715...0000 | drbin/tlbin | Keymaster Driver |
| 0717...0000 | drbin/tlbin | Gatekeeper Driver |
| 0721...0000 | drbin/tlbin | Secure Storage |
| 0804...3419 | tabin | Widevine |
| 0805...3419 | drbin/tlbin | Widevine |
| 0811...0000 | tabin | Unknown |
| 4018...96f9a | drbin/tlbin | Widevine |
| 5020...0000 | drbin/tlbin | DRM HDCP Common |
| abcd...539e | tabin | Unknown |
| ce45...3050 | tabin | Unknown |
| df1e...7e7d | tabin | Unknown |
| e97c...539e | tabin | Unknown |
| 9e41...369f | tabin | Unknown |

### mcDriverDaemon Load Parameters (11 drbin files)
These are loaded by mcDriverDaemon at startup:
1. 06090000000000000000000000000000.drbin
2. 020f0000000000000000000000000000.drbin
3. 05120000000000000000000000000001.drbin
4. 05070000000000000000000000000000.drbin
5. 031c0000000000000000000000000000.drbin
6. 07150000000000000000000000000000.drbin
7. 07170000000000000000000000000000.drbin
8. 07210000000000000000000000000000.drbin
9. 08050000000000000000000000003419.drbin
10. 40188311faf343488db888ad39496f9a.drbin
11. 5020170115e016302017012521300000.drbin

## Vendor Libraries (from firmware)

### vendor/lib64/
- android.hardware.gatekeeper-V1-ndk.so (AIDL)
- android.hardware.keymaster-V4-ndk.so
- android.hardware.security.keymint-V1-ndk.so (AIDL)
- android.hardware.security.keymint-V3-ndk.so (AIDL Keymint 3.0)
- libMcClient.so (Trustonic client)
- libTEECommon.so (TEE common)
- libion.so / libion_mtk.so (ION memory)
- libkeymaster4.so / libkeymaster41.so
- libthha.so (TEE HAL)
- vendor.trustonic.tee@1.0.so
- vendor.trustonic.tee@1.1.so
- vendor.trustonic.tee.tui@1.0.so

### vendor/lib64/hw/
- android.hardware.gatekeeper@1.0-impl.trustonic.so
- android.hardware.keymaster@4.0-impl.trustonic.so
- android.hardware.keymaster@4.1-impl.trustonic.so

### system/lib64/ (20 files)
AIDL and HIDL libraries for Keymint 3.0 support

### system_ext/lib64/
- libteeservice_client.trustonic.so

## Kernel Modules (243 from firmware)

Platform-specific modules for MT6897:
- clk-mt6897*.ko (clock drivers)
- pinctrl-mt6897.ko (pin control)
- mtk-scpsys-mt6897.ko (power management)
- mmqos-mt6897.ko (memory QoS)
- slbc_mt6897.ko (slave controller)
- mt6897_dcm.ko (dynamic clock management)
- cmdq-platform-mt6897.ko (command queue)
- pd-chk-mt6897.ko (power domain check)
- And many more...

## Firmware Files (19 files from firmware)

### Haptic
- aw8622x_haptic.bin
- aw8622x_osc_rtp_12K_10s.bin
- aw8622x_rtp.bin
- aw8624_haptic.bin
- aw8624_osc_rtp_24K_5s.bin
- aw8624_rtp.bin
- haptic_config.bin

### Capacitive Touch
- aw9620x_bt_0.bin / aw9620x_bt_1.bin
- aw9620x_fw_0.bin / aw9620x_fw_1.bin
- aw9620x_reg_0.bin / aw9620x_reg_1.bin

### Connectivity
- BT_FW.cfg
- connfem.cfg
- conninfra.cfg

### Charging
- cps4021_bootloader.bin
- cps4021_fw.bin

### Touchscreen
- focaltech_ts_fw.bin

## AIDL vs HIDL (Android 15 Specific)

X6873 uses AIDL interfaces (Android 15), NOT HIDL:
- Keymint 3.0 (AIDL) - NOT Keymaster 4.1 (HIDL)
- Gatekeeper V1 (AIDL) - NOT Gatekeeper 1.0 (HIDL)

Reference tree (LH8n, Android 12) uses HIDL interfaces.

## VINTF Manifests (from firmware)

- android.hardware.security.keymint-service.trustonic.xml (AIDL V3)
- android.hardware.gatekeeper-service.trustonic.xml (AIDL V1)

## Init RC Files (device-specific)

### vendor/etc/init/
- android.hardware.gatekeeper-service.trustonic.rc
- android.hardware.security.keymint@3.0-service.trustonic.rc
- tee.rc
- vendor.trustonic.tee@1.1-service.rc

## File Count Summary

| Category | Count |
|----------|-------|
| Kernel Modules (.ko) | 243 |
| mcRegistry Files | 34 |
| Vendor Libraries | 16 |
| System Libraries | 20 |
| Firmware Files | 19 |
| Init RC Files | 4 |

## DO NOT REPLACE

The following must NEVER be copied from reference tree:
1. Any *.ko files (kernel modules)
2. Any mcRegistry/* files (trusted applications)
3. Any vendor/bin/hw/* files (HAL services)
4. Any vendor/lib64/* files (vendor libraries)
5. Any vendor/firmware/* files (firmware blobs)
6. Any system/lib64/* files (system libraries)
7. Service names in init.rc files
8. drbin load parameters in init.tee.rc
