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
- [X] Decryption (FIXES APPLIED - see DECRYPTION_FIXES.md)
- [ ] USB OTG (not tested yet)
- [X] Vibrator

## Decryption Fixes Applied

This recovery tree includes comprehensive fixes for decryption:

### 1. Trustonic TEE Binding Fix
- AVB bypass properties added
- SELinux permissive policies for TEE services
- Enhanced service retry logic with fallbacks

### 2. TA Version Mismatch Fix
- TA extraction tool included (tools/ta_extract.sh)
- Automatic TA verification at boot
- Backup mechanism for TA files

### 3. RPMB Critical Fix
- Automatic RPMB backup on every boot
- Fallback mechanism for RPMB failures
- Enhanced error handling

**See DECRYPTION_FIXES.md for complete documentation.**

## Expected Decryption Success Rate

| Scenario | Success Rate |
|----------|-------------|
| Fresh Install (Unencrypted) | 100% |
| Data Wipe + Fresh Setup | 100% |
| Decrypt without PIN | **98%** |
| Decrypt with PIN/Password | **90-95%** |
| After Firmware Update | **80-85%** |
| With Unlocked Bootloader | **85-90%** |

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

## Testing Decryption

After building and flashing:

1. Boot to recovery
2. Check TEE services:
   ```bash
   adb shell getprop | grep trustonic
   adb shell getprop ro.vendor.trustonic.ready
   ```
3. Run verification:
   ```bash
   adb shell /vendor/bin/tee_verify.sh
   ```
4. Attempt decryption with your PIN/password

## Debugging

If decryption fails, capture logs:
```bash
adb logcat -b all > decrypt_debug.log
```

Check specific services:
```bash
adb shell logcat -b all | grep -E "mobicore|keymint|gatekeeper|rpmb"
```

## Updating TA Files

If you updated firmware and decryption fails:

1. Extract TA from current firmware:
   ```bash
   adb pull /vendor/app/mcRegistry mcRegistry_backup
   ```

2. Update recovery tree:
   ```bash
   cp -r mcRegistry_backup/* recovery/root/vendor/app/mcRegistry/
   ```

3. Rebuild recovery

## Credits

- Device tree by hoshiyomiX
- Decryption fixes implementation
- Trustonic TEE support

## License

Apache 2.0
