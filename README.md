## ADVAN X1 (_6781_)
## Recovery device tree (TWRP, PBRP, OrangeFox, SHRP)

## Device specifications

Device                  | ADVAN X1
-----------------------:|:-----------------------------------------
SoC                     | Mediatek Helio G100 Ultimate (6 nm)
CPU                     | Octa-core (2x2.2 GHz Cortex-A76 & 6x2.0 GHz Cortex-A55)
GPU                     | Mali-G57 MC2
Memory                  | 8 GB RAM
Storage                 | 128 GB (UFS 2.2)
MicroSD                 | microSDXC (dedicated slot)
Shipped Android Version | 14.0
Battery                 | Non-removable 5000 mAh
Display                 | 1080 x 2460 pixels (~396 ppi density), 6.78 inches, 120hz
Camera                  | 64 MP Sony-IMX782; 5 MP (front)

## Device picture

![ ADVAN X1 ](https://i0.wp.com/advandigital.com/wp-content/uploads/2025/07/Background.png?w=752&ssl=1 "ADVAN X1")

## Features

Works:

- [X] ADB
- [X] Decryption
- [X] Display
- [X] Fasbootd
- [X] Flashing
- [X] MTP
- [X] Sideload
- [x] USB OTG
- [x] Vibrator

## Building
### TWRP, PBRP
_Lunch_ command :

```
lunch twrp_ADVAN_X1-eng && mka vendorbootimage
```

### SHRP, OrangeFox
_Lunch_ command :

```
lunch twrp_ADVAN_X1-eng && mka adbd vendorbootimage
```
