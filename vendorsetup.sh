#!/bin/bash
#
# vendorsetup.sh — auto-patch helper for Infinix X6873 (MT6897) TWRP tree.
#
# Adapted from the X6728 (Andrikurn/twrp_device_infinix_X6728) template:
#   - applies 01-patch-health-hal.patch     (AIDL health service vintf_fragments removal)
#   - applies 02-patch-vibration-brightness.patch (LEDS vibrator brightness fallback)
#   - applies 0001-Change-haptics-activation-file-path.patch (VIBRATOR_CUSTOM_PATH guard)
#
# Each patch is applied with `patch -p1 -N` from the AOSP workspace root, with a
# --dry-run first. Dry-run failures (e.g. source file already patched, or target
# file path differs on this branch) are non-fatal: the patch is skipped with a
# notice. This mirrors the X6728 behavior and keeps `lunch` resilient.
#
# Original template: Copyright (C) 2020-2025 The OrangeFox Recovery Project (GPL-3.0-or-later)
#

device_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd "${device_dir}/../../.." && pwd)"

patches=(
    "patches/01-patch-health-hal.patch"
    "patches/02-patch-vibration-brightness.patch"
    "patches/0001-Change-haptics-activation-file-path.patch"
)

if ! command -v patch >/dev/null 2>&1; then
    echo "[X6873] Missing required command: patch"
    return 0 2>/dev/null || exit 0
fi

applied=0
skipped=0
failed=0

for rel in "${patches[@]}"; do
    patch_file="${device_dir}/${rel}"
    if [[ ! -f "${patch_file}" ]]; then
        echo "[X6873] Missing patch: ${rel}"
        failed=$((failed + 1))
        continue
    fi
    if ( cd "${workspace_root}" && patch -p1 -N --dry-run --silent < "${patch_file}" >/dev/null 2>&1 ); then
        if ( cd "${workspace_root}" && patch -p1 -N --silent < "${patch_file}" >/dev/null 2>&1 ); then
            echo "[X6873] Applied: ${rel}"
            applied=$((applied + 1))
        else
            echo "[X6873] Failed to apply (dry-run OK, real apply failed): ${rel}"
            failed=$((failed + 1))
        fi
    else
        echo "[X6873] Skipped (already applied or not applicable): ${rel}"
        skipped=$((skipped + 1))
    fi
done

echo "[X6873] Patches summary — applied: ${applied}, skipped: ${skipped}, failed: ${failed}"

unset device_dir workspace_root patches rel patch_file applied skipped failed
