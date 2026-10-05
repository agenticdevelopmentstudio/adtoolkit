import Foundation

public struct WorkTrackingPreferences: Codable, Sendable, Equatable {
    public var enabled: Bool
    public var addedBundleIds: [String]
    public var removedBundleIds: [String]
    public var retentionDays: Int

    public static let defaultRetentionDays = 90
    public static let retentionDaysRange = 7...3650
    public static let `default` = WorkTrackingPreferences(enabled: false, addedBundleIds: [], removedBundleIds: [],
                                                          retentionDays: defaultRetentionDays)

    public init(enabled: Bool, addedBundleIds: [String], removedBundleIds: [String], retentionDays: Int) {
        self.enabled = enabled
        self.addedBundleIds = addedBundleIds
        self.removedBundleIds = removedBundleIds
        self.retentionDays = retentionDays
    }

    /// Sorted, de-duplicated ids; retention clamped into range.
    public func normalized() -> WorkTrackingPreferences {
        WorkTrackingPreferences(
            enabled: enabled,
            addedBundleIds: Array(Set(addedBundleIds)).sorted(),
            removedBundleIds: Array(Set(removedBundleIds)).sorted(),
            retentionDays: BillingLimits.clamp(retentionDays, to: Self.retentionDaysRange))
    }
}

public enum WorkTrackingAccessibility: String, Codable, Sendable { case granted, denied, unknown }

public struct WorkTrackingStatus: Codable, Sendable, Equatable {
    public var enabled: Bool
    public var accessibility: WorkTrackingAccessibility
    public var currentSpan: ActivitySpanDTO?
    public var writeFailures: Int
    public var lastError: String?

    public init(enabled: Bool = false, accessibility: WorkTrackingAccessibility = .unknown,
                currentSpan: ActivitySpanDTO? = nil, writeFailures: Int = 0, lastError: String? = nil) {
        self.enabled = enabled
        self.accessibility = accessibility
        self.currentSpan = currentSpan
        self.writeFailures = writeFailures
        self.lastError = lastError
    }

    /// True when tracking is on but window reads are off.
    public var isDegraded: Bool { enabled && accessibility != .granted }
    public static let degradedNotice = "Tracking without Accessibility — time is unassigned."
}

/// How a work-tracking list reply says "that failed" (review F25) — the same
/// convention as `BillingWire.readFailedRow`.
public enum WorkTrackingWire {
    /// The snake-case key of the one-element list a failed list read replies.
    public static let readFailedKey = "work_tracking_read_failed"
    /// The whole element: `{"work_tracking_read_failed":true}`.
    public static let readFailedRow = Data("{\"\(readFailedKey)\":true}".utf8)
}

/// The daemon's `settings` keys for work tracking.
public enum WorkTrackingSettingsKeys {
    public static let enabled = "activity_enabled"
    public static let addedBundleIds = "activity_added_bundle_ids"      // JSON array
    public static let removedBundleIds = "activity_removed_bundle_ids"  // JSON array
    public static let retentionDays = "activity_retention_days"
    public static let accessibilityLastStatus = "activity_ax_last_status"
}

/// The prefix of a billing segment's session id when an app span made it.
public enum ActivitySpanSession {
    public static let prefix = "app:"
    public static func sessionId(spanId: String) -> String { prefix + spanId }
    public static func spanId(sessionId: String) -> String? {
        sessionId.hasPrefix(prefix) ? String(sessionId.dropFirst(prefix.count)) : nil
    }
}
