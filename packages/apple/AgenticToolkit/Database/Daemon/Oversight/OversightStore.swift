#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - Oversight findings

    /// Live-session snapshot for oversight: `sessions` (active/stale) LEFT JOINed to
    /// `session_metrics` for context usage. LEFT JOIN so a session that hasn't reported a
    /// status-line payload still appears (context 0 = "unknown", handled by observers).
    /// Ordered by context pressure so the worst offenders lead.
    public func fetchLiveSessionsWithContext() throws -> [LiveSessionSnapshot] {
        try read { _ in
            var out: [LiveSessionSnapshot] = []
            try query("""
                SELECT s.session_id, s.cwd, s.status, s.model, s.git_branch,
                       s.last_activity_at, s.term_session_id,
                       COALESCE(m.context_used_pct, 0),
                       COALESCE(m.context_window_size, 0)
                FROM sessions s
                LEFT JOIN session_metrics m ON s.session_id = m.session_id
                WHERE s.status IN ('active', 'stale')
                ORDER BY COALESCE(m.context_used_pct, 0) DESC
            """) { row in
                out.append(LiveSessionSnapshot(
                    sessionId: string(row, 0),
                    cwd: string(row, 1),
                    status: string(row, 2),
                    model: string(row, 3),
                    gitBranch: string(row, 4),
                    lastActivityAt: string(row, 5),
                    contextUsedPct: Int(int(row, 7)),
                    contextWindowSize: Int(int(row, 8)),
                    termSessionId: string(row, 6)
                ))
            }
            return out
        }
    }

    /// Upsert a finding keyed by (session, observer, kind). Refreshes severity/reason/
    /// source/model/detail and bumps `updated_at`; a `stale` row is revived to `pending`
    /// (its condition recurred), while `acted`/`dismissed` are preserved — respecting a
    /// human's decision until the condition resolves and later recurs.
    public func upsertOversightFinding(_ finding: SessionFinding) throws {
        try write { _ in
            try execute("""
                INSERT INTO oversight_findings
                    (session_id, observer, kind, severity, status, source, model, reason, detail, updated_at)
                VALUES (?, ?, ?, ?, 'pending', ?, ?, ?, ?, datetime('now'))
                ON CONFLICT(session_id, observer, kind) DO UPDATE SET
                    severity = excluded.severity,
                    source = excluded.source,
                    model = excluded.model,
                    reason = excluded.reason,
                    detail = excluded.detail,
                    updated_at = datetime('now'),
                    status = CASE WHEN oversight_findings.status = 'stale'
                                  THEN 'pending' ELSE oversight_findings.status END
            """, params: [
                finding.sessionId, finding.observer, finding.kind, finding.severity,
                finding.source.rawValue, finding.model, finding.reason, finding.detail
            ])
        }
    }

    /// Mark as `stale` every still-`pending` finding for `observer` whose session is NOT
    /// in `keep` — conditions the observer no longer reports this tick. `acted`/`dismissed`
    /// rows are left untouched. Run once per observer per tick to reconcile.
    public func markOversightFindingsResolved(observer: String, exceptSessions keep: Set<String>) throws {
        try write { _ in
            if keep.isEmpty {
                try execute("""
                    UPDATE oversight_findings SET status = 'stale', updated_at = datetime('now')
                    WHERE observer = ? AND status = 'pending'
                """, params: [observer])
            } else {
                let placeholders = keep.map { _ in "?" }.joined(separator: ",")
                var params: [any Sendable] = [observer]
                params.append(contentsOf: keep.sorted())
                try execute("""
                    UPDATE oversight_findings SET status = 'stale', updated_at = datetime('now')
                    WHERE observer = ? AND status = 'pending'
                      AND session_id NOT IN (\(placeholders))
                """, params: params)
            }
        }
    }

    /// Read findings for the API. `status` filters to one lifecycle state (nil = all).
    /// Ordered by severity then recency so the most urgent lead.
    public func fetchOversightFindings(status: String? = nil, limit: Int = 200) throws -> [OversightFindingDTO] {
        try read { _ in
            var sql = """
                SELECT id, session_id, observer, kind, severity, status, source, model,
                       reason, detail, created_at, updated_at
                FROM oversight_findings
            """
            var params: [any Sendable] = []
            if let status {
                sql += " WHERE status = ?"
                params.append(status)
            }
            sql += " ORDER BY severity DESC, datetime(updated_at) DESC LIMIT ?"
            params.append(limit)

            var out: [OversightFindingDTO] = []
            try query(sql, params: params) { row in
                out.append(makeOversightFinding(row))
            }
            return out
        }
    }

    /// Read one finding by id (nil if absent) — the action endpoints resolve the target
    /// and record the act against a specific finding.
    public func fetchOversightFinding(id: Int) throws -> OversightFindingDTO? {
        try read { _ in
            var out: OversightFindingDTO?
            try query("""
                SELECT id, session_id, observer, kind, severity, status, source, model,
                       reason, detail, created_at, updated_at
                FROM oversight_findings WHERE id = ?
            """, params: [id]) { row in
                out = makeOversightFinding(row)
            }
            return out
        }
    }

    /// Column order matches the two SELECTs above — the single place that maps an
    /// `oversight_findings` row to its DTO, so the list and by-id reads can't drift.
    private func makeOversightFinding(_ row: Row) -> OversightFindingDTO {
        OversightFindingDTO(
            id: Int(int(row, 0)),
            sessionId: string(row, 1),
            observer: string(row, 2),
            kind: string(row, 3),
            severity: Int(int(row, 4)),
            status: string(row, 5),
            source: string(row, 6),
            model: string(row, 7),
            reason: string(row, 8),
            detail: string(row, 9),
            createdAt: string(row, 10),
            updatedAt: string(row, 11)
        )
    }

    /// Mark as `stale` every still-`pending` finding whose observer is NOT in `keep` —
    /// orphan reconciliation for observers (scripts) that were deleted or disabled, so
    /// their findings don't linger as pending forever. Run once per oversight tick.
    public func markOversightFindingsStale(observersNotIn keep: Set<String>) throws {
        try write { _ in
            if keep.isEmpty {
                try execute("""
                    UPDATE oversight_findings SET status = 'stale', updated_at = datetime('now')
                    WHERE status = 'pending'
                """, params: [])
            } else {
                let placeholders = keep.map { _ in "?" }.joined(separator: ",")
                try execute("""
                    UPDATE oversight_findings SET status = 'stale', updated_at = datetime('now')
                    WHERE status = 'pending' AND observer NOT IN (\(placeholders))
                """, params: keep.sorted())
            }
        }
    }

    // MARK: - Oversight scripts

    /// One stored script row: the decoded definition plus the storage-level
    /// `userModified` flag (which lives beside the JSON, not inside it — it's the
    /// upgrader's bookkeeping, not part of the script's shape).
    public struct OversightScriptRow: Sendable {
        public let script: OversightScript
        public let userModified: Bool
    }

    /// Every stored script row, ordered built-ins first then by name. Rows whose
    /// definition no longer decodes are skipped (and logged) rather than failing the
    /// whole read — one corrupt row must not take oversight down.
    public func fetchOversightScriptRows() throws -> [OversightScriptRow] {
        try read { _ in
            var out: [OversightScriptRow] = []
            try query("""
                SELECT definition, user_modified, id FROM oversight_scripts
                ORDER BY built_in DESC, name COLLATE NOCASE
            """, params: []) { row in
                let json = string(row, 0)
                guard let script = try? JSONDecoder().decode(OversightScript.self, from: Data(json.utf8)) else {
                    let id = string(row, 2)
                    logger.warning("Skipping undecodable oversight script '\(id, privacy: .public)'")
                    return
                }
                out.append(OversightScriptRow(script: script, userModified: int(row, 1) != 0))
            }
            return out
        }
    }

    /// One stored script (nil if absent).
    public func fetchOversightScriptRow(id: String) throws -> OversightScriptRow? {
        try read { _ in
            var out: OversightScriptRow?
            try query(
                "SELECT definition, user_modified FROM oversight_scripts WHERE id = ?",
                params: [id]
            ) { row in
                let json = string(row, 0)
                guard let script = try? JSONDecoder().decode(OversightScript.self, from: Data(json.utf8)) else {
                    return
                }
                out = OversightScriptRow(script: script, userModified: int(row, 1) != 0)
            }
            return out
        }
    }

    /// Insert-or-update one script. The mirrored columns are derived from the
    /// definition; `userModified` is the caller's statement about *why* this write
    /// happened (a user edit vs. the shipped-script seeder/upgrader).
    public func upsertOversightScript(_ script: OversightScript, userModified: Bool) throws {
        let definition = String(data: try JSONEncoder().encode(script), encoding: .utf8) ?? "{}"
        try write { _ in
            try execute("""
                INSERT INTO oversight_scripts
                    (id, name, enabled, built_in, user_modified, version, definition, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    enabled = excluded.enabled,
                    built_in = excluded.built_in,
                    user_modified = excluded.user_modified,
                    version = excluded.version,
                    definition = excluded.definition,
                    updated_at = datetime('now')
            """, params: [
                script.id, script.name, script.enabled ? 1 : 0, script.builtIn ? 1 : 0,
                userModified ? 1 : 0, script.version, definition
            ])
        }
    }

    public func deleteOversightScript(id: String) throws {
        try write { _ in
            try execute("DELETE FROM oversight_scripts WHERE id = ?", params: [id])
        }
    }

    /// Mark one finding `acted` — the record a human (Phase 3) or autonomous actor
    /// (Phase 4) leaves after successfully dispatching its action. Guarded on `pending`
    /// so a double-submit or a concurrent dismiss can't clobber a resolved decision.
    public func markOversightFindingActed(id: Int) throws {
        try write { _ in
            try execute("""
                UPDATE oversight_findings
                SET status = 'acted', updated_at = datetime('now')
                WHERE id = ? AND status = 'pending'
            """, params: [id])
        }
    }

    /// Count of findings in a given status — the badge polls `pending`.
    public func oversightFindingCount(status: String = "pending") throws -> Int {
        var count = 0
        try query("SELECT COUNT(*) FROM oversight_findings WHERE status = ?", params: [status]) { row in
            count = Int(int(row, 0))
        }
        return count
    }

    /// The type of the session's most recent event, or "" if it has none. `Stop` means
    /// Claude finished a response and is waiting for the user (a safe breakpoint to inject
    /// `/compact`); anything else means it is mid-response. Single-session + indexed on
    /// `session_id`, so it sorts only that one session's events — bounded and cheap. The
    /// `id DESC` tiebreak orders events that share a one-second timestamp by insertion.
    public func lastEventType(sessionId: String) throws -> String {
        try read { _ in
            var out = ""
            try query("""
                SELECT event_type FROM event_log
                WHERE session_id = ?
                ORDER BY timestamp DESC, id DESC
                LIMIT 1
            """, params: [sessionId]) { row in
                out = string(row, 0)
            }
            return out
        }
    }
}
#endif
