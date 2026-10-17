import Foundation
import AIPluginKit

/// In-memory `SecretStoring` shared by the daemon test bundles so neither ever touches the login Keychain. Previously each bundle
/// kept its own private copy; one authoritative fake keeps the behaviour (and the
/// removal-on-empty contract) identical across both.
///
/// Thread-safe: the functional harness hands this to the router, which reads and
/// writes it from the HTTP work queue while assertions run on the test thread.
final class InMemorySecretStore: SecretStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: String]
    /// Separate namespace standing in for the pre-pin fallback Keychain service, so
    /// tests can seed a legacy secret and assert `deleteLegacy` (and only it) clears it.
    private var legacyStorage: [String: String]

    init(_ initial: [String: String] = [:], legacy: [String: String] = [:]) {
        self.storage = initial
        self.legacyStorage = legacy
    }

    func get(forKey key: String) -> String? { lock.withLock { storage[key] } }

    @discardableResult
    func set(_ value: String, forKey key: String) -> Bool {
        lock.withLock { storage[key] = value }
        return true
    }

    @discardableResult
    func delete(forKey key: String) -> Bool {
        lock.withLock { storage[key] = nil }
        return true
    }

    @discardableResult
    func deleteLegacy(forKey key: String) -> Bool {
        lock.withLock { legacyStorage[key] = nil }
        return true
    }

    /// The currently-stored legacy-namespace keys, for asserting the one-time legacy
    /// cleanup removed the pre-pin credential.
    var legacyKeys: [String] { lock.withLock { Array(legacyStorage.keys) } }

    /// True when no secret is stored — used to assert the delete-on-empty path
    /// fully cleared the store rather than leaving a stale `""`.
    var isEmpty: Bool { lock.withLock { storage.isEmpty } }

    /// Snapshot of the currently-stored keys, for asserting that switching plugins
    /// wiped exactly the prior plugin's secrets.
    var allKeys: [String] { lock.withLock { Array(storage.keys) } }
}
