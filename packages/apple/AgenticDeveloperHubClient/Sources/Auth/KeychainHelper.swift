import Foundation
import Security
import os

/// Simple CRUD over macOS Keychain generic-password items, scoped to a
/// configurable service identifier.
///
/// Vendored from an internal `KeychainHelper`, with the `Loggable`
/// dependency dropped so this module stays dependency-free.
public enum KeychainHelper {

    /// The Keychain service identifier. Defaults to the main bundle identifier.
    nonisolated(unsafe) public static var service: String =
        Bundle.main.bundleIdentifier ?? "com.mikefullerton.AgenticDeveloperHubClient"

    private static let logger = Logger(
        subsystem: "com.mikefullerton.AgenticDeveloperHubClient",
        category: "Keychain"
    )

    /// Keep items in the data-protection keychain, under the app's default
    /// access group, instead of the file-based login keychain (macOS only;
    /// iOS has only the one keychain).
    ///
    /// The login keychain guards each item with an ACL naming the binary that
    /// wrote it, so a build signed differently — a Developer ID release after a
    /// development build, or the reverse — gets one password prompt per item.
    /// The data-protection keychain is guarded by the team's access group,
    /// which every build the team signs carries, so nothing prompts. It needs
    /// the `keychain-access-groups` entitlement: set this only in an app that
    /// has one.
    ///
    /// An item still in the login keychain is found on a miss, moved here, and
    /// deleted from there — not left behind like a static secret would be,
    /// because a refresh token rotates, and a stale copy another build
    /// refreshed would void the live one. That one read may prompt, once.
    nonisolated(unsafe) public static var usesDataProtectionKeychain = false

    /// The identifying attributes of one item, in the keychain this helper
    /// writes to — or, with `fileKeychain`, in the login keychain it may be
    /// migrating out of.
    private static func query(forKey key: String, fileKeychain: Bool = false) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        #if os(macOS)
        if usesDataProtectionKeychain && !fileKeychain {
            query[kSecUseDataProtectionKeychain as String] = true
        }
        #endif
        return query
    }

    /// Stores a value for the given account key, overwriting any existing value.
    ///
    /// On iOS — and on macOS with `usesDataProtectionKeychain` — the item is
    /// stored with an explicit accessibility class,
    /// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: `AfterFirstUnlock`
    /// (not `WhenUnlocked`, the implicit default) because background refresh
    /// must be able to read the token while the device is locked after its
    /// first unlock, and `ThisDeviceOnly` because a bearer token should never
    /// ride device backups or keychain sync onto another device. Because this
    /// method always deletes-then-adds, an existing item picks up the class
    /// on its next save — no separate migration step. A login-keychain copy is
    /// deleted only once the new item is in, so a failed add loses nothing.
    ///
    /// The file-based login keychain is left on the implicit default: it
    /// ignores (and in some OS versions rejects with `errSecParam`)
    /// `kSecAttrAccessible`.
    @discardableResult
    public static func set(_ value: String, forKey key: String) -> Bool {
        let data = Data(value.utf8)
        remove(query(forKey: key))

        var item = query(forKey: key)
        item[kSecValueData as String] = data
        #if os(iOS)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        #else
        if usesDataProtectionKeychain {
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
        #endif

        let status = SecItemAdd(item as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Keychain set failed for '\(key, privacy: .public)': \(status)")
            return false
        }
        if usesDataProtectionKeychain {
            remove(query(forKey: key, fileKeychain: true))
        }
        return true
    }

    /// Retrieves the value for the given account key, if present.
    public static func get(forKey key: String) -> String? {
        if let value = copyValue(query(forKey: key), key: key) {
            return value
        }
        #if os(macOS)
        if usesDataProtectionKeychain,
           let legacy = copyValue(query(forKey: key, fileKeychain: true), key: key) {
            // set() deletes the login-keychain copy once the new one is in.
            set(legacy, forKey: key)
            return legacy
        }
        #endif
        return nil
    }

    private static func copyValue(_ identity: [String: Any], key: String) -> String? {
        var query = identity
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

    /// Deletes the item for the given account key — in the login keychain as
    /// well, when items are kept elsewhere, so a cleared session stays cleared.
    @discardableResult
    public static func delete(forKey key: String) -> Bool {
        var deleted = remove(query(forKey: key))
        if usesDataProtectionKeychain {
            deleted = remove(query(forKey: key, fileKeychain: true)) && deleted
        }
        return deleted
    }

    @discardableResult
    private static func remove(_ query: [String: Any]) -> Bool {
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Whether a value exists for the given key — including one `get` would
    /// still move out of the login keychain. Asking reads no secret, so the
    /// login keychain answers without a prompt.
    public static func exists(forKey key: String) -> Bool {
        func present(_ query: [String: Any]) -> Bool {
            var query = query
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
        }
        return present(query(forKey: key))
            || (usesDataProtectionKeychain && present(query(forKey: key, fileKeychain: true)))
    }
}
