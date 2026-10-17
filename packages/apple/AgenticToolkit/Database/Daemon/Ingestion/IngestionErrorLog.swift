#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

// MARK: - Ingestion error log

extension DaemonDatabase {

    /// Records (or refreshes) a quarantined ingestion failure. Keyed by
    /// `filename`; the original `quarantined_at` is preserved across updates,
    /// while reason / retry_count / status track the latest attempt. `status`
    /// is `exhausted` once the retry budget is spent, else `failing`. Idempotent
    /// upsert — safe to call on every quarantine and every failed retry.
    public func recordIngestionError(
        filename: String,
        eventType: String,
        sessionId: String,
        reason: String,
        sqliteCode: Int?,
        quarantinedAt: String,
        retryCount: Int,
        lastRetriedAt: String?,
        exhausted: Bool
    ) throws {
        let status = exhausted ? "exhausted" : "failing"
        try migrationExecute("""
            INSERT INTO ingestion_errors (
                filename, event_type, session_id, reason, sqlite_code,
                quarantined_at, retry_count, last_retried_at, status,
                resolved_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, datetime('now'))
            ON CONFLICT(filename) DO UPDATE SET
                event_type = excluded.event_type,
                session_id = excluded.session_id,
                reason = excluded.reason,
                sqlite_code = excluded.sqlite_code,
                retry_count = excluded.retry_count,
                last_retried_at = excluded.last_retried_at,
                status = excluded.status,
                -- Preserve the original quarantine time across retries, but take a
                -- fresh time when the prior row was already resolved (a genuinely
                -- new failure that happens to reuse the filename).
                quarantined_at = CASE
                    WHEN ingestion_errors.status IN ('recovered', 'cleared')
                    THEN excluded.quarantined_at
                    ELSE ingestion_errors.quarantined_at
                END,
                resolved_at = NULL,
                updated_at = datetime('now')
        """, params: [
            filename, eventType, sessionId, reason, sqliteCode as Int?,
            quarantinedAt, retryCount, lastRetriedAt as String?, status
        ])
    }

    /// Records a drop file that arrived empty, as a terminal `lost` row: the
    /// event it carried is gone, so unlike `failing` / `exhausted` this is never
    /// retried and never counted as a live failure. Resolved on arrival — the
    /// row is history, not an open problem. Idempotent by `filename`.
    public func recordLostIngestionEvent(filename: String, detectedAt: String) throws {
        try migrationExecute("""
            INSERT INTO ingestion_errors (
                filename, event_type, session_id, reason, sqlite_code,
                quarantined_at, retry_count, last_retried_at, status,
                resolved_at, updated_at
            ) VALUES (?, '', '', ?, NULL, ?, 0, NULL, 'lost', datetime('now'), datetime('now'))
            ON CONFLICT(filename) DO UPDATE SET
                reason = excluded.reason,
                status = 'lost',
                resolved_at = datetime('now'),
                updated_at = datetime('now')
        """, params: [filename, QuarantineService.lostEventReason, detectedAt])
    }

    /// Marks a previously-failing ingestion error as recovered (its event was
    /// finally ingested). No-op if the filename isn't logged.
    public func resolveIngestionError(filename: String) throws {
        try migrationExecute("""
            UPDATE ingestion_errors
            SET status = 'recovered', resolved_at = datetime('now'), updated_at = datetime('now')
            WHERE filename = ?
        """, params: [filename])
    }

    /// Marks every still-active (failing/exhausted) ingestion error as cleared —
    /// called when the user clears the quarantine directory, so the log keeps the
    /// history (for tracking) without reporting them as live failures.
    public func clearActiveIngestionErrors() throws {
        try migrationExecute("""
            UPDATE ingestion_errors
            SET status = 'cleared', resolved_at = datetime('now'), updated_at = datetime('now')
            WHERE status IN ('failing', 'exhausted')
        """)
    }

    /// Most-recently-touched ingestion-error log rows (any status), newest first.
    public func recentIngestionErrors(limit: Int = 200) throws -> [IngestionErrorLogDTO] {
        var rows: [IngestionErrorLogDTO] = []
        try query("""
            SELECT filename, event_type, session_id, reason, sqlite_code,
                   quarantined_at, retry_count, last_retried_at, status,
                   resolved_at, updated_at
            FROM ingestion_errors
            ORDER BY updated_at DESC
            LIMIT ?
        """, params: [limit]) { row in
            rows.append(IngestionErrorLogDTO(
                filename: string(row, 0),
                eventType: string(row, 1),
                sessionId: string(row, 2),
                reason: string(row, 3),
                sqliteCode: optionalInt(row, 4),
                quarantinedAt: string(row, 5),
                retryCount: Int(int64(row, 6)),
                lastRetriedAt: optionalString(row, 7),
                status: string(row, 8),
                resolvedAt: optionalString(row, 9),
                updatedAt: string(row, 10)
            ))
        }
        return rows
    }
}
#endif
