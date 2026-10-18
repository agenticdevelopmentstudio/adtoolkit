import Foundation

/// Remembers which provider configurations one host has pushed to the daemon, so a
/// later push can name exactly the ones it dropped (`AIProviderConfigSync.removedConfigIds`)
/// instead of asking the daemon to delete everything it was not sent.
///
/// Two hosts (the Kitchen over HTTP, the Stenographer app over XPC) share one daemon
/// registry. Each keeps its own ledger under its own key, so neither ever deletes a
/// configuration it did not push itself.
public struct AIConfigPushLedger: Sendable {

    public let key: String
    /// `UserDefaults` is documented thread-safe; the SDK just has not marked it `Sendable`.
    private nonisolated(unsafe) let defaults: UserDefaults

    public init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    /// The ids recorded by the last successful push.
    public func lastPushed() -> Set<UUID> {
        Set((defaults.stringArray(forKey: key) ?? []).compactMap(UUID.init(uuidString:)))
    }

    /// The ids this host pushed before and no longer has configured. `configured` is
    /// every configuration the host holds now, resolvable or not, so a configuration
    /// that is merely unresolvable this time is not deleted.
    public func removed(configured: [UUID]) -> [UUID] {
        lastPushed().subtracting(configured).sorted { $0.uuidString < $1.uuidString }
    }

    /// Records a push that landed: what it sent, plus what it kept tracking (the
    /// previously pushed ids it did not remove).
    public func recordLanded(_ sync: AIProviderConfigSync) {
        let removed = Set(sync.removedConfigIds ?? [])
        let next = Set(sync.configs.map(\.id)).union(lastPushed().subtracting(removed))
        defaults.set(next.map(\.uuidString).sorted(), forKey: key)
    }
}
