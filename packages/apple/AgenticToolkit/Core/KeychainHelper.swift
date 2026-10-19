import Foundation
import Security
import os

/// Provides simple CRUD operations for storing secrets in the macOS Keychain.
/// Uses generic password items scoped to a configurable service identifier.
public enum KeychainHelper {

    /// The Keychain service identifier. Defaults to the main bundle identifier.
    nonisolated(unsafe) public static var service: String = Bundle.main.bundleIdentifier ?? "com.agentictoolkit"

    /// Optional shared Keychain access group. When set, items are scoped to this
    /// group so multiple signed binaries (e.g. an app and its daemon) carrying the
    /// matching `keychain-access-groups` entitlement can share them. `nil` (the
    /// default) preserves the original per-binary behavior.
    nonisolated(unsafe) public static var accessGroup: String?

    /// Keep secrets in the data-protection keychain, under the app's default
    /// access group, instead of the file-based login keychain.
    ///
    /// The login keychain guards each item with an ACL naming the binary that
    /// wrote it, so a build signed differently — a Developer ID release after a
    /// development build, or the reverse — gets one password prompt per item.
    /// The data-protection keychain is guarded by the team's access group
    /// instead, which every build the team signs carries, so nothing prompts.
    /// It needs the `keychain-access-groups` entitlement (and the profile that
    /// grants it): set this only in a binary that has one. No explicit group is
    /// passed, so an app signed under a wildcard team profile is not refused.
    ///
    /// A secret still in the login keychain is found on a miss and re-stored
    /// here — that one read may prompt, once. The old copy is left where it is,
    /// like a retired service's, and `delete` removes it too.
    nonisolated(unsafe) public static var usesDataProtectionKeychain = false

    /// Whether the file-based login keychain can hold a copy `get` should
    /// recover: true whenever this helper writes somewhere else.
    private static var readsFileKeychainFallback: Bool {
        accessGroup != nil || usesDataProtectionKeychain
    }

    /// Service identifiers this app used to write under, newest first.
    ///
    /// The service defaults to the bundle identifier, so changing the bundle
    /// identifier — a rename, a new reverse-DNS prefix — orphans every secret
    /// the app has ever stored. Nothing surfaces: `get` returns `nil` and the
    /// feature behaves as though the user never entered the key. Listing the
    /// retired identifiers here lets `get` find one and re-store it under the
    /// current service, the same shape as the access-group recovery below.
    ///
    /// Recovering a legacy item leaves it where it is: another install may
    /// still be using it. `delete` removes it too, because a secret the user
    /// cleared must stay cleared — otherwise the next `get` would recover the
    /// old copy and bring the cleared secret back.
    nonisolated(unsafe) public static var legacyServices: [String] = []

    /// The entry of this process's `keychain-access-groups` entitlement whose
    /// group is `group` — `"<team>.com.example.shared"` for
    /// `"com.example.shared"` — or nil when the binary carries none.
    ///
    /// The team prefix is the signer's (`$(AppIdentifierPrefix)` in the
    /// entitlements file), so it is read off the running code rather than
    /// spelled in source, where it goes stale the moment the build is signed by
    /// another team. Read through `SecTaskCreateFromSelf`, which reports what
    /// the kernel granted, not what a file on disk says.
    public static func entitledAccessGroup(_ group: String) -> String? {
        guard let task = SecTaskCreateFromSelf(nil),
              let groups = SecTaskCopyValueForEntitlement(task, "keychain-access-groups" as CFString, nil)
                as? [String]
        else { return nil }
        return groups.first { $0 == group || $0.hasSuffix("." + group) }
    }

    /// Builds the base generic-password query for an account key. When an access
    /// group is in play, scopes the item to it and forces the macOS data-protection
    /// keychain (required for access groups on macOS). Without one,
    /// `dataProtection` alone picks the data-protection keychain.
    static func makeQuery(
        account: String,
        accessGroup: String? = KeychainHelper.accessGroup,
        dataProtection: Bool = KeychainHelper.usesDataProtectionKeychain,
        service: String = KeychainHelper.service
    ) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
            query[kSecUseDataProtectionKeychain as String] = true
        } else if dataProtection {
            query[kSecUseDataProtectionKeychain as String] = true
        }
        return query
    }

    /// Stores a value in the Keychain for the given account key.
    /// Overwrites any existing value for the same key.
    @discardableResult
    public static func set(_ value: String, forKey key: String) -> Bool {
        let data = Data(value.utf8)
        deleteItem(makeQuery(account: key))

        var query = makeQuery(account: key)
        query[kSecValueData as String] = data
        if readsFileKeychainFallback {
            // Data-protection items default to `WhenUnlocked`. A co-signed daemon may
            // run before first unlock or while the screen is locked, so make shared
            // secrets readable after first unlock. `ThisDeviceOnly`: local app↔daemon
            // secrets must never sync to iCloud or migrate off this machine.
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Keychain set failed for '\(key, privacy: .public)': \(status)")
        }
        return status == errSecSuccess
    }

    /// Retrieves a value from the Keychain for the given account key.
    public static func get(forKey key: String) -> String? {
        if let value = copyValue(forKey: key, accessGroup: accessGroup) {
            return value
        }
        // Legacy migration: secrets written before an access group was configured live
        // in the default keychain and are invisible to access-group / data-protection
        // queries (and to a co-signed daemon). Recover one if present and re-store it
        // under the current group so future reads — including the daemon's — succeed.
        if readsFileKeychainFallback,
           let legacy = copyValue(forKey: key, accessGroup: nil, dataProtection: false) {
            set(legacy, forKey: key)
            return legacy
        }
        // Retired-service migration: the service defaults to the bundle
        // identifier, so a bundle-identifier change leaves every secret behind
        // under the old one. Recover the newest and re-store it under the
        // current service. The old item is left where it is.
        for legacyService in legacyServices {
            if let legacy = copyValue(forKey: key, accessGroup: accessGroup, service: legacyService)
                ?? (readsFileKeychainFallback
                    ? copyValue(forKey: key, accessGroup: nil, dataProtection: false, service: legacyService)
                    : nil) {
                logger.info("Recovered '\(key, privacy: .public)' from retired Keychain service")
                set(legacy, forKey: key)
                return legacy
            }
        }
        return nil
    }

    /// Copies the stored string for an account, scoped to the given access group.
    private static func copyValue(
        forKey key: String,
        accessGroup: String?,
        dataProtection: Bool = KeychainHelper.usesDataProtectionKeychain,
        service: String = KeychainHelper.service
    ) -> String? {
        var query = makeQuery(
            account: key, accessGroup: accessGroup, dataProtection: dataProtection, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                logger.error("Keychain get failed for '\(key, privacy: .public)': \(status)")
            }
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Deletes the Keychain item for the given account key, along with any
    /// copy under a retired service (``legacyServices``) that `get` would
    /// otherwise recover.
    @discardableResult
    public static func delete(forKey key: String) -> Bool {
        var deleted = deleteItem(makeQuery(account: key))
        if readsFileKeychainFallback {
            deleted = deleteItem(makeQuery(account: key, accessGroup: nil, dataProtection: false)) && deleted
        }
        for legacyService in legacyServices {
            deleted = deleteItem(makeQuery(account: key, service: legacyService)) && deleted
            if readsFileKeychainFallback {
                deleted = deleteItem(makeQuery(
                    account: key, accessGroup: nil, dataProtection: false, service: legacyService)) && deleted
            }
        }
        return deleted
    }

    @discardableResult
    private static func deleteItem(_ query: [String: Any]) -> Bool {
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Returns whether a value exists in the Keychain for the given key.
    ///
    /// Retired services count. An item `get` would recover is present as far
    /// as any caller is concerned, and answering `false` here would have a
    /// settings pane render an empty field over a stored secret. This probe
    /// does not migrate — the first `get` does that.
    public static func exists(forKey key: String) -> Bool {
        var query = makeQuery(account: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            return true
        }
        // Asking whether an item exists reads no secret, so the login
        // keychain answers without a prompt.
        func present(_ query: [String: Any]) -> Bool {
            var query = query
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
        }
        if readsFileKeychainFallback,
           present(makeQuery(account: key, accessGroup: nil, dataProtection: false)) {
            return true
        }
        return legacyServices.contains { legacyService in
            present(makeQuery(account: key, service: legacyService))
                || (readsFileKeychainFallback
                    && present(makeQuery(
                        account: key, accessGroup: nil, dataProtection: false, service: legacyService)))
        }
    }
}

extension KeychainHelper: Loggable {
    public static nonisolated let logger = makeLogger()
}
