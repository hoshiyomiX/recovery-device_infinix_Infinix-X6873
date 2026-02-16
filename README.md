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

- [X] Display
- [X] Touch
- [X] ADB
- [X] Fasbootd
- [X] Flashing
- [X] MTP
- [X] Sideload
- [X] Decryption (AIDL Keymint v3 - Fixed)
- [ ] USB OTG
- [ ] Vibrator

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
