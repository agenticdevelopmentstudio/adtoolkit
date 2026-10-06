import Foundation

/// Carries an app's saved settings across a bundle-identifier change. The
/// standard defaults domain IS the bundle id, so renaming the bundle silently
/// starts the app on an empty domain and every setting the user made is gone.
///
/// Merges the legacy domain into the new one exactly once: every legacy key
/// the new domain lacks is copied, and a key the new domain already holds is
/// the user's latest word and is never overwritten. It merges rather than
/// copying only into an empty domain because the new domain is rarely empty in
/// practice — a development build run under the new id, or anything that wrote
/// one key there first, would otherwise skip the migration for good and lose
/// every window position and setting. A marker key in the new domain records
/// the merge so it never runs twice. The legacy domain is left in place — it
/// costs a plist, and deleting it would make a downgrade lose everything.
public enum DefaultsDomainMigration {
    /// The key, in the new domain, recording that `legacyDomain` was merged.
    public static func markerKey(for legacyDomain: String) -> String {
        "DefaultsDomainMigration.merged.\(legacyDomain)"
    }

    /// - Returns: `true` when settings were copied.
    @discardableResult
    public static func migrateIfNeeded(
        from legacyDomain: String,
        to domain: String,
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard legacyDomain != domain,
              let legacy = defaults.persistentDomain(forName: legacyDomain),
              !legacy.isEmpty else { return false }
        var merged = defaults.persistentDomain(forName: domain) ?? [:]
        let marker = markerKey(for: legacyDomain)
        guard merged[marker] == nil else { return false }
        let missing = legacy.filter { merged[$0.key] == nil }
        merged.merge(missing) { current, _ in current }
        merged[marker] = true
        defaults.setPersistentDomain(merged, forName: domain)
        return !missing.isEmpty
    }
}
