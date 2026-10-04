import Foundation

/// Seam for a future usage-data sync to the agentic-developer-hub (adh).
///
/// Not wired into `UsageCollector` or `DaemonDelegate`: usage capture stays
/// local-only today (c4), with no network calls anywhere in the capture
/// path. This protocol exists only so a real adh-backed implementation can
/// be swapped in later without any change to `UsageStore`/`UsageCollector`.
public protocol UsageSyncService: Sendable {
    /// Uploads a batch of already-recorded usage segments. Implementations
    /// own their own batching/retry/backoff; a single call represents one
    /// attempt.
    func sync(_ records: [UsageSyncRecord]) async throws
}

/// A minimal, storage-agnostic snapshot of a recorded focus segment —
/// deliberately decoupled from `UsageStore`'s internal `FocusSegment` so this
/// seam doesn't force that (currently internal) type public.
public struct UsageSyncRecord: Equatable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let appBundleID: String
    public let windowTitle: String

    public init(id: UUID, startedAt: Date, endedAt: Date?, appBundleID: String, windowTitle: String) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.appBundleID = appBundleID
        self.windowTitle = windowTitle
    }
}

/// The default — and today, only — `UsageSyncService`: performs no network
/// I/O and never fails. Usage stays fully local-only (c4) until a real
/// adh-backed sync service replaces this.
public struct LocalOnlyUsageSyncService: UsageSyncService {
    public init() {}
    public func sync(_ records: [UsageSyncRecord]) async throws {}
}
