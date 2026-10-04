import Foundation

/// One recorded app-activity span, reduced to what billing derivation needs.
/// The host reads it from its own activity table; billing never writes it
/// except to stamp the derivation watermark.
public struct BillingAppSpanRow: Sendable, Equatable {
    public let id: String
    public let bundleId: String
    public let appName: String
    public let windowTitle: String
    /// "" = unresolved.
    public let workingPath: String
    /// The main repo root (parent of the git common dir); "" = no repo.
    public let repoRoot: String
    public let branch: String
    /// ISO-8601 UTC.
    public let startedAt: String
    /// "" = open.
    public let endedAt: String
    // swiftlint:disable:next identifier_name
    public let tz: String

    public init(
        id: String, bundleId: String, appName: String, windowTitle: String,
        workingPath: String, repoRoot: String, branch: String,
        // swiftlint:disable:next identifier_name
        startedAt: String, endedAt: String, tz: String
    ) {
        self.id = id
        self.bundleId = bundleId
        self.appName = appName
        self.windowTitle = windowTitle
        self.workingPath = workingPath
        self.repoRoot = repoRoot
        self.branch = branch
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.tz = tz
    }

    /// The billing segment session id this span's runs are stored under —
    /// the one marker that tells an app segment from a Claude one.
    public var sessionId: String { ActivitySpanSession.sessionId(spanId: id) }
}

/// One recorded stretch with no user input.
public struct BillingIdleInterval: Sendable, Equatable {
    /// The last input before the gap.
    public let idleFrom: String
    /// "" = still idle.
    public let idleUntil: String

    public init(idleFrom: String, idleUntil: String) {
        self.idleFrom = idleFrom
        self.idleUntil = idleUntil
    }
}
