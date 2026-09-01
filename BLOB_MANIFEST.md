# BLOB MANIFEST — X6873 Supplementary Blobs

This manifest documents the supplementary blobs fetched from the Infinix X6873 firmware dump and merged into the recovery tree.

## Source

- **Repository**: [rama-firmware-dumps/Infinix-X6873](https://gitlab.com/rama-firmware-dumps/infinix/Infinix-X6873)
- **Branch**: `X6873-16.2.0.150SP12(OP003PF001AZ)`
- **Fetch method**: GitLab API endpoint (`/api/v4/projects/.../repository/files/:path/raw?ref=:branch`) with curl. Raw endpoint (`/-/raw/...`) was used initially but rate-limited after the first batch.
- **Total attempted**: 28 blobs
- **Fetched OK**: 27
- **Failed**: 1 (rate-limited, non-critical)
- **Total bytes**: 1,618,342

## Why these blobs

The X6728 template (`Andrikurn/twrp_device_infinix_X6728`) ships a richer set of TWRP-relevant blobs than the X6873 source tree had. The blobs below fill the gap so the X6873 ported tree matches the X6728 feature set:

- **Paytrigger HAL** — Transsion payment-trigger TEE service + libs (X6728 has these, X6873 lacked them entirely)
- **Tranlog libs** — Transsion logging TEE libs (X6728 has them, X6873 lacked)
- **Trustonic VINTF manifests** — secureclock + sharedsecret AIDL HAL declarations
- **AIDL health V1/V2/V4 NDK libs** — for the AIDL health service
- **Keystore2 AIDL libs** — V1-cpp + V5-ndk + support libs (aaid, apc_compat, crypto, attestation-app-id, keyutils)
- **rkp-V3-ndk** — Remote Key Provisioning (required by KeyMint V3+)
- **system_ext trustonic libs** — `libTeeClient.so` (TUI client) + `libtrankeytask.so` (TranKey task)

## Fetched blobs (27 OK)

| Destination path | Size | Type | Source path |
|---|---:|---|---|
| `vendor/bin/hw/vendor.transsion.hardware.security.paytrigger@1.0-service` | 24,160 | ELF | `vendor/bin/hw/...` |
| `vendor/lib64/libpaytrigger.trustonic.so` | 18,824 | ELF | `vendor/lib64/...` |
| `vendor/lib64/vendor.transsion.hardware.security.paytrigger-V1-ndk.so` | 42,008 | ELF | `vendor/lib64/...` |
| `vendor/lib64/libtneclient.so` | 24,352 | ELF | `vendor/lib64/...` |
| `vendor/lib64/libtranlog.so` | 81,968 | ELF | `vendor/lib64/...` |
| `vendor/lib64/vendor.transsion.hardware.tranlogconfig-V1-ndk.so` | 46,456 | ELF | `vendor/lib64/...` |
| `vendor/lib64/vendor.transsion.hardware.tranlog-V1-ndk.so` | 59,224 | ELF | `vendor/lib64/...` |
| `vendor/etc/init/vendor.transsion.hardware.security.paytrigger@1.0-service.rc` | 394 | ASCII | `vendor/etc/init/...` |
| `vendor/etc/vintf/manifest/vendor.transsion.hardware.security.paytrigger@1.0-service.xml` | 227 | XML | `vendor/etc/vintf/manifest/...` |
| `vendor/etc/vintf/manifest/android.hardware.security.secureclock-service.trustonic.xml` | 191 | XML | `vendor/etc/vintf/manifest/...` |
| `vendor/etc/vintf/manifest/android.hardware.security.sharedsecret-service.trustonic.xml` | 193 | XML | `vendor/etc/vintf/manifest/...` |
| `vendor/etc/vintf/manifest/android.hardware.health-service.example.xml` | 201 | XML | `vendor/etc/vintf/manifest/...` |
| `system/lib64/android.hardware.security.rkp-V3-ndk.so` | 85,848 | ELF | `system/system/lib64/...` |
| `system/lib64/android.hardware.security.secureclock-V1-ndk.so` | 69,056 | ELF | `system/system/lib64/...` |
| `system/lib64/android.hardware.security.sharedsecret-V1-ndk.so` | 85,584 | ELF | `system/system/lib64/...` |
| `system/lib64/android.hardware.health-V1-ndk.so` | 85,472 | ELF | `system/system/lib64/...` |
| `system/lib64/android.hardware.health-V2-ndk.so` | 85,560 | ELF | `system/system/lib64/...` |
| `system/lib64/android.hardware.health-V4-ndk.so` | 85,672 | ELF | `system/system/lib64/...` |
| `system/lib64/android.system.keystore2-V1-cpp.so` | 119,240 | ELF | `system/system/lib64/...` |
| `system/lib64/android.system.keystore2-V5-ndk.so` | 119,344 | ELF | `system/system/lib64/...` |
| `system/lib64/libkeystore2_aaid.so` | 35,256 | ELF | `system/system/lib64/...` |
| `system/lib64/libkeystore2_apc_compat.so` | 69,320 | ELF | `system/system/lib64/...` |
| `system/lib64/libkeystore2_crypto.so` | 37,944 | ELF | `system/system/lib64/...` |
| `system/lib64/libkeystore-attestation-application-id.so` | 52,040 | ELF | `system/system/lib64/...` |
| `system/lib64/libkeyutils.so` | 35,152 | ELF | `system/system/lib64/...` |
| `system_ext/lib64/libTeeClient.so` | 119,408 | ELF | `system_ext/lib64/...` |
| `system_ext/lib64/libtrankeytask.so` | 235,248 | ELF | `system_ext/lib64/...` |

## Failed blobs (1)

| Destination path | Reason | Severity |
|---|---|---|
| `system/lib64/android.hardware.security.keymint-V4-ndk.so` | GitLab rate-limit (HTTP 403) on both raw and API endpoints | **NON-CRITICAL** — `keymint-V3-ndk.so` already present in tree (X6873 ships V3, not V4). V4 was a bonus for SP12 compatibility but not required. |

## How to re-fetch the failed blob

If the rate-limit clears (typically within minutes), re-run:

```bash
curl -L --max-time 60 -sS -f \
  -H "User-Agent: Mozilla/5.0" \
  "https://gitlab.com/api/v4/projects/rama-firmware-dumps%2Finfinix%2FInfinix-X6873/repository/files/system%2Fsystem%2Flib64%2Fandroid.hardware.security.keymint-V4-ndk.so/raw?ref=X6873-16.2.0.150SP12%28OP003PF001AZ%29" \
  -o recovery/root/system/lib64/android.hardware.security.keymint-V4-ndk.so
```

## JSON manifest

A machine-readable version is at `BLOB_MANIFEST.json` (alongside this file). Structure:

```json
{
  "repo": "https://gitlab.com/rama-firmware-dumps/infinix/Infinix-X6873",
  "branch": "X6873-16.2.0.150SP12(OP003PF001AZ)",
  "total": 28,
  "ok": 27,
  "fail": 1,
  "total_bytes": 1618342,
  "entries": [
    {"src": "...", "dst": "...", "ok": true, "size": 24160, "elf": true, "error": null},
    ...
  ]
}
```
