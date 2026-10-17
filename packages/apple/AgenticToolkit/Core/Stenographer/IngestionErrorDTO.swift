import Foundation

/// One quarantined hook-event file the daemon could not ingest, surfaced to the
/// app (XPC) and CLI (HTTP). `reason` is read from the file's `.meta.json`
/// sidecar, or a placeholder for files quarantined before reason capture.
/// `retryCount` / `exhausted` reflect the self-healing retry budget.
public struct IngestionErrorDTO: Codable, Sendable {
    public let filename: String
    public let eventType: String
    public let sessionId: String
    public let quarantinedAt: String
    public let reason: String
    /// Failed self-healing retries so far (0 = not yet retried).
    public let retryCount: Int
    /// ISO-8601 time of the most recent retry, or nil if never retried.
    public let lastRetriedAt: String?
    /// True once `retryCount` reaches the configured max — these are what the
    /// menubar alert badge counts.
    public let exhausted: Bool

    public init(
        filename: String,
        eventType: String,
        sessionId: String,
        quarantinedAt: String,
        reason: String,
        retryCount: Int = 0,
        lastRetriedAt: String? = nil,
        exhausted: Bool = false
    ) {
        self.filename = filename
        self.eventType = eventType
        self.sessionId = sessionId
        self.quarantinedAt = quarantinedAt
        self.reason = reason
        self.retryCount = retryCount
        self.lastRetriedAt = lastRetriedAt
        self.exhausted = exhausted
    }
}

/// One row of the persistent ingestion-error log (DB table `ingestion_errors`),
/// surfaced over HTTP at `GET /ingestion/errors/log` for tracking and fixing
/// recurring failures. Unlike `IngestionErrorDTO` (a live file still on disk),
/// this includes resolved history: `status` is `failing` | `exhausted` |
/// `recovered` | `cleared` | `lost`. `lost` is a drop file that arrived empty —
/// its event is gone, so it is recorded once and never retried or counted as a
/// live failure.
public struct IngestionErrorLogDTO: Codable, Sendable {
    public let filename: String
    public let eventType: String
    public let sessionId: String
    public let reason: String
    public let sqliteCode: Int?
    public let quarantinedAt: String
    public let retryCount: Int
    public let lastRetriedAt: String?
    public let status: String
    public let resolvedAt: String?
    public let updatedAt: String

    public init(
        filename: String,
        eventType: String,
        sessionId: String,
        reason: String,
        sqliteCode: Int?,
        quarantinedAt: String,
        retryCount: Int,
        lastRetriedAt: String?,
        status: String,
        resolvedAt: String?,
        updatedAt: String
    ) {
        self.filename = filename
        self.eventType = eventType
        self.sessionId = sessionId
        self.reason = reason
        self.sqliteCode = sqliteCode
        self.quarantinedAt = quarantinedAt
        self.retryCount = retryCount
        self.lastRetriedAt = lastRetriedAt
        self.status = status
        self.resolvedAt = resolvedAt
        self.updatedAt = updatedAt
    }
}

/// Live progress of a "Retry All" batch. The retry runs asynchronously on the
/// daemon (off the XPC/HTTP reply thread, so a large backlog can't time the
/// caller out); the UI starts it, then polls this until `running == false`.
/// `total` is the batch size; `processed` counts files attempted so far;
/// `recovered` ingested and were removed; `stillFailing` are still quarantined.
public struct RetryProgressDTO: Codable, Sendable {
    public let running: Bool
    public let total: Int
    public let processed: Int
    public let recovered: Int
    public let stillFailing: Int

    public init(running: Bool, total: Int, processed: Int, recovered: Int, stillFailing: Int) {
        self.running = running
        self.total = total
        self.processed = processed
        self.recovered = recovered
        self.stillFailing = stillFailing
    }
}
