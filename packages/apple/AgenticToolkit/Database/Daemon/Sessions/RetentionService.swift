#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

/// Deletes old events and empty ended sessions from the daemon database.
///
/// **Opt-in.** Retention permanently deletes event history, so it stays off until
/// `retention_enabled` is explicitly truthy by Core's `RawSetting.bool` rule
/// (1/true/yes/on, any case) in the settings table — see ``isEnabled(_:)``. A seeded
/// `retention_days` is the deletion *window*, not consent to delete.
///
/// **Chunked.** One ``runOnce()`` deletes at most ``batchSize`` events, then reports
/// ``Outcome/rerun`` while more remain, so a multi-month backlog drains across many
/// short passes instead of holding the write lane for minutes. The caller owns the
/// schedule and re-runs on `.rerun`.
///
/// **Ceiling.** `finalizedThrough` returns the latest `yyyy-MM-dd` UTC day whose
/// events may be deleted. A daemon that freezes events into rollups before deleting
/// them passes its rollup watermark; one with no rollup passes `{ nil }`, and `nil`
/// means "no ceiling" — age alone decides.
public struct RetentionService: Sendable {
    /// Events deleted per pass.
    public static let batchSize = 50
    /// The window used when `retention_days` holds no integer.
    public static let defaultRetentionDays = 7

    /// What a pass left behind.
    public enum Outcome: Sendable, Equatable {
        /// The backlog is drained for this cycle.
        case complete
        /// A full batch was deleted; more remain, so run again at once.
        case rerun
    }

    public let database: DaemonDatabase
    public let retentionDays: Int
    public let finalizedThrough: @Sendable () throws -> String?

    public init(
        database: DaemonDatabase,
        retentionDays: Int,
        finalizedThrough: @escaping @Sendable () throws -> String?
    ) {
        self.database = database
        self.retentionDays = retentionDays
        self.finalizedThrough = finalizedThrough
    }

    /// Retention is opt-in: enabled only when `retention_enabled` is explicitly
    /// truthy. Absent, empty or anything else means disabled — the safe default for an
    /// operation that permanently deletes user data.
    public static func isEnabled(_ database: DaemonDatabase) -> Bool {
        RawSetting.bool((try? database.setting(for: "retention_enabled")) ?? nil, default: false)
    }

    /// The deletion window: `retention_days` when it holds an integer, else `fallback`.
    public static func effectiveRetentionDays(
        _ database: DaemonDatabase, fallback: Int = defaultRetentionDays
    ) -> Int {
        if let raw = try? database.setting(for: "retention_days"), let days = Int(raw) {
            return days
        }
        return fallback
    }

    /// One pass: a batch of old events, then — once events are drained — a batch of
    /// empty ended sessions.
    public func runOnce() throws -> Outcome {
        do {
            let deleted = try database.deleteOldEvents(
                olderThanDays: retentionDays,
                batchSize: Self.batchSize,
                notAfterDay: try finalizedThrough()
            )
            if deleted >= Self.batchSize {
                // More to delete — yield the queue and re-fire so other DB-queue
                // waiters can interleave.
                logger.debug("Retention batch deleted \(deleted) event(s); rescheduling")
                return .rerun
            }
            // Event backlog drained for this cycle. Reap empty ended sessions, which
            // is itself batched (LIMIT); if it hit the cap there are more, so
            // reschedule to drain the rest instead of leaving them for tomorrow.
            let deletedSessions = try database.deleteEndedSessionsWithNoEvents()
            if deletedSessions >= DaemonDatabase.emptySessionReapBatch {
                logger.debug("Retention reaped \(deletedSessions) empty session(s); rescheduling")
                return .rerun
            }
            logger.info(
                "Retention cleanup complete — final batch \(deleted) event(s), \(deletedSessions) empty session(s)"
            )
            return .complete
        } catch {
            logger.error("Retention cleanup failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}

extension RetentionService: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension DaemonDatabase {

    // MARK: - Retention

    /// Deletes up to `batchSize` event_log rows older than `days`. Single batch only —
    /// the caller loops (see ``RetentionService``). That shares the write lane fairly
    /// with ingest + read handlers instead of holding it across an entire multi-month
    /// backlog. When `notAfterDay` (a `yyyy-MM-dd` UTC day) is supplied, deletion is
    /// additionally capped to events on that day or earlier — a rollup watermark, so a
    /// day's source is never deleted before it is frozen into a daily metric. nil = no
    /// cap.
    @discardableResult
    public func deleteOldEvents(
        olderThanDays days: Int,
        batchSize: Int = 50,
        notAfterDay: String? = nil
    ) throws -> Int {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoff = fmt.string(from: Date.now.addingTimeInterval(-Double(days) * 86400))
        // "<day>T99" sorts above every real timestamp on that UTC day but below
        // the next day (same trick as the daily-metric recompute); index-friendly.
        let watermarkClause = notAfterDay != nil ? "AND timestamp <= ?" : ""
        var params: [any Sendable] = [cutoff]
        if let notAfterDay { params.append(notAfterDay + "T99") }
        params.append(batchSize)
        return try write { database in
            try execute("""
                DELETE FROM event_log
                WHERE rowid IN (
                    SELECT rowid FROM event_log
                    WHERE timestamp <= ? \(watermarkClause)
                    LIMIT ?
                )
            """, params: params)
            return Int(database.changesCount)
        }
    }

    /// Per-cycle cap on empty-ended-session reaping, shared with ``RetentionService``
    /// so it knows a full batch means "more remain, reschedule".
    public static let emptySessionReapBatch = 500

    @discardableResult
    public func deleteEndedSessionsWithNoEvents(
        batchSize: Int = DaemonDatabase.emptySessionReapBatch
    ) throws -> Int {
        try write { database in
            // `NOT EXISTS` probes idx_event_log_session_id per candidate session,
            // instead of `NOT IN`'s full scan of event_log (581k+ rows); `LIMIT`
            // bounds the delete so it stays well under the write eject ceiling and
            // drains a large backlog across cycles.
            try execute("""
                DELETE FROM sessions WHERE session_id IN (
                    SELECT session_id FROM sessions
                    WHERE status = 'ended'
                      AND NOT EXISTS (
                          SELECT 1 FROM event_log WHERE event_log.session_id = sessions.session_id
                      )
                    LIMIT ?
                )
            """, params: [batchSize])
            return Int(database.changesCount)
        }
    }
}

#endif
