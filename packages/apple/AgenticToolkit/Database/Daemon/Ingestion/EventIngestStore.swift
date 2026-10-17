#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

// MARK: - Event ingestion

extension DaemonDatabase {

    /// Resolves symlinks in a cwd (via `realpath`) so the stored session cwd is the
    /// physical path a live `claude` reports. Returns the input unchanged for empty
    /// or non-existent paths (realpath fails with ENOENT). Mirrors
    /// `ProcessLiveness.canonicalPath`; kept local to avoid a Tasks dependency.
    private static func canonicalCwd(_ path: String) -> String {
        guard !path.isEmpty, let resolved = realpath(path, nil) else { return path }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    /// Ingests an event: upserts the session, inserts into event_log, inserts into
    /// the per-type table, and optionally inserts tool_input / tool_response rows.
    /// Synchronous — blocks until all writes are committed. Returns an IngestedEvent
    /// with the new event_log row ID so the caller can broadcast it immediately.
    @discardableResult
    public func ingestEvent(
        eventType: String,
        timestamp: String,
        hookData: [String: Any],
        context: [String: Any]? = nil,
        accountEmail: String = "",
        oauthAccountEmail: String? = nil
    ) throws -> IngestedEvent {
        // Resolve the account + how it authenticated ONCE, outside the write lane
        // (currentEmail() may stat/parse ~/.claude.json — never hold the writer
        // through it). Token wins when present (per-session-immutable, authoritative);
        // else the oauth login the *capture* resolved; else unresolved.
        // `snapshotAccount` keeps its old meaning (token-else-oauth) for the
        // rate-limit snapshot stamp below.
        //
        // `oauthAccountEmail` is nil only for an envelope written before the field
        // existed; resolving now is then the best answer left, and it is the old
        // behaviour. For everything else the answer travelled with the event, so a
        // backlog is attributed to who was logged in when it was captured — see
        // `ParsedEvent.oauthAccountEmail`.
        let sessionAccount: String
        let authMethod: String
        if !accountEmail.isEmpty {
            sessionAccount = accountEmail
            authMethod = "token"
        } else {
            let oauth = oauthAccountEmail ?? accountResolver.currentEmail()
            sessionAccount = oauth
            authMethod = oauth.isEmpty ? "" : "oauth"
        }
        let snapshotAccount = sessionAccount
        return try write { database in
            let sessionId  = hookData["session_id"] as? String ?? ""
            let cwd        = hookData["cwd"]        as? String ?? ""
            let model      = hookData["model"]      as? String ?? ""
            let pid        = hookData["pid"]        as? Int    ?? 0
            let termProg   = hookData["term_program"] as? String ?? ""
            let termSession = hookData["term_session_id"] as? String ?? ""
            let toolName   = hookData["tool_name"]  as? String ?? ""
            let source     = hookData["source"]     as? String ?? ""
            // The session is stamped with (account, auth_method) via a source-tagged
            // precedence (see the upsert below): a `token` stamp heals an earlier
            // NON-token (`oauth`/`unknown`) guess, but a differing later token never
            // overwrites an existing one (first-token-wins — a session's token is
            // fixed for its lifetime); an `oauth` stamp fills an empty account and
            // heals a low-confidence `unknown` (backfill/import-time) stamp, but
            // never clobbers a `token` and never overwrites an existing `oauth`
            // (first-oauth-wins, stable, no thrash). This lets us persist the oauth
            // login safely — the old code refused to, because a frozen wrong oauth
            // guess was uncorrectable; source-tagging removes that hazard. Snapshots
            // still use `snapshotAccount` (token-else-oauth).
            // Store the canonical (symlink-resolved) cwd so liveness can match a
            // live `claude`'s real cwd against it. The hook reports the logical
            // `$PWD` (e.g. /tmp/x), but libproc reports the physical path
            // (/private/tmp/x); without this they'd never match for symlinked
            // project roots. realpath returns the input for non-existent paths.
            let sessionCwd = Self.canonicalCwd(cwd)
            // 1 = this event moves the session's clock, status and activity icon;
            // 0 = ambient noise that fired for reasons outside this session.
            let isActivity = HookEventType.isActivity(eventType) ? 1 : 0
            // 1 = this event is about the main agent's turn, so it decides the
            // activity icon; 0 = a subagent, a compaction, an idle reminder — see
            // `HookEventType.setsTurnState`. A row created by one records no state.
            let setsTurnState = HookEventType.setsTurnState(eventType, hookData: hookData)
            let turnState = setsTurnState ? 1 : 0
            let insertedEventType = setsTurnState ? eventType : ""
            // The subagent clock, kept beside the turn's and never mixed into it.
            // 1 = a subagent of this session just did something, so stamp it;
            // -1 = a subagent finished, so clear it; 0 = not about a subagent at
            // all, leave it alone. See `HookEventType.subagentClock`.
            let subagentClock = HookEventType.subagentClock(eventType, hookData: hookData)

            // 1. Upsert session. `last_activity_at` is the EVENT's own time, not
            // wall-clock `now`: a live hook fires with timestamp≈now (unchanged
            // behavior), but re-ingesting an OLD event (a restart's drop-dir
            // backlog, or a Retry-All of the quarantine) must NOT resurrect a
            // month-old session as "active now" and flood a sessions list.
            // `MAX(existing, event)` also keeps it monotonic against out-of-order
            // replays; `COALESCE(..., now)` falls back if the timestamp is unparseable.
            try execute("""
                INSERT INTO sessions(session_id, cwd, model, pid, term_program, term_session_id,
                                      account_email, auth_method, last_event_type, last_activity_at,
                                      turn_state_at, subagent_activity_at, subagent_stopped_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, COALESCE(datetime(?), datetime('now')),
                        CASE WHEN ? = 1 THEN COALESCE(datetime(?), datetime('now')) ELSE '' END,
                        CASE WHEN ? = 1 THEN COALESCE(datetime(?), datetime('now')) ELSE '' END,
                        CASE WHEN ? = -1 THEN COALESCE(datetime(?), datetime('now')) ELSE '' END)
                ON CONFLICT(session_id) DO UPDATE SET
                    -- The first two `? = 1` guards below are the same bound flag:
                    -- does this event count as activity? An ambient event (see
                    -- `HookEventType.ambientEventTypes`) leaves both columns alone,
                    -- because it fires for reasons outside the session — a settings
                    -- file saved, a status line redrawn — and moving the clock for it
                    -- dragged hours-idle sessions back inside a sessions list's
                    -- recency filter and re-lit their status icon.
                    last_activity_at = CASE WHEN ? = 1
                        THEN MAX(sessions.last_activity_at, excluded.last_activity_at)
                        ELSE sessions.last_activity_at END,
                    -- Activity alone is not enough to make a session active again:
                    -- an event whose timestamp doesn't advance `last_activity_at` is
                    -- a replay — a spool backlog draining after the migration that
                    -- held it, a restart's drop-dir sweep, a Retry-All of the
                    -- quarantine — and the `claude` behind it is long gone. Marking
                    -- those active resurrects sessions a daemon's liveness task already ended,
                    -- which is a phantom row in a sessions list and a spurious
                    -- status broadcast to every client; for a session with no cwd,
                    -- which liveness deliberately refuses to reconcile, the
                    -- resurrection is permanent. (SQLite evaluates every SET
                    -- expression against the OLD row, so this reads the pre-update
                    -- timestamp, not the MAX being assigned above.)
                    status     = CASE
                        WHEN ? = 1 AND excluded.last_activity_at > sessions.last_activity_at
                            THEN 'active'
                        ELSE sessions.status END,
                    -- Only the newest event about the main agent's turn may set the
                    -- activity icon's state (the third flag, `setsTurnState`). A
                    -- subagent finishing after the turn's `Stop`, or the idle
                    -- reminder a minute later, used to leave a finished session
                    -- spinning or asking for attention. And a replayed backlog
                    -- arrives out of order: without the timestamp guard the last row
                    -- re-ingested — not the last thing that happened — would decide
                    -- whether the session reads as working or waiting.
                    --
                    -- Ordered against `turn_state_at`, the turn state's OWN clock,
                    -- not `last_activity_at`. This is not the same test, because this
                    -- upsert is not the only writer: the interrupted-turn writer advances
                    -- `turn_state_at` and deliberately leaves `last_activity_at`
                    -- alone (an interrupt is not activity). Measured against activity
                    -- the comparison value therefore froze at the pre-interrupt
                    -- event, so every straggler that arrived afterwards — a drained
                    -- drop-dir backlog, a quarantine Retry-All, an `IngestDrainer`
                    -- replay — still compared `>=` and regressed Interrupted back to
                    -- a mid-turn state, which the interrupted-turn sweeper then re-marked
                    -- five seconds later: a session flickering between working and
                    -- interrupted, with a window that never closed. Both writers
                    -- maintain `turn_state_at`, so ordering on it closes it. (The
                    -- blank a migration041 backfill can leave sorts below every real
                    -- datetime, so an unknown-time state still yields to a real
                    -- event — the safe direction.)
                    last_event_type = CASE
                        WHEN ? = 1 AND excluded.turn_state_at >= sessions.turn_state_at
                            THEN excluded.last_event_type
                        ELSE sessions.last_event_type END,
                    -- When that state was set, under the same guard (the fourth flag is
                    -- `setsTurnState` again). The interrupted-turn sweeper needs it: the
                    -- transcript lags the hooks, so an interrupt marker is only news if
                    -- it is newer than the state it would replace.
                    turn_state_at = CASE
                        WHEN ? = 1 AND excluded.turn_state_at >= sessions.turn_state_at
                            THEN excluded.turn_state_at
                        ELSE sessions.turn_state_at END,
                    -- The subagent clock (the fifth flag, `HookEventType.subagentClock`):
                    -- 1 stamps it, -1 clears it because a stop is terminal, 0 leaves
                    -- it alone. A stamp must be newer than the last stamp AND the
                    -- last stop (migration045), so a replayed backlog cannot make a
                    -- finished subagent look live again — comparing against the
                    -- cleared '' alone let any older event through. The CLEAR is
                    -- deliberately unguarded by time, because a stop is the end of
                    -- that subagent whenever it is re-read.
                    subagent_activity_at = CASE
                        WHEN ? = -1 THEN ''
                        WHEN ? = 1 AND excluded.subagent_activity_at > sessions.subagent_activity_at
                                   AND excluded.subagent_activity_at > sessions.subagent_stopped_at
                            THEN excluded.subagent_activity_at
                        ELSE sessions.subagent_activity_at END,
                    subagent_stopped_at = CASE
                        WHEN excluded.subagent_stopped_at > sessions.subagent_stopped_at
                            THEN excluded.subagent_stopped_at
                        ELSE sessions.subagent_stopped_at END,
                    -- First non-empty cwd wins (a SessionStart still re-seats it).
                    -- Claude's own working directory is fixed for the session's
                    -- life, but the hook reports the *hook shell's* $PWD — so an
                    -- agent that `cd`s into a submodule used to move the session
                    -- out from under liveness, which then ended and resurrected it
                    -- on alternate ticks and made the row blink in the window.
                    cwd        = CASE
                        WHEN excluded.cwd != '' AND (sessions.cwd = '' OR ? = 'SessionStart')
                            THEN excluded.cwd
                        ELSE sessions.cwd END,
                    model      = CASE WHEN excluded.model != ''       THEN excluded.model       ELSE model       END,
                    pid        = CASE WHEN excluded.pid != 0          THEN excluded.pid         ELSE pid         END,
                    term_program = CASE WHEN excluded.term_program != '' THEN excluded.term_program
                                                                         ELSE term_program END,
                    term_session_id = CASE WHEN excluded.term_session_id != '' THEN excluded.term_session_id
                                                                              ELSE term_session_id END,
                    account_email = CASE
                        WHEN excluded.auth_method = 'token'
                            AND sessions.auth_method <> 'token' THEN excluded.account_email
                        WHEN excluded.auth_method = 'oauth'
                            AND sessions.auth_method = 'unknown' THEN excluded.account_email
                        WHEN sessions.auth_method <> 'token' AND sessions.account_email = '' THEN excluded.account_email
                        ELSE sessions.account_email END,
                    auth_method = CASE
                        WHEN excluded.auth_method = 'token'
                            AND sessions.auth_method <> 'token' THEN excluded.auth_method
                        WHEN excluded.auth_method = 'oauth'
                            AND sessions.auth_method = 'unknown' THEN excluded.auth_method
                        WHEN sessions.auth_method <> 'token' AND sessions.account_email = '' THEN excluded.auth_method
                        ELSE sessions.auth_method END
            """, params: [sessionId, sessionCwd, model, pid, termProg, termSession,
                          sessionAccount, authMethod, insertedEventType, timestamp, turnState, timestamp,
                          subagentClock, timestamp, subagentClock, timestamp,
                          isActivity, isActivity, turnState, turnState,
                          subagentClock, subagentClock, eventType])
            if let sessionUpsertHook {
                try sessionUpsertHook(self, sessionId, timestamp, isActivity == 1)
            }

            // 2. Update last_tool if this is a tool event
            if !toolName.isEmpty {
                try execute(
                    "UPDATE sessions SET last_tool = ? WHERE session_id = ?",
                    params: [toolName, sessionId]
                )
            }

            // 3. Mark session ended only on the real session-end hook. NOT "Stop" —
            // that fires after every assistant response, not when the session ends,
            // so ending on it marked every live session "ended".
            if eventType == "SessionEnd" {
                try execute(
                    "UPDATE sessions SET status = 'ended' WHERE session_id = ?",
                    params: [sessionId]
                )
            }

            // 4. Compute display detail
            let detail = computeDetail(eventType: eventType, hookData: hookData)

            // 5. Insert into event_log
            let contextJSON = Self.encodeContextJSON(context)
            try execute(
                """
                INSERT INTO event_log(session_id, event_type, timestamp, cwd, detail, context_json)
                VALUES (?,?,?,?,?,?)
                """,
                params: [sessionId, eventType, timestamp, cwd, detail, contextJSON]
            )
            let eventLogId = database.lastInsertedRowID

            // 6. Insert into per-type table (scalar fields only)
            if let knownType = HookEventType(rawValue: eventType) {
                var perType: [String: Any] = [
                    "event_log_id": eventLogId,
                    "session_id": sessionId,
                    "timestamp": timestamp,
                    "cwd": cwd
                ]
                for (key, value) in hookData {
                    if key == "session_id" || key == "cwd" || key == "timestamp" { continue }
                    if value is [String: Any] || value is [Any] { continue }
                    perType[key] = value
                }
                if knownType == .statusLine {
                    // The status-line payload's substance is all nested — model,
                    // cost, context_window, prompt_cache, rate_limits — and the
                    // loop above drops every object it meets, so the table held
                    // ten housekeeping columns and none of the numbers. Flatten
                    // the whole tree instead: DynamicSchema issues the ALTER for
                    // a name it hasn't seen, so a field Anthropic adds next
                    // release is recorded the first render it arrives on, with
                    // no migration and no code change here.
                    //
                    // Gated to StatusLine on purpose. Most of its payload is a
                    // published contract with a bounded shape; `tool_input` is
                    // whatever a tool felt like sending, and flattening that
                    // would grow a column per distinct key until the table hit
                    // SQLite's 2000 limit. Those already have `tool_inputs` /
                    // `tool_responses`.
                    //
                    // "Most" because the payload is not bounded everywhere:
                    // `prompt_cache.miss_causes` is a map keyed by cause name.
                    // `flattenLeaves` keeps that subtree as JSON text for the
                    // same reason the gate exists — see `opaquePayloadSubtrees`
                    // — and `DynamicSchema.maxColumns` catches the next such
                    // field before it can reach the 2000 either.
                    for (key, value) in Self.flattenLeaves(hookData) {
                        if key == "session_id" || key == "cwd" || key == "timestamp" { continue }
                        perType[key] = value
                    }
                }
                // Both of these name a `file_path` whose *contents* are the
                // thing we care about — a settings/skill file for ConfigChange,
                // a CLAUDE.md for InstructionsLoaded — and neither payload
                // carries a size or hash. Without one, `instructions_loaded_events`
                // repeats the same paths forever and cannot say whether an edit
                // to those instructions is what invalidated the prompt cache.
                if knownType == .configChange || knownType == .instructionsLoaded {
                    for (key, value) in FileFingerprintEnricher.enrich(hookData: hookData) {
                        perType[key] = value
                    }
                }
                if knownType == .postToolUse || knownType == .postToolUseFailure {
                    if let durationMs = computePostToolDurationMs(
                        sessionId: sessionId,
                        toolUseId: hookData["tool_use_id"] as? String ?? "",
                        postTimestamp: timestamp
                    ) {
                        perType["duration_ms"] = durationMs
                    }
                }
                try insertDynamic(table: knownType.tableName, fields: perType)
            }

            // 7. Insert nested tool_input
            if let toolInput = hookData["tool_input"] as? [String: Any] {
                var fields: [String: Any] = ["event_log_id": eventLogId, "event_type": eventType]
                for (key, value) in toolInput {
                    if !(value is [String: Any]) && !(value is [Any]) { fields[key] = value }
                }
                if fields.count > 2 {  // more than just the fixed cols
                    try insertDynamic(table: "tool_inputs", fields: fields)
                }
            }

            // 8. Insert nested tool_response
            if let toolResponse = hookData["tool_response"] as? [String: Any] {
                var fields: [String: Any] = ["event_log_id": eventLogId]
                for (key, value) in toolResponse {
                    if !(value is [String: Any]) && !(value is [Any]) { fields[key] = value }
                }
                if fields.count > 1 {
                    try insertDynamic(table: "tool_responses", fields: fields)
                }
            }

            // 9. Record branch creations (EnterWorktree / git branch-creating
            // bash commands) so a Stop hook can later block a session that
            // leaves merged-but-undeleted branches behind.
            if let creation = detectBranchCreation(
                eventType: eventType,
                toolName: toolName,
                cwd: cwd,
                hookData: hookData
            ) {
                try? execute(
                    """
                    INSERT OR IGNORE INTO session_branches
                        (session_id, repo_path, branch_name, source)
                    VALUES (?, ?, ?, ?)
                    """,
                    params: [sessionId, creation.repoPath, creation.branchName, creation.source]
                )
            }

            // 10. StatusLine payload routing — feeds rate_limit_snapshots,
            // claude_versions, and the extended session_metrics columns
            // added in migration007. Subsumes what CSL used to write
            // directly to its own SQLite files.
            if eventType == "StatusLine", let statusLineIngest {
                try statusLineIngest(self, sessionId, hookData, timestamp, snapshotAccount)
            }

            return IngestedEvent(
                id: eventLogId,
                event: eventType,
                sessionId: sessionId,
                timestamp: timestamp,
                cwd: cwd,
                detail: detail,
                toolName: toolName,
                model: model,
                source: source
            )
        }
    }

    // MARK: - Payload flattening

    /// Every leaf of a nested payload, keyed by its underscore-joined path:
    /// `prompt_cache.hit_ratio` becomes `prompt_cache_hit_ratio`.
    ///
    /// Underscores rather than dots because these names become SQL columns, and
    /// a dotted identifier has to be quoted at every call site from now on.
    /// The paths this produces are therefore *not* the dotted ones
    /// `extractFieldPaths` records in `claude_versions` — that set describes the
    /// payload's shape, this one names storage.
    ///
    /// An array is kept as its JSON text — `workspace.added_dirs` is a list, and
    /// a dropped list can't be told from an empty one. So is an object named in
    /// `opaquePayloadSubtrees`. Either one that will not serialise is DROPPED
    /// rather than written as `"[]"` / `"{}"`: an empty-looking value is the same
    /// lie in the other direction, and an absent column already reads as absent.
    ///
    /// A JSON null is dropped, which costs nothing and buys the column its right
    /// type. A null leaf carries no value to record, and the column it would
    /// create has no type to infer, so `DynamicSchema` would fall back to TEXT
    /// and every later number in that column would sort as a string. Skipping it
    /// loses no per-row information: an omitted column reads back as NULL, the
    /// same as one bound to NULL. What *is* only recorded when a null appears —
    /// that the field existed at all — is already in `claude_versions.field_paths`,
    /// which walks every key regardless of value.
    public static func flattenLeaves(_ value: Any, prefix: String = "") -> [String: Any] {
        guard let dict = value as? [String: Any] else { return [:] }
        var leaves: [String: Any] = [:]
        for (key, val) in dict {
            let path = prefix.isEmpty ? key : "\(prefix)_\(key)"
            if val is NSNull {
                continue
            } else if val is [String: Any], !opaquePayloadSubtrees.contains(path) {
                for (nested, nestedValue) in flattenLeaves(val, prefix: path) {
                    leaves[nested] = nestedValue
                }
            } else if val is [String: Any] || val is [Any] {
                if let text = jsonText(val) { leaves[path] = text }
            } else {
                leaves[path] = val
            }
        }
        return leaves
    }

    /// Payload objects kept whole, as JSON text, instead of flattened into a
    /// column per key.
    ///
    /// Flattening is safe for an object whose keys are a bounded published set.
    /// It is not safe for a map keyed by whatever the producer happened to meet,
    /// and `prompt_cache.miss_causes` is exactly that: one key per cache-miss
    /// cause, a set that grows as Anthropic names causes and multiplies with the
    /// ones that embed a TTL (`ttl_expired_1h`, `ttl_expired_5m`, …). Neither it
    /// nor `last_miss_cause` appears in the public field reference at all — this
    /// repo says so itself, in `StatusLineBaseInfo.promptCacheCell`'s doc — so
    /// there is no contract bounding either one. A column apiece would accrete
    /// for the life of the install, which is precisely what the StatusLine gate
    /// exists to avoid; one TEXT column holds every cause, and `json_extract`
    /// reads any of them back out.
    public static let opaquePayloadSubtrees: Set<String> = [
        "prompt_cache_miss_causes",
        "prompt_cache_last_miss_cause"
    ]

    /// A subtree re-serialised for storage in one TEXT column, or nil when it
    /// cannot be.
    ///
    /// `isValidJSONObject` is the guard, not `try?`: `data(withJSONObject:)`
    /// signals an unrepresentable value by raising an **Objective-C exception**,
    /// which is not a Swift error and which `try?` does not catch — it unwinds
    /// straight past every `do`/`catch` here and terminates the daemon. That
    /// matters even though the values normally come from `JSONSerialization`
    /// (which only ever produces representable ones): this is a static helper on
    /// the ingest path, `flattenLeaves` is called from tests and could be called
    /// from anywhere else tomorrow, and the whole quarantine design rests on a
    /// malformed payload failing its own event rather than the process.
    private static func jsonText(_ value: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Event reads

    public func fetchEvents(
        sessionId: String? = nil,
        eventType: String? = nil,
        since: String? = nil,
        limit: Int = 50,
        offset: Int = 0,
        excludeRootCwd: Bool = false
    ) throws -> [SessionEventDTO] {
        var conditions: [String] = []
        var params: [any Sendable] = []

        if let sessionId {
            conditions.append("e.session_id = ?")
            params.append(sessionId)
        }
        if let eventType {
            conditions.append("e.event_type = ?")
            params.append(eventType)
        }
        if let since {
            // datetime() normalises both ISO 8601 and SQLite formats for safe comparison
            conditions.append("datetime(e.timestamp) >= datetime(?)")
            params.append(since)
        }
        if excludeRootCwd {
            conditions.append("e.cwd != '/'")
        }

        var sql = Self.sessionEventSelect
        if !conditions.isEmpty {
            sql += " WHERE " + conditions.joined(separator: " AND ")
        }
        sql += " ORDER BY e.timestamp DESC LIMIT ? OFFSET ?"
        params.append(limit)
        params.append(offset)

        var results: [SessionEventDTO] = []
        try query(sql, params: params) { row in results.append(sessionEvent(from: row)) }
        return results
    }

    /// The one column list both event readers select, in the order
    /// `sessionEvent(from:)` reads it by position. One definition, so the two
    /// readers cannot drift apart.
    private static let sessionEventSelect = """
        SELECT e.id, e.session_id, e.event_type, e.timestamp, e.cwd, e.detail,
               COALESCE(s.git_branch, '') AS git_branch
        FROM event_log e
        LEFT JOIN sessions s ON s.session_id = e.session_id
        """

    private func sessionEvent(from row: Row) -> SessionEventDTO {
        SessionEventDTO(
            id: Int(int(row, 0)),
            sessionId: string(row, 1),
            eventType: string(row, 2),
            timestamp: string(row, 3),
            cwd: string(row, 4),
            detail: string(row, 5),
            gitBranch: string(row, 6)
        )
    }

    /// A session with its newest `recentLimit` events (see `fetchRecentEvents`),
    /// or nil if there is no such session — what `/sessions/:id` and the XPC
    /// `getSessionDetail` both answer.
    public func fetchSessionDetail(sessionId: String, recentLimit: Int) throws -> SessionDetailDTO? {
        guard let session = try fetchSession(sessionId: sessionId) else { return nil }
        return SessionDetailDTO(
            session: session, recentEvents: try fetchRecentEvents(sessionId: sessionId, limit: recentLimit))
    }

    /// The newest `limit` events of one session, newest first by event time.
    ///
    /// `ORDER BY e.timestamp` over the whole session has no index to walk, so
    /// SQLite reads *every* event of the session (each a random read of a fat
    /// row) into a temp b-tree before the LIMIT can discard any. Walking
    /// `idx_event_log_session_id` backwards by rowid stops at a LIMIT instead.
    /// Measured on a real 51 GB db, newest 500 of a 137k-event session: 1,277 ms
    /// warm → 8 ms, and seconds of disk when cold.
    ///
    /// Capture order is not event order, though: the JSONL sweep of subagent
    /// transcripts and a quarantine re-ingest insert rows minutes or hours
    /// after the fact, under their original timestamps, with the highest ids.
    /// So the index walk takes a *window* of the newest captures, larger than
    /// `limit` by `recentEventsSlack`, and only that window is sorted by
    /// time. A late batch up to the slack's size then sorts into its real place
    /// instead of pushing genuinely newer events out. An exact answer would
    /// need a `(session_id, timestamp)` index on `event_log` — a build over
    /// tens of GB at launch, the risk `ensureTranscriptTurnTokenIndex` shows —
    /// for a read whose callers want "what just happened". Paged API reads keep
    /// `fetchEvents`.
    public func fetchRecentEvents(sessionId: String, limit: Int) throws -> [SessionEventDTO] {
        let window = max(limit * 4, limit + Self.recentEventsSlack)
        var results: [SessionEventDTO] = []
        try query("""
            SELECT * FROM (
                \(Self.sessionEventSelect)
                WHERE e.session_id = ?
                ORDER BY e.id DESC
                LIMIT ?
            )
            ORDER BY timestamp DESC, id DESC
            LIMIT ?
        """, params: [sessionId, window, limit]) { row in results.append(sessionEvent(from: row)) }
        return results
    }

    /// How many late-captured rows `fetchRecentEvents` absorbs beyond `limit`.
    public static let recentEventsSlack = 200

    /// Returns a rich event payload: the `event_log` row, its per-type
    /// detail row (if the `<type>_events` table exists), and any
    /// associated `tool_inputs` / `tool_responses` rows. Used by the
    /// menubar log's double-click detail window. Values are returned as
    /// `[String: Any]` so dynamic per-type columns serialise without a
    /// bespoke DTO per event variant.
    public func fetchEventDetail(eventLogId: Int64) throws -> [String: Any]? {
        // Read-only (event_log + per-type + tool tables) → read lane, so a
        // GET /events/:id detail fetch runs on a reader and never blocks ingest.
        try read { _ in
            var result: [String: Any]?
            var eventType = ""
            try query("""
                SELECT id, session_id, event_type, timestamp, cwd, detail
                FROM event_log WHERE id = ?
            """, params: [eventLogId]) { row in
                eventType = string(row, 2)
                result = [
                    "id": Int(int64(row, 0)),
                    "session_id": string(row, 1),
                    "event_type": eventType,
                    "timestamp": string(row, 3),
                    "cwd": string(row, 4),
                    "detail": string(row, 5)
                ]
            }
            guard var core = result else { return nil }

            // Pass session_id so the per-type lookup seeks the (session_id, event_log_id)
            // index instead of full-scanning the table.
            let sessionId = core["session_id"] as? String
            if let kind = HookEventType(rawValue: eventType),
               let row = try? fetchRowByEventLogId(
                   table: kind.tableName, eventLogId: eventLogId, sessionId: sessionId) {
                core["type_fields"] = stripRedundantFields(row)
            }
            if let input = try? fetchRowByEventLogId(table: "tool_inputs", eventLogId: eventLogId) {
                core["tool_input"] = stripRedundantFields(input)
            }
            if let response = try? fetchRowByEventLogId(table: "tool_responses", eventLogId: eventLogId) {
                core["tool_response"] = stripRedundantFields(response)
            }
            return core
        }
    }

    /// Selects a single row from `table` by `event_log_id`, additionally constraining on
    /// `session_id` when provided so the per-type `(session_id, event_log_id)` index
    /// (migration013) serves the lookup instead of a full table scan. `tool_inputs` /
    /// `tool_responses` have no `session_id`, so they pass nil and rely on their
    /// `event_log_id` index (migration014). Returns nil if no row matches (and throws if
    /// the table doesn't exist — callers wrap in `try?`).
    private func fetchRowByEventLogId(
        table: String, eventLogId: Int64, sessionId: String? = nil
    ) throws -> [String: Any]? {
        var row: [String: Any]?
        let sql: String
        let params: [any Sendable]
        if let sessionId {
            sql = #"SELECT * FROM "\#(table)" WHERE session_id = ? AND event_log_id = ? LIMIT 1"#
            params = [sessionId, eventLogId]
        } else {
            sql = #"SELECT * FROM "\#(table)" WHERE event_log_id = ? LIMIT 1"#
            params = [eventLogId]
        }
        try query(sql, params: params) { dbRow in
            var fields: [String: Any] = [:]
            for columnName in dbRow.columnNames {
                let value: DatabaseValue = dbRow[columnName]
                switch value.storage {
                case .int64(let number): fields[columnName] = Int(number)
                case .double(let number): fields[columnName] = number
                case .string(let text): fields[columnName] = text
                case .blob(let data): fields[columnName] = String(data: data, encoding: .utf8) ?? ""
                case .null: continue
                }
            }
            row = fields
        }
        return row
    }

    /// Removes fields already present on the top-level event payload
    /// (ids, session_id, timestamp, cwd, event_type) so the nested
    /// `type_fields` / `tool_input` / `tool_response` dicts show only
    /// what's unique to that row.
    private func stripRedundantFields(_ fields: [String: Any]) -> [String: Any] {
        var copy = fields
        for key in ["id", "event_log_id", "session_id", "timestamp", "cwd", "event_type"] {
            copy.removeValue(forKey: key)
        }
        return copy
    }

    // MARK: - Event log insert for JSONL import

    /// Insert into event_log with a message_id dedup key. Returns the new
    /// event_log row ID, or `nil` if the message_id was already present
    /// (unique index kicks in). Empty `messageId` disables dedup.
    @discardableResult
    public func insertImportedEvent(
        eventType: String,
        timestamp: String,
        sessionId: String,
        cwd: String,
        detail: String,
        messageId: String
    ) throws -> Int64? {
        try write { database in
            // Dedup is enforced by the partial UNIQUE index on message_id
            // (idx_event_log_message_id, WHERE message_id != ''). `INSERT OR
            // IGNORE` lets that index reject duplicates as an O(log n) probe.
            // A pre-check `SELECT … WHERE message_id = ?` full-scans event_log:
            // SQLite uses a partial index only when the query's WHERE clause
            // includes the index predicate (`message_id != ''`); a bare equality
            // omits it (even a literal `= 'x'` scans), so the index goes unused —
            // pathological once the table is large.
            // Empty message_id falls outside the index, so it always inserts
            // (dedup disabled). Mirrors `insertTranscriptTurn`.
            try execute("""
                INSERT OR IGNORE INTO event_log (session_id, event_type, timestamp, cwd, detail, message_id)
                VALUES (?, ?, ?, ?, ?, ?)
            """, params: [sessionId, eventType, timestamp, cwd, detail, messageId])
            return database.changesCount > 0 ? database.lastInsertedRowID : nil
        }
    }

    // MARK: - Ingest support

    /// Correlates a PostToolUse / PostToolUseFailure back to its matching
    /// PreToolUse (by `session_id` + `tool_use_id`) and returns elapsed
    /// milliseconds. Returns nil if no matching pre-row is found, the
    /// `pre_tool_use_events` table doesn't yet have a `tool_use_id` column,
    /// or either timestamp fails to parse. Runs on the DB queue — only
    /// called from inside `ingestEvent`'s write transaction.
    private func computePostToolDurationMs(
        sessionId: String,
        toolUseId: String,
        postTimestamp: String
    ) -> Int? {
        guard !sessionId.isEmpty, !toolUseId.isEmpty,
              tableHasColumn("pre_tool_use_events", "tool_use_id") else { return nil }

        var preTimestamp: String?
        try? query("""
            SELECT timestamp FROM pre_tool_use_events
            WHERE session_id = ? AND tool_use_id = ?
            ORDER BY event_log_id DESC LIMIT 1
        """, params: [sessionId, toolUseId]) { row in
            preTimestamp = string(row, 0)
        }
        guard let pre = preTimestamp, !pre.isEmpty,
              let preDate = TimestampParsing.parse(pre),
              let postDate = TimestampParsing.parse(postTimestamp) else { return nil }
        let delta = postDate.timeIntervalSince(preDate) * 1000.0
        guard delta >= 0 else { return nil }
        return Int(delta.rounded())
    }

    /// Serialises a context dict to JSON for the `event_log.context_json`
    /// column. Returns `''` for nil / empty / unserializable input so the
    /// column always has a stable string value.
    private static func encodeContextJSON(_ context: [String: Any]?) -> String {
        guard let context, !context.isEmpty else { return "" }
        guard JSONSerialization.isValidJSONObject(context),
              let data = try? JSONSerialization.data(withJSONObject: context, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return ""
        }
        return json
    }

    /// Inserts a row into `table` using only the scalar values in `fields`.
    /// Calls DynamicSchema to add missing columns first.
    private func insertDynamic(table: String, fields: [String: Any]) throws {
        // Separate scalars from nested objects
        var scalars: [String: Any] = [:]
        for (key, value) in fields {
            if value is [String: Any] || value is [Any] { continue }
            // Both the ALTER in DynamicSchema and the INSERT below interpolate
            // the key into a quoted SQL identifier — an identifier cannot be
            // bound — and these keys come from payloads this repo does not
            // control. Drop a name that would need escaping rather than escape
            // it: one missing field beats a statement that reparses as SQL.
            guard DynamicSchema.isSafeColumnName(key) else {
                logger.error("insertDynamic: dropping unusable column name '\(key, privacy: .public)'")
                continue
            }
            scalars[key] = value
        }
        guard !scalars.isEmpty else { return }

        try write { database in
            // Confined to the columns `ensureColumns` reports the table actually
            // has. A key it declined — an over-budget table — would otherwise
            // still be named here, and `no such column` would roll back the
            // caller's entire event transaction rather than lose one field.
            let available = try self.dynamicSchema.ensureColumns(
                for: table, fields: scalars, database: database
            )
            let cols = scalars.keys.filter(available.contains).sorted()
            guard !cols.isEmpty else { return }
            let colList = cols.map { #""\#($0)""# }.joined(separator: ", ")
            let placeholders = cols.map { _ in "?" }.joined(separator: ", ")
            let sql = #"INSERT INTO "\#(table)" (\#(colList)) VALUES (\#(placeholders))"#
            try database.execute(sql: sql, arguments: try Self.args(cols.map { scalars[$0]! }))
        }
    }
}
#endif
