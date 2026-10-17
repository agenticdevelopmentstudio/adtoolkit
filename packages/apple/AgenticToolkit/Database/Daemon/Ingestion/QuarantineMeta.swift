#if canImport(AgenticToolkitCore)
import Foundation

/// Metadata written alongside a quarantined event file (`error-<name>.meta.json`)
/// recording *why* it could not be ingested and how many self-healing retries it
/// has survived. Read back by `QuarantineService` so the failure is inspectable
/// and recoverable through the Ingestion Errors surface instead of vanishing
/// into the log.
public struct QuarantineMeta: Codable, Sendable {
    public let reason: String
    public let sqliteCode: Int?
    public let quarantinedAt: String
    public let eventType: String
    public let sessionId: String
    /// How many ingest retries have been attempted since the file was first
    /// quarantined. `0` on first quarantine; bumped by each failed retry. Once
    /// it reaches the configured max the file is "exhausted" — auto-retry stops
    /// and the menubar alert badge lights. Absent in legacy sidecars (→ 0).
    public let retryCount: Int
    /// ISO-8601 timestamp of the most recent retry attempt; `nil` until the
    /// first retry. Drives oldest-first fairness in the periodic retry batch.
    public let lastRetriedAt: String?

    public init(
        reason: String,
        sqliteCode: Int?,
        quarantinedAt: String,
        eventType: String,
        sessionId: String,
        retryCount: Int = 0,
        lastRetriedAt: String? = nil
    ) {
        self.reason = reason
        self.sqliteCode = sqliteCode
        self.quarantinedAt = quarantinedAt
        self.eventType = eventType
        self.sessionId = sessionId
        self.retryCount = retryCount
        self.lastRetriedAt = lastRetriedAt
    }

    /// Back-compat decode: sidecars written before self-healing have no
    /// `retryCount` / `lastRetriedAt`, so default them rather than failing.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reason = try container.decode(String.self, forKey: .reason)
        sqliteCode = try container.decodeIfPresent(Int.self, forKey: .sqliteCode)
        quarantinedAt = try container.decode(String.self, forKey: .quarantinedAt)
        eventType = try container.decode(String.self, forKey: .eventType)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        retryCount = try container.decodeIfPresent(Int.self, forKey: .retryCount) ?? 0
        lastRetriedAt = try container.decodeIfPresent(String.self, forKey: .lastRetriedAt)
    }

    /// True once the retry budget is spent — what lights the menubar badge.
    public func isExhausted(maxRetries: Int) -> Bool { retryCount >= maxRetries }

    /// The sidecar path for a quarantined event file: `<eventfile>.meta.json`.
    /// Single source of truth for the naming convention, shared by the writer
    /// (the ingestor) and the reader/retrier (QuarantineService).
    public static func sidecarURL(for eventURL: URL) -> URL {
        eventURL.appendingPathExtension("meta.json")
    }

    /// Encodes and writes this metadata to `eventURL`'s sidecar. Best-effort.
    public func writeSidecar(for eventURL: URL) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.sidecarURL(for: eventURL))
    }
}
#endif
