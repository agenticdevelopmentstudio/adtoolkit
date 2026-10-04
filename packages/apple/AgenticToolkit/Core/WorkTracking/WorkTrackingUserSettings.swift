import Foundation

/// The work-tracking knobs as live ``UserSetting``s, stored under
/// `prefix + WorkTrackingSettingsKeys.*` — the app decides only the prefix,
/// the same way ``BillingUserSettings`` does.
@MainActor
public final class WorkTrackingUserSettings {

    public let enabled: UserSetting<Bool>
    public let addedBundleIds: UserSetting<[String]>
    public let removedBundleIds: UserSetting<[String]>
    public let retentionDays: UserSetting<Int>

    public init(prefix: String) {
        let defaults = WorkTrackingPreferences.default
        enabled = UserSetting(prefix + WorkTrackingSettingsKeys.enabled, default: defaults.enabled)
        addedBundleIds = UserSetting(prefix + WorkTrackingSettingsKeys.addedBundleIds, default: defaults.addedBundleIds)
        removedBundleIds = UserSetting(
            prefix + WorkTrackingSettingsKeys.removedBundleIds, default: defaults.removedBundleIds)
        retentionDays = UserSetting(prefix + WorkTrackingSettingsKeys.retentionDays, default: defaults.retentionDays)
    }

    /// The current values as one normalized snapshot.
    public var preferences: WorkTrackingPreferences {
        WorkTrackingPreferences(
            enabled: enabled.value, addedBundleIds: addedBundleIds.value,
            removedBundleIds: removedBundleIds.value, retentionDays: retentionDays.value
        ).normalized()
    }
}
