# TrustZone Applications (TA)

This directory should contain TrustZone applications (.ta files).

For this device (X6873), the Trusted Applications are stored in:
- `/vendor/app/mcRegistry/*.tlbin` - Trustonic trusted libraries
- `/vendor/app/mcRegistry/*.drbin` - Trustonic drivers

The mcRegistry format (.tlbin/.drbin) is used by Trustonic TEE.

If you need actual .ta files, extract them from:
1. The stock firmware's /vendor/thh/ta/ directory
2. Or convert from other Trustonic formats

Required TAs for crypto functionality:
- Keymaster TA (UUID: 0715xxxx...)
- Gatekeeper TA (UUID: 0717xxxx...)  
- Secure Storage TA (UUID: 0721xxxx...)
