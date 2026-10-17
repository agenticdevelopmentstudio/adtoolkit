#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - Session transcript titles (JSONL import)

    /// Set a session's transcript title (from a JSONL `custom-title` /
    /// `ai-title` record). Precedence: a custom title overwrites anything;
    /// an ai title never displaces an existing custom title (it may replace
    /// an earlier ai title). Stored apart from `summary` — the daemon's
    /// summarizer owns that column and imports must not clobber it.
    /// UPDATE-only: a title for an unknown session is a no-op, so a
    /// title-only session (a title record with no turns anywhere) can't
    /// materialize a phantom row.
    ///
    /// Also *clears* a `summary` that is literally this title. An enrichment pass
    /// used to write the transcript title into `summary`, which is why a
    /// sessions list showed a branch-like word where a summary belonged - and
    /// why the summarizer then skipped those rows forever, `summary != ''` being
    /// its "already summarized" test. Clearing on an exact match is precise: it
    /// can only remove the residue it is named after, never a real summary.
    public func updateSessionTranscriptTitle(sessionId: String, title: String, source: String) throws {
        try write { _ in
            try execute("""
                UPDATE sessions
                SET transcript_title = ?, title_source = ?
                WHERE session_id = ?
                  AND (? = 'custom' OR title_source != 'custom')
            """, params: [title, source, sessionId, source])
            try execute("""
                UPDATE sessions SET summary = '', summary_at = ''
                WHERE session_id = ? AND summary = ?
            """, params: [sessionId, title])
        }
    }

    /// The agent's most recent prose reply, for a sessions list's second row
    /// line. Written off the Stop hook - the moment the agent
    /// finished speaking - because no hook payload carries the text itself.
    public func updateSessionLastOutput(_ text: String, sessionId: String) {
        do {
            try execute(
                "UPDATE sessions SET last_output = ? WHERE session_id = ?",
                params: [text, sessionId]
            )
        } catch {
            logger.error("updateSessionLastOutput failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Sessions a sessions list can still show that have no `last_output` yet:
    /// not ended, or ended within `recentHours`, newest first.
    ///
    /// `last_output` is only ever written off a `Stop` hook, so a session that was
    /// already running when the daemon learned to record it — or whose last `Stop`
    /// landed while the daemon was down — reads "No output yet." until the agent
    /// next finishes speaking, which for an idle session is never. This is the list
    /// the startup pass fills in from the transcripts instead.
    public func sessionIdsMissingLastOutput(recentHours: Int = SessionSchema.lastOutputReachHours) throws -> [String] {
        // Read-only → read lane (see sessionsNeedingEnrichment).
        try read { _ in
            var out: [String] = []
            try query("""
                SELECT session_id FROM sessions
                WHERE last_output = ''
                  AND (status != ? OR last_activity_at >= datetime('now', ?))
                ORDER BY last_activity_at DESC
            """, params: [SessionStatus.ended.rawValue, "-\(recentHours) hours"]) { row in
                out.append(string(row, 0))
            }
            return out
        }
    }

    /// A live session whose last recorded turn state could have been cut short by an
    /// interrupt, with what ``markTurnInterrupted(sessionId:ifEventType:setAt:interruptedAt:)``
    /// needs to change it only if nothing has happened since.
    public struct TurnStateCandidate: Sendable, Equatable {
        public let sessionId: String
        public let lastEventType: String
        /// When `lastEventType` was recorded (`turn_state_at`, SQLite `datetime` form).
        public let turnStateAt: String
        /// The transcript the hooks reported, or "" when none has been recorded.
        public let transcriptPath: String

        public init(sessionId: String, lastEventType: String, turnStateAt: String, transcriptPath: String) {
            self.sessionId = sessionId
            self.lastEventType = lastEventType
            self.turnStateAt = turnStateAt
            self.transcriptPath = transcriptPath
        }
    }

    /// Active sessions whose turn is still in flight as far as the hooks know: their
    /// `last_event_type` neither ends a turn (`HookEventType.turnEndingEventTypes`) nor
    /// already records an interrupt, and isn't empty (no state recorded yet).
    public func turnStateCandidates() throws -> [TurnStateCandidate] {
        let settled = Array(HookEventType.turnEndingEventTypes) + [HookEventType.interruptedEventType, ""]
        let placeholders = settled.map { _ in "?" }.joined(separator: ", ")
        return try read { _ in
            var out: [TurnStateCandidate] = []
            try query("""
                SELECT s.session_id, s.last_event_type, s.turn_state_at,
                       COALESCE(m.transcript_path, '')
                FROM sessions s LEFT JOIN session_metrics m ON m.session_id = s.session_id
                WHERE s.status = ? AND s.last_event_type NOT IN (\(placeholders))
            """, params: [SessionStatus.active.rawValue] + settled) { row in
                out.append(TurnStateCandidate(
                    sessionId: string(row, 0),
                    lastEventType: string(row, 1),
                    turnStateAt: string(row, 2),
                    transcriptPath: string(row, 3)
                ))
            }
            return out
        }
    }

    /// Records that the user interrupted the session's turn at `interruptedAt` (the
    /// transcript marker's ISO-8601 time) — but only if its state is still exactly what
    /// was read (`eventType`, set at `setAt`), and the interrupt is no older than that
    /// state. A hook that lands between the transcript read and this write is newer
    /// news than the interrupt, so it wins; and so does a new prompt whose hook landed
    /// before the transcript recorded it. Same-second ties count as interrupted:
    /// `turn_state_at` has whole-second resolution, and nobody interrupts and types a
    /// new prompt inside one second. Returns whether the row changed.
    ///
    /// A blank `turn_state_at` is not "the beginning of time": compared against one,
    /// *any* datetime wins (SQLite sorts every datetime string above `''`), so the
    /// ordering guard would be vacuously true and a years-old marker could flip the
    /// row. migration041 writes exactly that blank whenever the event it re-derived
    /// state from carried no parseable timestamp. For those rows the state's time is
    /// unknown, and the closest thing the row does know is `last_activity_at` — the
    /// same event's clock, written beside `turn_state_at` by the upsert and never
    /// blank — so the guard falls back to it.
    @discardableResult
    public func markTurnInterrupted(
        sessionId: String,
        ifEventType eventType: String,
        setAt: String,
        interruptedAt: String
    ) throws -> Bool {
        try write { database in
            try database.execute(sql: """
                UPDATE sessions SET last_event_type = ?, turn_state_at = datetime(?),
                    -- An interrupt ends the turn's foreground subagents without a
                    -- `SubagentStop`, so it clears the subagent clock the same way
                    -- one would. A background subagent that survived it re-stamps
                    -- on its next hook, which is newer than this.
                    subagent_activity_at = CASE
                        WHEN subagent_activity_at <= datetime(?) THEN '' ELSE subagent_activity_at END,
                    subagent_stopped_at = MAX(subagent_stopped_at, datetime(?))
                WHERE session_id = ? AND last_event_type = ? AND turn_state_at = ?
                  AND datetime(?) >= COALESCE(NULLIF(turn_state_at, ''), last_activity_at)
            """, arguments: try Self.args([
                HookEventType.interruptedEventType, interruptedAt, interruptedAt, interruptedAt,
                sessionId, eventType, setAt, interruptedAt
            ]))
            return database.changesCount > 0
        }
    }

    /// A session's transcript title and its provenance (`custom` / `ai`),
    /// both empty when no title record has been imported.
    public func sessionTranscriptTitle(sessionId: String) throws -> (title: String, source: String) {
        var result = (title: "", source: "")
        try query(
            "SELECT transcript_title, title_source FROM sessions WHERE session_id = ?",
            params: [sessionId]
        ) { row in
            result = (title: self.string(row, 0), source: self.string(row, 1))
        }
        return result
    }
}
#endif
