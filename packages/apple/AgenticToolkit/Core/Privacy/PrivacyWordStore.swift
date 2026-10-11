import Foundation
import LocalAuthentication
import Security

/// The privacy words — alias and real pairs — kept in the keychain and nowhere
/// else: no defaults, no database, no file.
///
/// One item, its value the pairs as JSON, readable by the apps in its access
/// group without a prompt while the Mac is unlocked. That is deliberate: a
/// private terminal needs the words from its first byte — they are what
/// conceals its output — so starting one must not ask. What asks is the app:
/// showing a private terminal, opening the words and saving them each take
/// ``authenticate(reason:)`` first.
///
/// Items saved before that were guarded by `userPresence`, which the keychain
/// will not hand over silently. ``load(context:)`` without a context reports
/// one as ``StoreError/needsAuthentication``; read with an authenticated
/// context and saved again, it is rewritten without the guard.
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
        /// The item is still guarded by `userPresence` and cannot be read
        /// without authenticating.
        case needsAuthentication
        case keychain(OSStatus)
        case unreadable

        public var errorDescription: String? {
            switch self {
            case .authenticationFailed(let reason): reason
            case .needsAuthentication: "The privacy words need you to authenticate once before they can be read."
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

    /// The stored pairs. Empty when nothing has been saved yet.
    ///
    /// - Parameter context: An authenticated context, for reading an item
    ///   saved under the old `userPresence` guard. Without one the read never
    ///   prompts, and such an item throws ``StoreError/needsAuthentication``.
    public func load(context: LAContext? = nil) throws -> [TextSubstitutionFilter.Pair] {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let silent = LAContext()
        silent.interactionNotAllowed = true
        query[kSecUseAuthenticationContext as String] = context ?? silent
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        if status == errSecInteractionNotAllowed || status == errSecAuthFailed { throw StoreError.needsAuthentication }
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

        var query = baseQuery
        query[kSecValueData as String] = try JSONEncoder().encode(pairs)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
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
