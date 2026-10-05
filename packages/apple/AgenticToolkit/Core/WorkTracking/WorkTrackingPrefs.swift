import Foundation

/// The settings storage work tracking reads and writes. The host conforms its
/// database (Stenographer's SQLite `DatabaseManager`), exactly as it does for
/// `BillingPersistence`, whose settings requirements these mirror.
public protocol WorkTrackingSettingsStore {
    /// The raw value stored under `key`; nil when it was never set.
    func setting(for key: String) throws -> String?
    func setSetting(_ key: String, _ value: String) throws
    /// Runs `body` atomically: every write lands, or none does.
    func transaction<T>(_ body: () throws -> T) throws -> T
}

/// Reads and writes the work-tracking settings under the keys
/// `WorkTrackingSettingsKeys` names. Everything written is normalized first
/// (sorted, de-duplicated ids; retention clamped), and everything read is
/// normalized too, so a hand-edited row still means the nearest valid value.
public enum WorkTrackingPrefs {

    /// The stored preferences; `WorkTrackingPreferences.default` for any key never set.
    public static func load(_ store: some WorkTrackingSettingsStore) throws -> WorkTrackingPreferences {
        let defaults = WorkTrackingPreferences.default
        let enabled = RawSetting.bool(try store.setting(for: WorkTrackingSettingsKeys.enabled),
                                      default: defaults.enabled)
        let added = decodeIds(try store.setting(for: WorkTrackingSettingsKeys.addedBundleIds))
        let removed = decodeIds(try store.setting(for: WorkTrackingSettingsKeys.removedBundleIds))
        let retention = RawSetting.int(try store.setting(for: WorkTrackingSettingsKeys.retentionDays),
                                       default: defaults.retentionDays,
                                       range: WorkTrackingPreferences.retentionDaysRange)
        return WorkTrackingPreferences(enabled: enabled, addedBundleIds: added, removedBundleIds: removed,
                                       retentionDays: retention).normalized()
    }

    /// Normalizes `prefs`, then writes every key in one transaction.
    public static func save(_ prefs: WorkTrackingPreferences, _ store: some WorkTrackingSettingsStore) throws {
        let normal = prefs.normalized()
        let added = try encodeIds(normal.addedBundleIds)
        let removed = try encodeIds(normal.removedBundleIds)
        try store.transaction {
            try store.setSetting(WorkTrackingSettingsKeys.enabled, normal.enabled ? "true" : "false")
            try store.setSetting(WorkTrackingSettingsKeys.addedBundleIds, added)
            try store.setSetting(WorkTrackingSettingsKeys.removedBundleIds, removed)
            try store.setSetting(WorkTrackingSettingsKeys.retentionDays, String(normal.retentionDays))
        }
    }

    /// The answer the last Accessibility check gave; `.unknown` when never checked.
    public static func lastAccessibility(_ store: some WorkTrackingSettingsStore) throws -> WorkTrackingAccessibility {
        let raw = try store.setting(for: WorkTrackingSettingsKeys.accessibilityLastStatus) ?? ""
        return WorkTrackingAccessibility(rawValue: raw) ?? .unknown
    }

    public static func setLastAccessibility(_ value: WorkTrackingAccessibility,
                                            _ store: some WorkTrackingSettingsStore) throws {
        try store.setSetting(WorkTrackingSettingsKeys.accessibilityLastStatus, value.rawValue)
    }

    // MARK: - Private

    /// A JSON array of strings; anything else (absent, empty, garbage) is no ids.
    private static func decodeIds(_ raw: String?) -> [String] {
        guard let data = raw?.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return ids
    }

    private static func encodeIds(_ ids: [String]) throws -> String {
        String(bytes: try JSONEncoder().encode(ids), encoding: .utf8) ?? "[]"
    }
}
