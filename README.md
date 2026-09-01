## Infinix GT 30 Pro (_X6873_)
## Recovery device tree (TWRP, PBRP, OrangeFox, SHRP)

## Device specifications

Device                  | Infinix GT 30 Pro
-----------------------:|:-----------------------------------------
SoC                     | Mediatek Dimensity 8350 Ultimate (4 nm)
CPU                     | Octa-core (1x3.35 GHz Cortex-A715 & 3x3.20 GHz Cortex-A715 & 4x2.20 GHz Cortex-A510)
GPU                     | Mali G615-MC6
Memory                  | 8 / 12 GB RAM
Storage                 | 256 / 512 GB (UFS 4.0)
MicroSD                 | None
Shipped Android Version | 15.0
Battery                 | Non-removable 5500 mAh
Display                 | 1224 x 2720 pixels (~440 ppi density), AMOLED 6.78", 144Hz
Camera                  | 108 MP (wide), 8 MP (ultrawide); 13 MP (front)

## Device picture

![ Infinix GT 30 Pro ](https://fdn2.gsmarena.com/vv/pics/infinix/infinix-gt30-pro-1.jpg "Infinix GT 30 Pro")

## Features

Works:

- [ ] Display
- [ ] Touch
- [ ] ADB
- [ ] Fasbootd
- [ ] Flashing
- [ ] MTP
- [ ] Sideload
- [ ] Decryption (re-enabled per X6728 template — testing needed)
- [ ] USB OTG
- [ ] Vibrator

## Caution

> **⚠️ WARNING: This recovery tree is a WORK IN PROGRESS port and may not work as intended!**

- **Template Base**: This recovery tree structure was ported from [Andrikurn/twrp_device_infinix_X6728](https://github.com/Andrikurn/twrp_device_infinix_X6728) and adapted for X6873 hardware (MT6897, UFS 4.0). The X6728 tree provides the TWRP template scaffolding (cgroup infrastructure, VINTF compatibility matrices, fstab.postinstall, patch system, vendorsetup auto-patcher).

- **Original Reference**: The previous structure was ported from [tecno_LH8n-TWRP](https://github.com/naden01/tecno_LH8n-TWRP). Some files (init.recovery.mt6897.rc, init.custom.rc, fstab.mt6897) still reflect that heritage.

- **Outdated Blobs**: The blobs used in this recovery tree are extracted from firmware dump `X6873-15.0.3.116SP01(0P001PF001AZ)`. Supplementary blobs (paytrigger HAL, tranlog libs, AIDL keystore2/keymint V4/secureclock/sharedsecret/health NDK, etc.) are fetched from the newer firmware dump [rama-firmware-dumps/Infinix-X6873](https://gitlab.com/rama-firmware-dumps/infinix/Infinix-X6873) at branch `X6873-16.2.0.150SP12(OP003PF001AZ)`. See `BLOB_MANIFEST.md` for the full list of fetched blobs.

- **Decryption Re-enabled**: FBE crypto flags are now enabled (mirroring the X6728 template `Andrikurn/twrp_device_infinix_X6728`, which has working FBE decryption on the same MediaTek + Trustonic TEE family). Previously disabled due to splash-logo stuck issue; re-enabling per maintainer decision. If splash-stuck recurs on X6873 specifically (mt6897 UFS vs X6728 mt6768 eMMC), the disabled state can be restored by commenting out the 5 crypto flags in `BoardConfig.mk`.

## Technical Notes: KeyMint V3 Challenge

### Current State of FBE Decryption with KeyMint 3.0

**Update (2026-09-01)**: FBE crypto is now **enabled** in this tree, mirroring the X6728 template which has demonstrated working FBE decryption on the same MediaTek + Trustonic TEE family. The original concern about KeyMint V3 + Trustonic not being supported from source appears to be device-specific rather than family-wide — the X6728 tree (Helio G81 + Trustonic) achieves working decryption, suggesting the issue was previously a config gap rather than a fundamental incompatibility.

Historically, the bitter reality in the custom recovery world was that **no source tree (TWRP or OrangeFox) had universally and stably succeeded in upstreaming FBE decryption with KeyMint 3.0 (AIDL)**, especially for the MediaTek + Trustonic TEE combination. The X6728 tree challenges this assumption for the Infinix HOT 60i specifically.

### Progress is on Qualcomm (QCOM), Not MediaTek

Checking the official TWRP Gerrit for the android-14 branch, developers (like Nebrassy) have only started adding patches for keymint-qti and AIDL GateKeeper in the `android_device_qcom_twrp-common` repository. Qualcomm is somewhat luckier because their cryptographic HAL documentation and behavior are more frequently analyzed. However, this cannot be directly ported to MediaTek devices.

### The "MediaTek + Trustonic TEE" Challenge

Infinix (and Tecno) devices using modern MediaTek chipsets typically use Trustonic Kinibi as their TEE (Trusted Execution Environment). The main problem with Trustonic is its very closed (proprietary) security system:

- **Cannot simply throw** the `android.hardware.security.keymint@3.0-service.trustonic` binary and load the kernel module (`mcDrvModule.ko`) and expect it to work.
- **Trustonic's KeyMint V3 service** typically demands a complete boot environment verification (checking metadata partition, weaver status, and complex connections to trustlet applications in `/vendor/app/mcRegistry`).
- **When running in minimal environment** like TWRP/OrangeFox, this service often crashes or refuses to communicate because it perceives the environment as "unsafe".

### Reference Repositories (Not Instant Solutions)

If you still want to cherry-pick or see how other maintainers try to work around Android 14/15, you can monitor:

- **Minimal Manifest TWRP AOSP** (twrp-15 or android-14 branch): Where devs are trying to adjust build structure for the latest Android.
- **Modern Samsung Devices**: Some Samsung developers (like tree for Galaxy M55) are testing `vendor.samsung.hardware.keymint-V3-ndk.so` implementation, but this is also very specific to Knox/Samsung TEE.

### Debugging Approach

The approach to bypass the splash screen and take manual logs is an engineering-wise correct step, because from `logcat` or `dmesg` you can directly see at which point the Infinix KeyMint 3.0 disconnects (whether at Gatekeeper, TEE communication, or vold).

As a developer/maintainer, you are at the forefront. Don't be surprised if references from other devices don't help much, because each vendor implements Google's KeyMint V3 standard with different security styles.

## Patches Applied at Lunch

The `vendorsetup.sh` script auto-applies the following patches from `patches/` against the AOSP workspace at lunch time (each is dry-run first, skipped if already applied or not applicable):

1. **`01-patch-health-hal.patch`** — removes `vintf_fragments` from `android.hardware.health-service.example-defaults` in `hardware/interfaces/health/aidl/default/Android.bp`. Ported from X6728.
2. **`02-patch-vibration-brightness.patch`** — adds a `/sys/class/leds/vibrator/brightness` fallback path in `bootable/recovery/twrpminui/events.cpp` for haptic feedback during TWRP UI interactions. Ported from X6728.
3. **`0001-Change-haptics-activation-file-path.patch`** — adds a `VIBRATOR_CUSTOM_PATH` macro guard in `events.cpp` for device-specific haptics paths. Original X6873 patch, retained.

## Building
### TWRP, PBRP
_Lunch_ command :

```
lunch twrp_X6873-eng && mka vendorbootimage
```

### SHRP, OrangeFox
_Lunch_ command :

```
lunch twrp_X6873-eng && mka adbd vendorbootimage
```

## Credits

- **Template Base**: [Andrikurn/twrp_device_infinix_X6728](https://github.com/Andrikurn/twrp_device_infinix_X6728) — TWRP device tree for Infinix HOT 60i (X6728). Used as the structural template for this X6873 port.
- **A15 Porting Reference**: [naden01/tecno_LH8n-TWRP](https://github.com/naden01/tecno_LH8n-TWRP) — original structure of this tree was ported using this repository as reference.
- **Firmware Blobs**: [rama-firmware-dumps/Infinix-X6873](https://gitlab.com/rama-firmware-dumps/infinix/Infinix-X6873) — supplementary Trustonic/Transsion/AIDL blobs fetched from firmware dump branch `X6873-16.2.0.150SP12(OP003PF001AZ)`.
