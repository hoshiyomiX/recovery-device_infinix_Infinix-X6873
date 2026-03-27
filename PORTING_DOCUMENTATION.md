# TWRP Device Tree for Infinix X6873 (GT 30 Pro)

## Device Information

| Property | Value |
|----------|-------|
| **Device** | Infinix GT 30 Pro |
| **Codename** | X6873 |
| **Platform** | MediaTek MT6897 (Dimensity 8350 Ultimate) |
| **Android** | 15 (AP3A.240905.015.A2) |
| **TranOS** | X6873-15.0.3.116SP01 (xos15.0.3) |
| **TEE** | Trustonic Kinibi |
| **Keystore** | Keymint 3.0 (AIDL) |
| **Gatekeeper** | AIDL V1 |
| **Security Patch** | 2025-04-05 |

## Recovery Tree Structure

```
X6873-TWRP/
├── Android.mk                    # Main Android makefile
├── AndroidProducts.mk            # Product definitions
├── BoardConfig.mk               # Board configuration
├── device.mk                    # Device modules
├── twrp_X6873.mk               # TWRP product makefile
├── vendorsetup.sh              # Build setup script
├── system.prop                 # System properties
│
├── bootctrl/                    # Boot control HAL
│   ├── Android.bp
│   ├── BootControl.cpp
│   ├── BootControl.h
│   ├── boot_control_definition.h
│   ├── boot_region_control.cpp
│   ├── boot_region_control_private.h
│   ├── ufs-mtk-ioctl.h
│   └── ufs-mtk-ioctl-private.h
│
├── init/                        # Init library
│   ├── Android.bp
│   └── init_X6873.cpp
│
├── mtk_plpath_utils/            # MTK partition path utils
│   ├── Android.bp
│   └── mtk_plpath_utils.cpp
│
├── prebuilt/                    # Prebuilt files
│   └── dtb.img
│
└── recovery/root/               # Recovery root filesystem
    ├── first_stage_ramdisk/
    │   └── fstab.mt6897
    ├── lib/modules/             # Kernel modules
    │   ├── mcDrvModule.ko
    │   ├── rpmb.ko
    │   ├── rpmb-mtk.ko
    │   ├── teeperf.ko
    │   ├── bootprof.ko
    │   └── emi.ko
    ├── system/
    │   ├── lib64/               # System libraries
    │   └── etc/
    │       ├── recovery.fstab
    │       ├── twrp.flags
    │       ├── cgroups.json
    │       └── vintf/manifest/
    ├── system_ext/lib64/
    ├── vendor/
    │   ├── bin/hw/              # HAL services
    │   │   ├── android.hardware.security.keymint@3.0-service.trustonic
    │   │   ├── android.hardware.gatekeeper-service.trustonic
    │   │   └── vendor.trustonic.tee@1.1-service
    │   ├── lib64/               # Vendor libraries
    │   ├── app/mcRegistry/      # 34 Trusted Applications
    │   ├── etc/
    │   │   ├── init/*.rc
    │   │   └── vintf/manifest/
    │   └── firmware/
    └── *.rc files               # Init configurations
```

## Build Instructions

### Prerequisites
- Ubuntu 20.04+ or equivalent
- Android build environment setup
- TWRP source tree

### Build Commands

```bash
# Initialize TWRP source
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-15

# Sync source
repo sync

# Clone device tree
git clone https://github.com/your-username/X6873-TWRP.git device/infinix/X6873

# Build
source build/envsetup.sh
lunch twrp_X6873-eng
mka recoveryimage
```

## Crypto Support

This device uses **Trustonic Kinibi** TEE with:

### Keymint 3.0 (AIDL)
- Binary: `vendor/bin/hw/android.hardware.security.keymint@3.0-service.trustonic`
- Interface: `IKeyMintDevice/default`
- Features: Key attestation, remotely provisioned components

### Gatekeeper (AIDL)
- Binary: `vendor/bin/hw/android.hardware.gatekeeper-service.trustonic`
- Interface: `IGatekeeper/default`

### Trustonic TEE Daemon
- Binary: `vendor/bin/mcDriverDaemon`
- Trusted Apps: 34 files in `vendor/app/mcRegistry/`

## Trusted Applications

| UUID | Purpose |
|------|---------|
| 020f...0000 | Utils |
| 031c...0000 | SEC |
| 0507...0000 | Fingerprint (Goodix) |
| 0512...0001 | SEC Key Provisioning |
| 0609...0000 | DRM Key Install |
| 0715...0000 | Keymaster Driver |
| 0717...0000 | Gatekeeper Driver |
| 0721...0000 | Secure Storage |
| 0805...3419 | Widevine |
| 4018...96f9a | Widevine |
| 5020...0000 | DRM HDCP |

## Partition Layout

| Partition | Size | Type |
|-----------|------|------|
| boot | 64MB | boot |
| vendor_boot | 64MB | vendor_boot |
| super | ~9GB | dynamic |
| persist | - | ext4 |
| metadata | - | ext4 |
| userdata | - | f2fs (FBE) |

## Security Features

- **File-Based Encryption (FBE)**: AES-256-XTS with wrapped keys
- **Verified Boot**: AVB with SHA256_RSA4096
- **Keymaster 4.1** (HIDL) for backward compatibility
- **Keymint 3.0** (AIDL) for Android 15

## Kernel Modules

Required modules loaded in recovery:
1. `bootprof.ko` - Boot profiling
2. `emi.ko` - EMI driver
3. `mcDrvModule.ko` - Trustonic kernel interface
4. `rpmb.ko` - RPMB support
5. `rpmb-mtk.ko` - MTK RPMB driver
6. `teeperf.ko` - TEE performance

## Notes

1. This device uses **A/B slots** with virtual A/B OTA
2. No dedicated recovery partition - uses vendor_boot
3. FBE encryption requires persist partition for TEE
4. Keymint 3.0 replaces Keymaster for Android 15

## Credits

- Firmware dump: [rama-firmware-dumps](https://gitgud.io/rama-firmware-dumps/infinix/Infinix-X6873)
- Reference tree: [naden01/tecno_LH8n-TWRP](https://github.com/naden01/tecno_LH8n-TWRP)
- TWRP Team

## License

- Device tree configuration: Apache-2.0
- Extracted blobs: Proprietary
