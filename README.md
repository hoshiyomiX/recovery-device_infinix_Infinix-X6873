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
- [ ] Decryption (temporary disabled)
- [ ] USB OTG
- [ ] Vibrator

## Caution

> **⚠️ WARNING: This recovery tree is a WORK IN PROGRESS port and may not work as intended!**

- **Different Tree Structure**: This recovery tree structure is completely different from the original [recovery-device_infinix_Infinix-X6873](https://github.com/idabgsram/recovery-device_infinix_Infinix-X6873). It was ported from [tecno_LH8n-TWRP](https://github.com/naden01/tecno_LH8n-TWRP) and may potentially not work as intended compared to the original.

- **Outdated Blobs**: The blobs used in this recovery tree are outdated, extracted from firmware dump `X6873-15.0.3.116SP01(0P001PF001AZ)`. You can find the firmware dump at [rama-firmware-dumps/Infinix-X6873](https://gitgud.io/rama-firmware-dumps/infinix/Infinix-X6873).

- **Decryption Disabled**: Decryption is temporarily disabled to avoid the splash logo stuck issue when entering custom recovery. This will be addressed in future updates.

## Technical Notes: KeyMint V3 Challenge

> **Reference Document**: [Tantangan KeyMint V3 di Recovery Kustom](https://docs.google.com/document/d/1ERo8MeMnI-VOqszsCS40wSIZfof55NPcVyDJVeJXd8g/edit?usp=drivesdk)

### Current State of FBE Decryption with KeyMint 3.0

Unfortunately, the bitter reality in the custom recovery world today is that **no source tree (TWRP or OrangeFox) has universally and stably succeeded in upstreaming FBE decryption with KeyMint 3.0 (AIDL)**, especially for the MediaTek + Trustonic TEE combination.

Currently, the stable and official TWRP branch (android-12.1) mostly caps at KeyMint 1.0/2.0 or Keymaster 4.1 capabilities. For Android 14 and 15 that enforce KeyMint V3 usage, the situation remains highly experimental.

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

- **A15 Porting Reference**: [naden01/tecno_LH8n-TWRP](https://github.com/naden01/tecno_LH8n-TWRP) - This recovery tree was ported using this repository as reference.
