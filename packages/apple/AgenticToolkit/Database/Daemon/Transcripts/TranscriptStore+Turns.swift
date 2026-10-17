#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - Transcript turns (JSONL import + CSL migration)

    /// Insert one row into `transcript_turns`. Dedup is enforced by the
    /// partial unique indexes:
    ///   - any turn with non-empty `message_id` (migration007) — LAST
    ///     record wins: Claude Code streams several partial JSONL records
    ///     per assistant API response, all sharing one `message.id`, and
    ///     only the final one carries the finished usage tallies. A
    ///     conflict upgrades the stored row to the newcomer's token counts
    ///     and timestamp (plus `tool_name` / subagent markers when the
    ///     newcomer supplies them) instead of discarding it. The update is
    ///     skipped when the newcomer carries zero usage, so a usage-less
    ///     partial can't wipe final tallies — and a same-values re-import
    ///     writes back identical numbers, keeping imports idempotent
    ///     (session_metrics recomputes from this table).
    ///   - user turns at the same `(session_id, timestamp)` (migration008)
    ///   - empty-mid assistant turns at the same `(session_id, timestamp,
    ///     tool_name)` (migration009) — so multi-tool-use sibling rows
    ///     stay distinct (different `tool_name`) while re-imports of the
    ///     same source row collapse. First record wins (OR IGNORE) — with
    ///     no message id there's no stream to reconcile.
    ///
    /// Returns `true` if a row was inserted or updated, `false` if dedup
    /// swallowed the write. `eventLogId` is the optional FK back to the
    /// synthesized event_log row (so consumers can join turn → event for
    /// context); it is never changed on conflict — the first record's
    /// event link stands.
    @discardableResult
    public func insertTranscriptTurn(
        sessionId: String,
        timestamp: String,
        kind: String,
        model: String,
        messageId: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int,
        cacheCreationTokens: Int,
        cacheCreation1hTokens: Int = 0,
        toolName: String,
        cwd: String,
        eventLogId: Int64? = nil,
        accountEmail: String,
        isSubagent: Bool = false,
        agentId: String = ""
    ) throws -> Bool {
        // One parameter list for both statements. A nil `eventLogId` binds as
        // SQL NULL (see `args`), which is what leaving the column out of the
        // INSERT produced anyway.
        let params: [any Sendable] = [
            sessionId, timestamp, kind, model, messageId,
            inputTokens, outputTokens, cacheReadTokens,
            cacheCreationTokens, cacheCreation1hTokens, toolName, cwd, eventLogId,
            accountEmail, isSubagent, agentId
        ]
        return try write { database in
            if messageId.isEmpty {
                try execute("""
                    INSERT OR IGNORE INTO transcript_turns (
                        session_id, timestamp, kind, model, message_id,
                        input_tokens, output_tokens, cache_read_tokens,
                        cache_creation_tokens, cache_creation_1h_tokens,
                        tool_name, cwd, event_log_id,
                        account_email, is_subagent, agent_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, params: params)
            } else {
                // The conflict target repeats the partial index's predicate
                // (`WHERE message_id != ''`) so SQLite matches
                // idx_transcript_turns_message_id — same partial-index rule
                // as `insertImportedEvent`'s dedup probe.
                try execute("""
                    INSERT INTO transcript_turns (
                        session_id, timestamp, kind, model, message_id,
                        input_tokens, output_tokens, cache_read_tokens,
                        cache_creation_tokens, cache_creation_1h_tokens,
                        tool_name, cwd, event_log_id,
                        account_email, is_subagent, agent_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(message_id) WHERE message_id != '' DO UPDATE SET
                        timestamp = excluded.timestamp,
                        input_tokens = excluded.input_tokens,
                        output_tokens = excluded.output_tokens,
                        cache_read_tokens = excluded.cache_read_tokens,
                        cache_creation_tokens = excluded.cache_creation_tokens,
                        cache_creation_1h_tokens = excluded.cache_creation_1h_tokens,
                        tool_name = CASE WHEN excluded.tool_name != ''
                                         THEN excluded.tool_name ELSE tool_name END,
                        is_subagent = MAX(is_subagent, excluded.is_subagent),
                        agent_id = CASE WHEN excluded.agent_id != ''
                                        THEN excluded.agent_id ELSE agent_id END
                    WHERE excluded.input_tokens + excluded.output_tokens
                        + excluded.cache_read_tokens + excluded.cache_creation_tokens > 0
                """, params: params)
            }
            return database.changesCount > 0
        }
    }

    /// One `transcript_turns` row, read back by `message_id`. Exercised by
    /// tests asserting dedup / subagent-attribution outcomes.
    public struct TranscriptTurnRow {
        public let sessionId: String
        public let timestamp: String
        public let kind: String
        public let model: String
        public let inputTokens: Int
        public let outputTokens: Int
        public let cacheReadTokens: Int
        public let cacheCreationTokens: Int
        public let toolName: String
        public let isSubagent: Bool
        public let agentId: String
    }

    /// Fetch one turn by its `message_id`, or `nil` if unknown.
    public func transcriptTurn(messageId: String) throws -> TranscriptTurnRow? {
        var row: TranscriptTurnRow?
        try query("""
            SELECT session_id, timestamp, kind, model,
                   input_tokens, output_tokens, cache_read_tokens,
                   cache_creation_tokens, tool_name, is_subagent, agent_id
            FROM transcript_turns
            WHERE message_id = ?
        """, params: [messageId]) { dbRow in
            row = TranscriptTurnRow(
                sessionId: self.string(dbRow, 0),
                timestamp: self.string(dbRow, 1),
                kind: self.string(dbRow, 2),
                model: self.string(dbRow, 3),
                inputTokens: self.int(dbRow, 4),
                outputTokens: self.int(dbRow, 5),
                cacheReadTokens: self.int(dbRow, 6),
                cacheCreationTokens: self.int(dbRow, 7),
                toolName: self.string(dbRow, 8),
                isSubagent: self.int(dbRow, 9) != 0,
                agentId: self.string(dbRow, 10)
            )
        }
        return row
    }

    // MARK: - Agent dispatches (JSONL import)

    /// One `agent_dispatches` row — subagent dispatch metadata from the
    /// parent session's `toolUseResult` record (migration034).
    public struct AgentDispatchRow {
        public let agentId: String
        public let sessionId: String
        public let agentType: String
        public let startedAt: String
        public let status: String
        public let totalTokens: Int
        public let totalDurationMs: Int
        public let totalToolUseCount: Int
    }

    /// Insert or update one subagent dispatch, keyed by `agent_id`. Last
    /// write wins (mirroring claude-usage's `upsert_agents`), so re-imports
    /// refresh rather than duplicate.
    public func upsertAgentDispatch(
        agentId: String,
        sessionId: String,
        agentType: String,
        startedAt: String,
        status: String,
        totalTokens: Int,
        totalDurationMs: Int,
        totalToolUseCount: Int
    ) throws {
        try write { _ in
            try execute("""
                INSERT INTO agent_dispatches (
                    agent_id, session_id, agent_type, started_at, status,
                    total_tokens, total_duration_ms, total_tool_use_count,
                    updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
                ON CONFLICT(agent_id) DO UPDATE SET
                    session_id = excluded.session_id,
                    agent_type = excluded.agent_type,
                    started_at = excluded.started_at,
                    status = excluded.status,
                    total_tokens = excluded.total_tokens,
                    total_duration_ms = excluded.total_duration_ms,
                    total_tool_use_count = excluded.total_tool_use_count,
                    updated_at = datetime('now')
            """, params: [
                agentId, sessionId, agentType, startedAt, status,
                totalTokens, totalDurationMs, totalToolUseCount
            ])
        }
    }

    /// Fetch one dispatch by its `agent_id`, or `nil` if unknown.
    public func agentDispatch(agentId: String) throws -> AgentDispatchRow? {
        var row: AgentDispatchRow?
        try query("""
            SELECT agent_id, session_id, agent_type, started_at, status,
                   total_tokens, total_duration_ms, total_tool_use_count
            FROM agent_dispatches
            WHERE agent_id = ?
        """, params: [agentId]) { dbRow in
            row = AgentDispatchRow(
                agentId: self.string(dbRow, 0),
                sessionId: self.string(dbRow, 1),
                agentType: self.string(dbRow, 2),
                startedAt: self.string(dbRow, 3),
                status: self.string(dbRow, 4),
                totalTokens: self.int(dbRow, 5),
                totalDurationMs: self.int(dbRow, 6),
                totalToolUseCount: self.int(dbRow, 7)
            )
        }
        return row
    }

    /// Count all dispatch rows (upsert-idempotency assertions in tests).
    public func agentDispatchCount() throws -> Int {
        var count = 0
        try query("SELECT COUNT(*) FROM agent_dispatches") { row in
            count = self.int(row, 0)
        }
        return count
    }

    /// Count rows in `transcript_turns`, optionally filtered by session.
    /// Phase 4 will introduce richer per-turn read endpoints; this lightweight
    /// counter is enough for ingest tests and a future `/health` summary.
    public func transcriptTurnCount(sessionId: String? = nil) throws -> Int {
        var count = 0
        if let sessionId {
            try query(
                "SELECT COUNT(*) FROM transcript_turns WHERE session_id = ?",
                params: [sessionId]
            ) { row in
                count = Int(int64(row, 0))
            }
        } else {
            try query("SELECT COUNT(*) FROM transcript_turns") { row in
                count = Int(int64(row, 0))
            }
        }
        return count
    }
}
#endif
