/*
 * TWRP-Keymint Bridge Header
 * For Infinix X6873 (GT 30 Pro)
 *
 * This header provides the C interface for TWRP to interact with
 * Android's Keymint/Keymaster services for FBE v2 decryption.
 */

#ifndef TWRP_KEYMINT_BRIDGE_H
#define TWRP_KEYMINT_BRIDGE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Initialize the keymint bridge
 * Must be called before any other functions
 *
 * Returns:
 *   0 on success
 *   -1 on failure (check logs for details)
 */
int twrp_keymint_init(void);

/*
 * Derive key for FBE decryption
 *
 * Parameters:
 *   entropy      - Random entropy for key derivation
 *   entropy_len  - Length of entropy data
 *   app_id       - Application ID for key isolation
 *   app_id_len   - Length of application ID
 *   out_key      - Output buffer for derived key
 *   out_key_len  - Input: size of buffer, Output: actual key size
 *
 * Returns:
 *   0 on success
 *   -1 on failure
 */
int twrp_keymint_derive_key(
    const uint8_t* entropy,
    size_t entropy_len,
    const uint8_t* app_id,
    size_t app_id_len,
    uint8_t* out_key,
    size_t* out_key_len
);

/*
 * Check if keymint service is ready
 *
 * Returns:
 *   1 if ready
 *   0 if not ready
 */
int twrp_keymint_is_ready(void);

/*
 * Check if gatekeeper service is ready for PIN/password verification
 *
 * Returns:
 *   1 if ready
 *   0 if not ready
 */
int twrp_keymint_gatekeeper_ready(void);

/*
 * Cleanup resources
 */
void twrp_keymint_cleanup(void);

#ifdef __cplusplus
}
#endif

#endif /* TWRP_KEYMINT_BRIDGE_H */
