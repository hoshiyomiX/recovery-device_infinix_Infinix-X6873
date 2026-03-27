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
