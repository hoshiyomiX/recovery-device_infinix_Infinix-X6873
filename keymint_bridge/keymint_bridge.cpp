/*
 * TWRP-Keymint Bridge for Infinix X6873 (GT 30 Pro)
 * Version: 1.0 - Fix for Missing Bridge
 *
 * This library bridges TWRP's crypto operations to Android's Keymint/Keymaster
 * interfaces for proper FBE v2 decryption support.
 *
 * Supports:
 * - AIDL Keymint v3 (Android 15+)
 * - HIDL Keymaster v4.0/v4.1 (backward compatibility)
 */

#define LOG_TAG "twrp_keymint_bridge"

#include <android-base/logging.h>
#include <android-base/properties.h>

#include <aidl/android/hardware/security/keymint/IKeyMintDevice.h>
#include <aidl/android/hardware/security/keymint/KeyParameter.h>
#include <aidl/android/hardware/security/keymint/KeyParameterValue.h>
#include <aidl/android/hardware/security/keymint/KeyCharacteristics.h>
#include <aidl/android/hardware/security/keymint/KeyCreationResult.h>
#include <aidl/android/hardware/security/keymint/SecurityLevel.h>

#include <android/hardware/keymaster/4.0/IKeymasterDevice.h>
#include <android/hardware/keymaster/4.0/types.h>
#include <android/hardware/keymaster/4.1/IKeymasterDevice.h>
#include <android/hardware/keymaster/4.1/types.h>

#include <binder/IServiceManager.h>
#include <hidl/HidlSupport.h>
#include <hidl/ServiceManagement.h>

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
using namespace ::android::hardware::keymaster::V4_0;
using namespace ::android::hardware::keymaster::V4_1;

// Connection state tracking
enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED_AIDL,
    CONNECTED_HIDL,
    FAILED
};

class KeymintBridge {
private:
    std::mutex mutex_;
    ConnectionState state_ = ConnectionState::DISCONNECTED;

    // AIDL interface
    std::shared_ptr<IKeyMintDevice> aidl_keymint_;

    // HIDL interface
    sp<V4_1::IKeymasterDevice> hidl_keymaster_;
    sp<V4_0::IKeymasterDevice> hidl_keymaster_v4_;

    // Service readiness
    bool service_ready_ = false;
    int retry_count_ = 0;
    static constexpr int MAX_RETRIES = 10;
    static constexpr int RETRY_DELAY_MS = 500;

public:
    KeymintBridge() = default;
    ~KeymintBridge() = default;

    /*
     * Wait for Keymint/Keymaster service to be ready
     * Returns true if service is available
     */
    bool waitForService(int timeout_ms = 10000) {
        auto start = std::chrono::steady_clock::now();

        while (true) {
            auto now = std::chrono::steady_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();

            if (elapsed >= timeout_ms) {
                LOG(ERROR) << "Timeout waiting for Keymint/Keymaster service";
                return false;
            }

            // Check TEE readiness property
            int tee_ready = android::base::GetIntProperty("ro.vendor.tee.initialized", 0);
            if (tee_ready != 1) {
                LOG(DEBUG) << "TEE not ready, waiting...";
                std::this_thread::sleep_for(std::chrono::milliseconds(500));
                continue;
            }

            // Try AIDL Keymint first (Android 15+)
            if (connectAidlKeymint()) {
                state_ = ConnectionState::CONNECTED_AIDL;
                service_ready_ = true;
                LOG(INFO) << "Connected to AIDL Keymint v3";
                return true;
            }

            // Fallback to HIDL Keymaster 4.1
            if (connectHidlKeymaster41()) {
                state_ = ConnectionState::CONNECTED_HIDL;
                service_ready_ = true;
                LOG(INFO) << "Connected to HIDL Keymaster 4.1";
                return true;
            }

            // Fallback to HIDL Keymaster 4.0
            if (connectHidlKeymaster40()) {
                state_ = ConnectionState::CONNECTED_HIDL;
                service_ready_ = true;
                LOG(INFO) << "Connected to HIDL Keymaster 4.0";
                return true;
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(RETRY_DELAY_MS));
            retry_count_++;
        }

        return false;
    }

    /*
     * Connect to AIDL Keymint service
     */
    bool connectAidlKeymint() {
        ::ndk::SpAIBinder binder(AServiceManager_getService("android.hardware.security.keymint.IKeyMintDevice/default"));
        if (binder.get() == nullptr) {
            LOG(DEBUG) << "AIDL Keymint service not found";
            return false;
        }

        aidl_keymint_ = IKeyMintDevice::fromBinder(binder);
        if (aidl_keymint_ == nullptr) {
            LOG(ERROR) << "Failed to get AIDL Keymint interface";
            return false;
        }

        // Verify connection by getting hardware info
        KeyMintHardwareInfo info;
        auto status = aidl_keymint_->getHardwareInfo(&info);
        if (!status.isOk()) {
            LOG(ERROR) << "Failed to get Keymint hardware info: " << status.getDescription();
            aidl_keymint_ = nullptr;
            return false;
        }

        LOG(INFO) << "AIDL Keymint connected, security level: " << (int)info.securityLevel
                  << ", version: " << info.keyMintVersion;
        return true;
    }

    /*
     * Connect to HIDL Keymaster 4.1 service
     */
    bool connectHidlKeymaster41() {
        hidl_keymaster_ = V4_1::IKeymasterDevice::getService();
        if (hidl_keymaster_ == nullptr) {
            LOG(DEBUG) << "HIDL Keymaster 4.1 service not found";
            return false;
        }

        // Verify connection
        auto result = hidl_keymaster_->getHardwareInfo();
        if (!result.isOk()) {
            LOG(ERROR) << "Failed to get Keymaster 4.1 hardware info";
            hidl_keymaster_ = nullptr;
            return false;
        }

        LOG(INFO) << "HIDL Keymaster 4.1 connected";
        return true;
    }

    /*
     * Connect to HIDL Keymaster 4.0 service
     */
    bool connectHidlKeymaster40() {
        hidl_keymaster_v4_ = V4_0::IKeymasterDevice::getService();
        if (hidl_keymaster_v4_ == nullptr) {
            LOG(DEBUG) << "HIDL Keymaster 4.0 service not found";
            return false;
        }

        LOG(INFO) << "HIDL Keymaster 4.0 connected";
        return true;
    }

    /*
     * Derive key for FBE decryption
     * This is the main function called by TWRP for decryption
     */
    bool deriveKey(const std::vector<uint8_t>& entropy,
                   const std::vector<uint8_t>& application_id,
                   std::vector<uint8_t>& derived_key) {
        if (!service_ready_) {
            LOG(ERROR) << "Service not ready";
            return false;
        }

        if (state_ == ConnectionState::CONNECTED_AIDL) {
            return deriveKeyAidl(entropy, application_id, derived_key);
        } else if (state_ == ConnectionState::CONNECTED_HIDL) {
            return deriveKeyHidl(entropy, application_id, derived_key);
        }

        LOG(ERROR) << "No valid connection state";
        return false;
    }

    /*
     * Derive key using AIDL Keymint
     */
    bool deriveKeyAidl(const std::vector<uint8_t>& entropy,
                       const std::vector<uint8_t>& application_id,
                       std::vector<uint8_t>& derived_key) {
        if (aidl_keymint_ == nullptr) {
            LOG(ERROR) << "AIDL Keymint not connected";
            return false;
        }

        // Build key parameters for FBE key derivation
        std::vector<KeyParameter> params;

        KeyParameter param;
        param.tag = Tag::PURPOSE;
        param.value = KeyParameterValue(KeyPurpose::DERIVE_KEY);
        params.push_back(param);

        param.tag = Tag::ALGORITHM;
        param.value = KeyParameterValue(Algorithm::AES);
        params.push_back(param);

        param.tag = Tag::KEY_SIZE;
        param.value = KeyParameterValue(256);
        params.push_back(param);

        param.tag = Tag::BLOCK_MODE;
        param.value = KeyParameterValue(BlockMode::XTS);
        params.push_back(param);

        param.tag = Tag::PADDING;
        param.value = KeyParameterValue(PaddingMode::NONE);
        params.push_back(param);

        param.tag = Tag::SECURITY_LEVEL;
        param.value = KeyParameterValue(SecurityLevel::TRUSTED_ENVIRONMENT);
        params.push_back(param);

        // Create key with entropy
        KeyCreationResult result;
        auto status = aidl_keymint_->generateKey(params, entropy, &result);

        if (!status.isOk()) {
            LOG(ERROR) << "Failed to generate key: " << status.getDescription();
            return false;
        }

        if (result.keyBlob.empty()) {
            LOG(ERROR) << "Empty key blob returned";
            return false;
        }

        derived_key = result.keyBlob;
        LOG(INFO) << "Successfully derived key via AIDL Keymint, size: " << derived_key.size();
        return true;
    }

    /*
     * Derive key using HIDL Keymaster
     */
    bool deriveKeyHidl(const std::vector<uint8_t>& entropy,
                       const std::vector<uint8_t>& application_id,
                       std::vector<uint8_t>& derived_key) {
        if (hidl_keymaster_ != nullptr) {
            return deriveKeyHidl41(entropy, application_id, derived_key);
        } else if (hidl_keymaster_v4_ != nullptr) {
            return deriveKeyHidl40(entropy, application_id, derived_key);
        }

        LOG(ERROR) << "No HIDL Keymaster connection";
        return false;
    }

    bool deriveKeyHidl41(const std::vector<uint8_t>& entropy,
                         const std::vector<uint8_t>& application_id,
                         std::vector<uint8_t>& derived_key) {
        // Build key parameters
        hidl_vec<KeyParameter> params;
        params.resize(5);

        params[0].tag = Tag::PURPOSE;
        params[0].f.member = KeyParameterValue::make<KeyParameterValue::Tag::ENUM_VALUE>(
            static_cast<uint32_t>(KeyPurpose::DERIVE_KEY));

        params[1].tag = Tag::ALGORITHM;
        params[1].f.member = KeyParameterValue::make<KeyParameterValue::Tag::ENUM_VALUE>(
            static_cast<uint32_t>(Algorithm::AES));

        params[2].tag = Tag::KEY_SIZE;
        params[2].f.member = KeyParameterValue::make<KeyParameterValue::Tag::INTEGER>(256);

        params[3].tag = Tag::BLOCK_MODE;
        params[3].f.member = KeyParameterValue::make<KeyParameterValue::Tag::ENUM_VALUE>(
            static_cast<uint32_t>(BlockMode::XTS));

        params[4].tag = Tag::PADDING;
        params[4].f.member = KeyParameterValue::make<KeyParameterValue::Tag::ENUM_VALUE>(
            static_cast<uint32_t>(PaddingMode::NONE));

        auto cb = [&](ErrorCode error, const hidl_vec<uint8_t>& keyBlob,
                      const hidl_vec<KeyCharacteristics>& characteristics) {
            if (error == ErrorCode::OK) {
                derived_key.assign(keyBlob.begin(), keyBlob.end());
                LOG(INFO) << "Key derived via HIDL 4.1, size: " << derived_key.size();
            } else {
                LOG(ERROR) << "HIDL 4.1 generateKey failed: " << toString(error);
            }
        };

        hidl_keymaster_->generateKey(params, cb);
        return !derived_key.empty();
    }

    bool deriveKeyHidl40(const std::vector<uint8_t>& entropy,
                         const std::vector<uint8_t>& application_id,
                         std::vector<uint8_t>& derived_key) {
        // Similar implementation for V4.0
        hidl_vec<KeyParameter> params;
        params.resize(5);

        params[0].tag = Tag::PURPOSE;
        params[0].f.integer = static_cast<uint32_t>(KeyPurpose::DERIVE_KEY);

        params[1].tag = Tag::ALGORITHM;
        params[1].f.integer = static_cast<uint32_t>(Algorithm::AES);

        params[2].tag = Tag::KEY_SIZE;
        params[2].f.integer = 256;

        params[3].tag = Tag::BLOCK_MODE;
        params[3].f.integer = static_cast<uint32_t>(BlockMode::XTS);

        params[4].tag = Tag::PADDING;
        params[4].f.integer = static_cast<uint32_t>(PaddingMode::NONE);

        auto cb = [&](ErrorCode error, const hidl_vec<uint8_t>& keyBlob,
                      const hidl_vec<KeyCharacteristics>& characteristics) {
            if (error == ErrorCode::OK) {
                derived_key.assign(keyBlob.begin(), keyBlob.end());
                LOG(INFO) << "Key derived via HIDL 4.0, size: " << derived_key.size();
            } else {
                LOG(ERROR) << "HIDL 4.0 generateKey failed: " << toString(error);
            }
        };

        hidl_keymaster_v4_->generateKey(params, cb);
        return !derived_key.empty();
    }

    /*
     * Check if gatekeeper is available for PIN/password verification
     */
    bool isGatekeeperReady() {
        // Check property
        int gatekeeper_ready = android::base::GetIntProperty("ro.vendor.gatekeeper.ready", 0);
        if (gatekeeper_ready == 1) {
            return true;
        }

        // Try to connect directly
        ::ndk::SpAIBinder binder(AServiceManager_getService("android.hardware.gatekeeper.IGatekeeper/default"));
        return binder.get() != nullptr;
    }

    /*
     * Get connection state for debugging
     */
    ConnectionState getState() const { return state_; }
    bool isReady() const { return service_ready_; }
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
