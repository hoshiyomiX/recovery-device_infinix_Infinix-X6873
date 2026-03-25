/*
 * Copyright (C) 2025 The Android Open Source Project
 * Copyright (C) 2025 TWRP Device Tree for Infinix X6873
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <android-base/properties.h>

#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

using android::base::GetProperty;
using std::string;

void property_override(string prop, string value)
{
    auto pi = (prop_info *)__system_property_find(prop.c_str());

    if (pi != nullptr)
        __system_property_update(pi, value.c_str(), value.size());
    else
        __system_property_add(prop.c_str(), prop.size(), value.c_str(), value.size());
}

void vendor_load_properties()
{
    string prop_partitions[] = {"", "vendor.", "odm.", "product.", "system_ext."};
    for (const string &prop : prop_partitions)
    {
        property_override(string("ro.product.") + prop + string("brand"), "INFINIX");
        property_override(string("ro.product.") + prop + string("name"), "X6873-OP");
        property_override(string("ro.product.") + prop + string("device"), "Infinix-X6873");
        property_override(string("ro.product.") + prop + string("model"), "Infinix GT 30 Pro");
        property_override(string("ro.product.") + prop + string("marketname"), "Infinix GT 30 Pro");
        property_override(string("ro.product.") + prop + string("manufacturer"), "Infinix");
    }

    // Device specific properties
    property_override("ro.build.product", "Infinix-X6873");
    property_override("ro.product.device", "Infinix-X6873");
    property_override("ro.product.model", "Infinix GT 30 Pro");
    property_override("ro.product.brand", "INFINIX");
    property_override("ro.product.name", "X6873-OP");
    property_override("ro.product.manufacturer", "Infinix");

    // TEE properties
    property_override("ro.hardware.gatekeeper", "trustonic");
    property_override("ro.hardware.keystore_keymint", "trustonic");
    property_override("ro.hardware.keystore", "trustonic");
    property_override("ro.vendor.mtk_trustonic_tee_support", "1");

    // Platform
    property_override("ro.board.platform", "mt6897");
    property_override("ro.mediatek.platform", "mt6897");

    // Keymint version
    property_override("keymaster_ver", "4.1");
}

int main()
{
    vendor_load_properties();
    return 0;
}
