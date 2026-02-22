/*
 * TWRP-Keymint Bridge for Infinix X6873 (GT 30 Pro)
 * Version: 2.0 - AIDL Only (Vendor Compatible Build)
 *
 * This library bridges TWRP's crypto operations to Android's Keymint
 * interfaces for proper FBE v2 decryption support.
 *
 * Supports:
 * - AIDL Keymint v3 (Android 15+) - Primary interface
 * - AIDL Gatekeeper v1 (for PIN/password verification)
 *
 * Note: HIDL support removed due to vendor visibility restrictions.
 * For Android 15 devices, AIDL Keymint is the primary interface.
 */

#define LOG_TAG "twrp_keymint_bridge"

#include <android-base/logging.h>
#include <android-base/properties.h>

#include <aidl/android/hardware/security/keymint/IKeyMintDevice.h>
#include <aidl/android/hardware/security/keymint/IKeyMintOperation.h>
#include <aidl/android/hardware/security/keymint/KeyParameter.h>
#include <aidl/android/hardware/security/keymint/KeyParameterValue.h>
#include <aidl/android/hardware/security/keymint/KeyCharacteristics.h>
#include <aidl/android/hardware/security/keymint/KeyCreationResult.h>
#include <aidl/android/hardware/security/keymint/SecurityLevel.h>
#include <aidl/android/hardware/security/keymint/KeyMintHardwareInfo.h>

#include <aidl/android/hardware/gatekeeper/IGatekeeper.h>

#include <binder/IServiceManager.h>

#include <cutils/properties.h>

#include <vector>
#include <string>
#include <memory>
#include <mutex>
#include <chrono>
#include <thread>

namespace android {
namespace recovery {
namespace keymint {

using namespace ::aidl::android::hardware::security::keymint;
using namespace ::aidl::android::hardware::gatekeeper;

// Connection state tracking
enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED_AIDL,
    FAILED
};

class KeymintBridge {
private:
    std::mutex mutex_;
    ConnectionState state_ = ConnectionState::DISCONNECTED;

    // AIDL interfaces
    std::shared_ptr<IKeyMintDevice> keymint_device_;
    std::shared_ptr<IGatekeeper> gatekeeper_;

    // Service readiness
    bool service_ready_ = false;
    int retry_count_ = 0;
    static constexpr int MAX_RETRIES = 10;
    static constexpr int RETRY_DELAY_MS = 500;

    SecurityLevel security_level_ = SecurityLevel::SOFTWARE;

public:
    KeymintBridge() = default;
    ~KeymintBridge() = default;

    /*
     * Wait for Keymint service to be ready
     * Returns true if service is available
     */
    bool waitForService(int timeout_ms = 15000) {
        auto start = std::chrono::steady_clock::now();

        while (true) {
            auto now = std::chrono::steady_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();

            if (elapsed >= timeout_ms) {
                LOG(ERROR) << "Timeout waiting for Keymint service";
                state_ = ConnectionState::FAILED;
                return false;
            }

            // Check TEE readiness property
            int tee_ready = android::base::GetIntProperty("ro.vendor.tee.initialized", 0);
            if (tee_ready != 1) {
                LOG(DEBUG) << "TEE not ready (ro.vendor.tee.initialized=" << tee_ready << "), waiting...";
                std::this_thread::sleep_for(std::chrono::milliseconds(500));
                continue;
            }

            // Try AIDL Keymint (Android 13+)
            if (connectAidlKeymint()) {
                state_ = ConnectionState::CONNECTED_AIDL;
                service_ready_ = true;
                LOG(INFO) << "Connected to AIDL Keymint successfully";
                return true;
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(RETRY_DELAY_MS));
            retry_count_++;

            if (retry_count_ >= MAX_RETRIES) {
                LOG(ERROR) << "Max retries reached, Keymint connection failed";
                state_ = ConnectionState::FAILED;
                return false;
            }
        }

        return false;
    }

    /*
     * Connect to AIDL Keymint service
     * Supports both default and strongbox instances
     */
    bool connectAidlKeymint() {
        // Try default instance first
        if (tryConnectKeymintInstance("android.hardware.security.keymint.IKeyMintDevice/default")) {
            return true;
        }

        // Try strongbox instance (for devices with secure element)
        if (tryConnectKeymintInstance("android.hardware.security.keymint.IKeyMintDevice/strongbox")) {
            return true;
        }

        // Try TEE instance
        if (tryConnectKeymintInstance("android.hardware.security.keymint.IKeyMintDevice/tee")) {
            return true;
        }

        LOG(ERROR) << "No Keymint instance found";
        return false;
    }

    bool tryConnectKeymintInstance(const std::string& instance_name) {
        ::ndk::SpAIBinder binder(AServiceManager_getService(instance_name.c_str()));
        if (binder.get() == nullptr) {
            LOG(DEBUG) << "Keymint service not found: " << instance_name;
            return false;
        }

        keymint_device_ = IKeyMintDevice::fromBinder(binder);
        if (keymint_device_ == nullptr) {
            LOG(ERROR) << "Failed to get Keymint interface from: " << instance_name;
            return false;
        }

        // Verify connection by getting hardware info
        KeyMintHardwareInfo info;
        auto status = keymint_device_->getHardwareInfo(&info);
        if (!status.isOk()) {
            LOG(ERROR) << "Failed to get Keymint hardware info: " << status.getDescription();
            keymint_device_ = nullptr;
            return false;
        }

        security_level_ = info.securityLevel;
        LOG(INFO) << "Keymint connected: " << instance_name
                  << ", security level: " << static_cast<int>(info.securityLevel)
                  << ", keymint version: " << info.keyMintVersion
                  << ", keymaster version: " << info.keyMintVersion;

        return true;
    }

    /*
     * Connect to Gatekeeper service for PIN/password verification
     */
    bool connectGatekeeper() {
        ::ndk::SpAIBinder binder(AServiceManager_getService("android.hardware.gatekeeper.IGatekeeper/default"));
        if (binder.get() == nullptr) {
            LOG(DEBUG) << "Gatekeeper service not found";
            return false;
        }

        gatekeeper_ = IGatekeeper::fromBinder(binder);
        if (gatekeeper_ == nullptr) {
            LOG(ERROR) << "Failed to get Gatekeeper interface";
            return false;
        }

        LOG(INFO) << "Gatekeeper connected successfully";
        return true;
    }

    /*
     * Derive key for FBE decryption
     * This is the main function called by TWRP for decryption
     */
    bool deriveKey(const std::vector<uint8_t>& entropy,
                   const std::vector<uint8_t>& application_id,
                   std::vector<uint8_t>& derived_key) {
        if (!service_ready_ || keymint_device_ == nullptr) {
            LOG(ERROR) << "Keymint service not ready";
            return false;
        }

        return deriveKeyAidl(entropy, application_id, derived_key);
    }

    /*
     * Derive key using AIDL Keymint
     */
    bool deriveKeyAidl(const std::vector<uint8_t>& entropy,
                       const std::vector<uint8_t>& application_id,
                       std::vector<uint8_t>& derived_key) {
        if (keymint_device_ == nullptr) {
            LOG(ERROR) << "AIDL Keymint not connected";
            return false;
        }

        // Build key parameters for FBE key derivation
        std::vector<KeyParameter> params;

        KeyParameter param;

        // Key purpose: DERIVE_KEY
        param.tag = Tag::PURPOSE;
        param.value = KeyParameterValue(KeyPurpose::DERIVE_KEY);
        params.push_back(param);

        // Algorithm: AES
        param.tag = Tag::ALGORITHM;
        param.value = KeyParameterValue(Algorithm::AES);
        params.push_back(param);

        // Key size: 256 bits
        param.tag = Tag::KEY_SIZE;
        param.value = KeyParameterValue(256);
        params.push_back(param);

        // Block mode: XTS (for FBE)
        param.tag = Tag::BLOCK_MODE;
        param.value = KeyParameterValue(BlockMode::XTS);
        params.push_back(param);

        // Padding: NONE
        param.tag = Tag::PADDING;
        param.value = KeyParameterValue(PaddingMode::NONE);
        params.push_back(param);

        // Security level
        param.tag = Tag::SECURITY_LEVEL;
        param.value = KeyParameterValue(security_level_);
        params.push_back(param);

        // No authentication required for recovery
        param.tag = Tag::NO_AUTH_REQUIRED;
        param.value = KeyParameterValue(true);
        params.push_back(param);

        // Create key with entropy
        KeyCreationResult result;
        auto status = keymint_device_->generateKey(params, entropy, &result);

        if (!status.isOk()) {
            LOG(ERROR) << "Failed to generate key: " << status.getDescription();
            return false;
        }

        if (result.keyBlob.empty()) {
            LOG(ERROR) << "Empty key blob returned from Keymint";
            return false;
        }

        derived_key = result.keyBlob;
        LOG(INFO) << "Successfully derived key via AIDL Keymint, size: " << derived_key.size();
        return true;
    }

    /*
     * Import key for decryption (alternative to deriveKey)
     */
    bool importKey(const std::vector<uint8_t>& key_data,
                   std::vector<uint8_t>& key_blob) {
        if (keymint_device_ == nullptr) {
            LOG(ERROR) << "Keymint not connected";
            return false;
        }

        std::vector<KeyParameter> params;

        KeyParameter param;
        param.tag = Tag::PURPOSE;
        param.value = KeyParameterValue(KeyPurpose::DECRYPT);
        params.push_back(param);

        param.tag = Tag::ALGORITHM;
        param.value = KeyParameterValue(Algorithm::AES);
        params.push_back(param);

        param.tag = Tag::KEY_SIZE;
        param.value = KeyParameterValue(256);
        params.push_back(param);

        KeyCreationResult result;
        auto status = keymint_device_->importKey(
            params,
            KeyFormat::RAW,
            key_data,
            &result
        );

        if (!status.isOk()) {
            LOG(ERROR) << "Failed to import key: " << status.getDescription();
            return false;
        }

        key_blob = result.keyBlob;
        return true;
    }

    /*
     * Check if gatekeeper is available for PIN/password verification
     */
    bool isGatekeeperReady() {
        // Check property first
        int gatekeeper_ready = android::base::GetIntProperty("ro.vendor.gatekeeper.ready", 0);
        if (gatekeeper_ready == 1) {
            return true;
        }

        // Try to connect directly
        if (gatekeeper_ == nullptr) {
            return connectGatekeeper();
        }

        return gatekeeper_ != nullptr;
    }

    /*
     * Verify PIN/password with gatekeeper
     */
    bool verifyCredential(const std::vector<uint8_t>& credential,
                          const std::vector<uint8_t>& expected_response,
                          std::vector<uint8_t>& auth_token) {
        if (!isGatekeeperReady() || gatekeeper_ == nullptr) {
            LOG(ERROR) << "Gatekeeper not ready";
            return false;
        }

        // Gatekeeper verify operation
        // Note: This is a simplified implementation
        // Real implementation would need the stored password handle
        IGatekeeper::VerifyResponse response;
        auto status = gatekeeper_->verify(
            0,  // uid
            0,  // challenge (0 for decryption)
            {}, // enrolled_password_handle (empty for verification)
            credential,
            &response
        );

        if (!status.isOk()) {
            LOG(ERROR) << "Gatekeeper verify failed: " << status.getDescription();
            return false;
        }

        if (response.code == IGatekeeper::VerifyResponse::OK) {
            auth_token = response.hardwareAuthToken;
            return true;
        }

        return false;
    }

    /*
     * Get connection state for debugging
     */
    ConnectionState getState() const { return state_; }
    bool isReady() const { return service_ready_; }
    SecurityLevel getSecurityLevel() const { return security_level_; }
};

// Global instance
static std::unique_ptr<KeymintBridge> g_bridge;
static std::mutex g_bridge_mutex;

extern "C" {

/*
 * Initialize the keymint bridge
 * Must be called before any other functions
 */
int twrp_keymint_init() {
    std::lock_guard<std::mutex> lock(g_bridge_mutex);

    if (g_bridge != nullptr) {
        LOG(INFO) << "Keymint bridge already initialized";
        return 0;
    }

    g_bridge = std::make_unique<KeymintBridge>();
    if (!g_bridge->waitForService()) {
        LOG(ERROR) << "Failed to initialize keymint bridge";
        g_bridge.reset();
        return -1;
    }

    return 0;
}

/*
 * Derive key for FBE decryption
 */
int twrp_keymint_derive_key(const uint8_t* entropy, size_t entropy_len,
                            const uint8_t* app_id, size_t app_id_len,
                            uint8_t* out_key, size_t* out_key_len) {
    std::lock_guard<std::mutex> lock(g_bridge_mutex);

    if (g_bridge == nullptr) {
        LOG(ERROR) << "Bridge not initialized";
        return -1;
    }

    std::vector<uint8_t> entropy_vec(entropy, entropy + entropy_len);
    std::vector<uint8_t> app_id_vec(app_id, app_id + app_id_len);
    std::vector<uint8_t> derived_key;

    if (!g_bridge->deriveKey(entropy_vec, app_id_vec, derived_key)) {
        LOG(ERROR) << "Key derivation failed";
        return -1;
    }

    if (derived_key.size() > *out_key_len) {
        LOG(ERROR) << "Output buffer too small";
        return -1;
    }

    memcpy(out_key, derived_key.data(), derived_key.size());
    *out_key_len = derived_key.size();

    return 0;
}

/*
 * Check if decryption is possible
 */
int twrp_keymint_is_ready() {
    std::lock_guard<std::mutex> lock(g_bridge_mutex);

    if (g_bridge == nullptr) {
        return 0;
    }

    return g_bridge->isReady() ? 1 : 0;
}

/*
 * Check if gatekeeper is available
 */
int twrp_keymint_gatekeeper_ready() {
    std::lock_guard<std::mutex> lock(g_bridge_mutex);

    if (g_bridge == nullptr) {
        return 0;
    }

    return g_bridge->isGatekeeperReady() ? 1 : 0;
}

/*
 * Get security level (0=SOFTWARE, 1=TEE, 2=STRONGBOX)
 */
int twrp_keymint_get_security_level() {
    std::lock_guard<std::mutex> lock(g_bridge_mutex);

    if (g_bridge == nullptr) {
        return 0;
    }

    return static_cast<int>(g_bridge->getSecurityLevel());
}

/*
 * Cleanup
 */
void twrp_keymint_cleanup() {
    std::lock_guard<std::mutex> lock(g_bridge_mutex);
    g_bridge.reset();
}

} // extern "C"

} // namespace keymint
} // namespace recovery
} // namespace android
