import Foundation
import LocalAuthentication
import Security

/// The privacy words — alias and real pairs — kept in the keychain and nowhere
/// else: no defaults, no database, no file.
///
/// One item, its value the pairs as JSON. The item is guarded by
/// `userPresence`, so the keychain itself refuses to hand it over until the
/// user has authenticated — Touch ID or the account password — rather than this
/// code promising to ask first. Reads take the `LAContext` the user already
/// authenticated with, so revealing costs one prompt, not two.
///
/// `ThisDeviceOnly` and never synchronizable: the words name the user, and
/// they stay on the Mac they were typed on.
///
/// The access group is the caller's, because it is what lets several apps
/// signed by one team share the list, and which group that is belongs to the
/// app's entitlements, not to this type (`dependency-injection`). Access
/// control needs the data-protection keychain, so the binary must carry a
/// `keychain-access-groups` entitlement either way.
public struct PrivacyWordStore: Sendable {

    public enum StoreError: Error, LocalizedError, Equatable {
        case authenticationFailed(String)
        case keychain(OSStatus)
        case unreadable

        public var errorDescription: String? {
            switch self {
            case .authenticationFailed(let reason): reason
            case .keychain(let status):
                (SecCopyErrorMessageString(status, nil) as String?) ?? "Keychain error \(status)."
            case .unreadable: "The privacy words in the keychain could not be read."
            }
        }
    }

    public let accessGroup: String?
    public let service: String
    public let account: String

    public init(
        accessGroup: String?,
        service: String = "com.agenticdevelopmentstudio.privacy-words",
        account: String = "privacy-words"
    ) {
        self.accessGroup = accessGroup
        self.service = service
        self.account = account
    }

    /// Asks the user to prove they are the Mac's owner — Touch ID, or the
    /// account password — and returns the context that proved it.
    public static func authenticate(reason: String) async throws -> LAContext {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw StoreError.authenticationFailed(
                error?.localizedDescription ?? "This Mac cannot authenticate its owner.")
        }
        nonisolated(unsafe) let unsafeContext = context
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            unsafeContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: StoreError.authenticationFailed(
                        error?.localizedDescription ?? "Authentication failed."))
                }
            }
        }
        return context
    }

    /// The stored pairs, read with an authenticated `context`. Empty when
    /// nothing has been saved yet.
    public func load(context: LAContext) throws -> [TextSubstitutionFilter.Pair] {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = context
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
        guard let data = result as? Data,
              let pairs = try? JSONDecoder().decode([TextSubstitutionFilter.Pair].self, from: data) else {
            throw StoreError.unreadable
        }
        return pairs
    }

    /// Replaces the stored pairs. An empty list removes the item.
    public func save(_ pairs: [TextSubstitutionFilter.Pair]) throws {
        let deleted = SecItemDelete(baseQuery as CFDictionary)
        guard deleted == errSecSuccess || deleted == errSecItemNotFound else {
            throw StoreError.keychain(deleted)
        }
        guard !pairs.isEmpty else { return }

        var accessError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .userPresence, &accessError
        ) else {
            throw StoreError.keychain(errSecParam)
        }
        var query = baseQuery
        query[kSecValueData as String] = try JSONEncoder().encode(pairs)
        query[kSecAttrAccessControl as String] = access
        query[kSecAttrLabel as String] = "Privacy words"
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
    }

    private var baseQuery: [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrSynchronizable as String: false
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }
}
