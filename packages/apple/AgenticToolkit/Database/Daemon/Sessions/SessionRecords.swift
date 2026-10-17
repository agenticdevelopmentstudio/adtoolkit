#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

// MARK: - Session store

extension DaemonDatabase {

    // MARK: - Session writes (synchronous single-row updates)
    //
    // These commit before returning (via `execute` on the write lane). They were
    // once fire-and-forget, but an asynchronous write raced the read lane: a read on
    // a separate reader connection could run before the write committed and miss it.
    // Committing synchronously keeps read-your-writes strong across the read pool;
    // the cost is a single-row UPDATE's latency.

    public func updateSessionStatus(_ status: SessionStatus, sessionId: String) {
        do {
            try execute(
                "UPDATE sessions SET status = ? WHERE session_id = ?",
                params: [status.rawValue, sessionId]
            )
        } catch {
            logger.error("updateSessionStatus failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func updateSessionGitBranch(_ branch: String, sessionId: String) {
        // A blank is never an improvement on a branch already recorded: it is what a
        // `git` that declined to answer looks like, and the Sessions window would
        // show the row losing its branch rather than keeping the last known one.
        guard !branch.isEmpty else { return }
        do {
            try execute(
                "UPDATE sessions SET git_branch = ? WHERE session_id = ?",
                params: [branch, sessionId]
            )
        } catch {
            logger.error("updateSessionGitBranch failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Writes the resolved `project_root` (possibly empty for a non-git cwd) and
    /// stamps the algorithm `version` that produced it, so the backfill won't
    /// recompute this row until the version advances.
    public func updateSessionProjectRoot(_ projectRoot: String, version: Int, sessionId: String) {
        do {
            try execute(
                "UPDATE sessions SET project_root = ?, project_root_version = ? WHERE session_id = ?",
                params: [projectRoot, version, sessionId]
            )
        } catch {
            logger.error("updateSessionProjectRoot failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func updateSessionSummary(_ summary: String, sessionId: String) {
        do {
            // Stamped, not just stored: `summary = ''` can say "never summarized"
            // but not "summarized before the session did another hour of work",
            // which is the question `fetchSessionIdsNeedingSummary` has to answer
            // for a session that is still running.
            try execute(
                "UPDATE sessions SET summary = ?, summary_at = datetime('now') WHERE session_id = ?",
                params: [summary, sessionId]
            )
        } catch {
            logger.error("updateSessionSummary failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Clears summaries that aren't short titles (multi-line or very long) — e.g. older
    /// AI summaries from before the brevity guard, which rendered as paragraphs in the
    /// window. Emptied ones get a clean re-summary from `SummarizeTask`. Idempotent.
    /// Blanks rambling pre-cap AI summaries so `SummarizeTask` regenerates them short.
    /// Scoped to `ended` sessions only: those are the ones `SummarizeTask` refills, so
    /// active/stale sessions are never stranded with a wiped (un-refillable) summary,
    /// and a live session's Claude Code custom title is left intact.
    ///
    /// - Parameter maxCharacters: the summarizer's own character cap, which now moves
    ///   with the user's word limit. This runs on **every** daemon start, so a
    ///   threshold below what the summarizer produces would wipe good titles and
    ///   re-bill a model call for each one at every launch, forever. Pass
    ///   `SummaryDefaults.characterCap(maxWords:)` for the configured limit.
    public func clearOverlongSummaries(
        maxCharacters: Int = SummaryDefaults.characterCap(maxWords: SummaryDefaults.maxWords) + 10
    ) {
        try? execute("""
            UPDATE sessions SET summary = ''
            WHERE status = 'ended'
              AND (length(summary) > ? OR instr(summary, char(10)) > 0)
        """, params: [maxCharacters])
    }

    /// Clears every summary that is literally its session's transcript title — the
    /// residue of `SessionEnricher` once writing the title into `summary`. Idempotent.
    ///
    /// `updateSessionTranscriptTitle` already clears this, but only for the session
    /// whose title it is writing, which happens on that session's next `Stop`. An
    /// idle session never has one, so it kept showing "surge" where its summary
    /// belonged — and, its summary being non-empty, `fetchSessionIdsNeedingSummary`
    /// never offered it to the summarizer either. Every status, unlike
    /// `clearOverlongSummaries`: an emptied summary is refilled for any status now.
    public func clearTitleEchoSummaries() {
        try? execute("""
            UPDATE sessions SET summary = '', summary_at = ''
            WHERE summary != '' AND summary = transcript_title
        """)
    }

    /// Returns (sessionId, cwd, projectRootVersion) for every session still needing
    /// enrichment: missing git_branch or summary, or whose project_root was last
    /// computed below `currentProjectRootVersion`. The version gate (rather than
    /// `project_root = ''`) means a resolved row — including a non-git session whose
    /// root is legitimately '' — is enriched once and then skipped, instead of
    /// re-running git every startup. Live (active/stale) sessions come first, then
    /// most-recent, so the window's sessions enrich before the ended tail.
    /// Rows the startup backfill should sweep: something is still missing AND this
    /// row hasn't been swept at `currentEnrichmentVersion` yet.
    ///
    /// The enrichment-version gate is what makes the pass converge. Selecting on
    /// absence alone doesn't: absence is often permanent (no `custom-title` line in
    /// the transcript, a `cwd` that no longer exists), so it re-selected the same
    /// ~1,260 rows at every launch — see `migration030`.
    ///
    /// But the gate applies to the *absence* half only. A stale `project_root_version`
    /// is a different kind of eligibility: it says the algorithm that computed the
    /// stored root has been superseded, so the row must be recomputed even though it
    /// was swept before — the previous sweep ran the OLD algorithm. Folding it under
    /// the same `AND enrichment_version < ?` made a `projectRootAlgoVersion` bump a
    /// no-op for every already-swept row (i.e. nearly all of them), which is exactly
    /// the population the bump exists to fix. The two halves are therefore OR'd, each
    /// with its own gate.
    public func sessionsNeedingEnrichment(currentProjectRootVersion: Int, currentEnrichmentVersion: Int)
        throws -> [(sessionId: String, cwd: String, projectRootVersion: Int)] {
        // Read-only scan → read lane, so it never holds the single writer against ingest.
        try read { _ in
            var out: [(String, String, Int)] = []
            try query("""
                SELECT session_id, cwd, project_root_version FROM sessions
                WHERE project_root_version < ?
                   OR ((git_branch = '' OR summary = '') AND enrichment_version < ?)
                ORDER BY (status = 'ended'), last_activity_at DESC
            """, params: [currentProjectRootVersion, currentEnrichmentVersion]) { row in
                out.append((string(row, 0), string(row, 1), Int(int(row, 2))))
            }
            return out
        }
    }

    /// The stored `project_root_version` **and `cwd`** for one session, or nil when
    /// there is no such row. The single-session counterpart to
    /// `sessionsNeedingEnrichment`, for the ingestion path: a session whose
    /// `SessionStart` this daemon never saw (it was running before the daemon started,
    /// or the hook was installed mid-session) has a version of 0 and no project root,
    /// and until now nothing but a daemon restart's backfill would ever give it one —
    /// so it sat in the Sessions window labelled and grouped by its `cwd` for as long
    /// as it lived.
    ///
    /// The `cwd` travels with the version because the caller needs the session's own
    /// frozen directory, not the directory the individual hook happened to fire from.
    /// They are not the same thing the moment an agent `cd`s somewhere else, and a
    /// repair that reads the wrong one writes a neighbouring repository's branch onto
    /// the session.
    public func sessionProjectRootProbe(sessionId: String) throws -> (version: Int, cwd: String)? {
        try read { _ in
            var probe: (version: Int, cwd: String)?
            try query(
                "SELECT project_root_version, cwd FROM sessions WHERE session_id = ?",
                params: [sessionId]
            ) { row in
                probe = (version: Int(int(row, 0)), cwd: string(row, 1))
            }
            return probe
        }
    }

    /// Marks a session as swept by the startup enrichment pass, so a value the pass
    /// could not find isn't hunted for again on every launch.
    ///
    /// **Only stamps `ended` sessions**, and the `WHERE` does that gating so no extra
    /// read is needed. An `active` or `stale` session's transcript is still growing:
    /// a title added later arrives via the `Stop`/`SessionEnd` handler, but if the
    /// daemon happens to be down for that hook the backfill is the only thing that
    /// would ever pick it up — so live rows stay eligible. They are also the cheap
    /// case (25 of 5,808 sessions here); the 1,256 ended rows are the whole cost.
    /// Takes the ids in bulk rather than one call per session: the backfill stamps
    /// ~1,260 rows on a first sweep, and one `execute` apiece is 1,260 separate
    /// write-lane trips, each acquiring the single writer and committing its own
    /// transaction — against ingest, on the startup path. Chunked at 500 to stay
    /// well inside SQLite's `SQLITE_MAX_VARIABLE_NUMBER` (conservatively 999) with
    /// room for the three non-id parameters.
    ///
    /// - Parameter onlyInactiveForDays: when set, additionally requires
    ///   `last_activity_at` to be at least that old. It exists for the one row the
    ///   pass would otherwise chase forever: a session whose `cwd` is not on disk is
    ///   deliberately left unstamped, because an unmounted volume comes back and the
    ///   stamp would permanently retire the row — but a *deleted* directory never
    ///   does, so that row is re-enriched (a `git` subprocess and a title lookup) on
    ///   every daemon launch for the life of the install. Age is the only available
    ///   signal that separates the two, and it separates them well: a cwd missing for
    ///   a month is gone, and if it does reappear a `projectRootAlgoVersion` bump
    ///   re-opens the row anyway. The condition is SQL rather than a caller-side
    ///   filter so it evaluates against the row's own committed `last_activity_at`,
    ///   with no second read.
    public func stampSessionEnrichment(version: Int, sessionIds: [String], onlyInactiveForDays: Int? = nil) {
        guard !sessionIds.isEmpty else { return }
        // Bound as a datetime modifier, never interpolated (see `fetchSessions`).
        let ageClause = onlyInactiveForDays == nil
            ? "" : " AND last_activity_at < datetime('now', ?)"
        do {
            for start in stride(from: 0, to: sessionIds.count, by: 500) {
                let slice = Array(sessionIds[start..<Swift.min(start + 500, sessionIds.count)])
                let placeholders = Array(repeating: "?", count: slice.count).joined(separator: ",")
                var params: [any Sendable] = [version, SessionStatus.ended.rawValue]
                if let onlyInactiveForDays { params.append("-\(onlyInactiveForDays) days") }
                params.append(contentsOf: slice)
                try execute("""
                    UPDATE sessions SET enrichment_version = ?
                    WHERE status = ?\(ageClause) AND session_id IN (\(placeholders))
                """, params: params)
            }
        } catch {
            logger.error("stampSessionEnrichment failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Session reads

    /// Session IDs that want a summary, newest first, capped to `limit`. Lean read
    /// for `SummarizeTask`: it only needs IDs, so this skips the
    /// `LEFT JOIN event_log … COUNT(e.id)` that `fetchSessions` pays — never scanning
    /// the (large) event_log just to pick a handful of sessions to summarize.
    ///
    /// Two populations, active ones first because they are what the Sessions window
    /// is showing right now:
    ///
    ///   1. **Never summarized** (`summary = ''`), any status. This used to be
    ///      restricted to `status = 'ended'`, which meant no session was ever
    ///      summarized while you could still see it — every visible row's summary
    ///      line was a placeholder, permanently.
    ///   2. **Active and overtaken by its own work** — there has been activity since
    ///      the summary was written. `refreshAfter` is the floor on how often that
    ///      may re-bill a model call; without it a busy session would re-summarize on
    ///      every single pass.
    public func fetchSessionIdsNeedingSummary(limit: Int, refreshAfter: TimeInterval = 600) throws -> [String] {
        // Read-only → read lane (see sessionsNeedingEnrichment).
        try read { _ in
            var out: [String] = []
            try query("""
                SELECT session_id FROM sessions
                WHERE summary = ''
                   OR (status = ?
                       AND summary_at != ''
                       AND last_activity_at > summary_at
                       AND summary_at <= datetime('now', ?))
                ORDER BY (status = ?) DESC, last_activity_at DESC
                LIMIT ?
            """, params: [SessionStatus.active.rawValue,
                          "-\(Int(refreshAfter)) seconds",
                          SessionStatus.active.rawValue,
                          limit]) { row in
                out.append(string(row, 0))
            }
            return out
        }
    }

    /// Whether one session is eligible for a summary right now — the same predicate
    /// `fetchSessionIdsNeedingSummary` selects on, asked about a single row.
    ///
    /// The batch drain and the `Stop`-hook prompt path must agree on eligibility, so
    /// the condition is written once, here, rather than twice. The prompt path is what
    /// makes a summary arrive seconds after the agent stops speaking instead of
    /// whenever the next scheduled pass reaches this session: the batch runs every
    /// `summary_interval_minutes` and takes `maxPerRun` sessions, so a live session
    /// waited out an interval for its first summary even though its transcript had
    /// been complete since the moment `Stop` fired.
    public func sessionNeedsSummary(sessionId: String, refreshAfter: TimeInterval = 600) throws -> Bool {
        try read { _ in
            var needed = false
            try query("""
                SELECT 1 FROM sessions
                WHERE session_id = ?
                  AND (summary = ''
                       OR (status = ?
                           AND summary_at != ''
                           AND last_activity_at > summary_at
                           AND summary_at <= datetime('now', ?)))
            """, params: [sessionId,
                          SessionStatus.active.rawValue,
                          "-\(Int(refreshAfter)) seconds"]) { _ in
                needed = true
            }
            return needed
        }
    }

    /// `includeEventCount: false` drops the per-row `COUNT(*)` subquery over `event_log`,
    /// returning `eventCount = 0`. The Sessions-window poll hits this every few
    /// seconds and discards the count, so it opts out; the CLI/insights keep it.
    /// `sinceHours` keeps only sessions whose `last_activity_at` is within the
    /// last N hours, any status — the Sessions window's time filter (nil/0 = all).
    /// - Parameter limit: hard ceiling on rows materialised, applied in SQL so the
    ///   array can't exceed it. `nil` means unbounded and is only for callers with
    ///   an inherently bounded result; `sessions` grows for the life of the install
    ///   (5,810 rows / 3.4 MB of JSON on one real machine), so the HTTP and XPC
    ///   list paths always pass one.
    /// - Parameter project: substring match against `cwd`. It belongs in SQL rather
    ///   than in the caller because `limit` is applied by SQL: filtering afterwards
    ///   takes the newest `limit` sessions and *then* narrows, so a project whose
    ///   sessions all fall outside that newest slice returns empty — the filter reads
    ///   as "no such project" when the truth is "not in the last N rows". In SQL the
    ///   ceiling applies to the matches, which is what a caller passing both means.
    public func fetchSessions(
        status: SessionStatus? = nil,
        sinceHours: Int? = nil,
        project: String? = nil,
        includeEventCount: Bool = true,
        limit: Int? = nil
    ) throws -> [SessionDTO] {
        // A correlated subquery, NOT `LEFT JOIN event_log … GROUP BY`. The join
        // plan aggregates every matching session's events into a temp b-tree
        // before the ORDER BY/LIMIT can discard any of them, so `limit` bounded
        // the response but not the work — the same trap `graphSnapshot` was
        // rewritten to escape. Measured on a real 553 MB db (1,369 sessions /
        // 66,309 events), `LIMIT 200`:
        //   join+GROUP BY  → SCAN s USING idx_sessions_session_id
        //                    + USE TEMP B-TREE FOR ORDER BY   (31 ms)
        //   subquery       → SCAN s USING idx_sessions_last_activity
        //                    + CORRELATED SCALAR SUBQUERY      (6 ms)
        // The rewrite walks `idx_sessions_last_activity` in order (no sorter, so
        // the LIMIT stops the scan) and probes the covering
        // `idx_event_log_session_id` only for rows actually returned. The gap
        // widens with install size, because the old plan's cost is independent
        // of `limit`.
        let countExpr = includeEventCount
            ? "(SELECT COUNT(*) FROM event_log e WHERE e.session_id = s.session_id)"
            : "0"
        var sql = """
            SELECT s.session_id, s.cwd, s.model, s.started_at, s.last_activity_at,
                   s.last_tool, s.status, s.git_branch, s.summary, s.pid, s.term_program,
                   s.project_root, s.term_session_id, s.transcript_title, s.last_output,
                   s.last_event_type, s.summary_at, \(countExpr) as event_count,
                   \(Self.subagentWorkingColumn)
            FROM sessions s
        """
        var conditions: [String] = []
        var params: [any Sendable] = []
        if let status {
            conditions.append("s.status = ?")
            params.append(status.rawValue)
        }
        if let sinceHours, sinceHours > 0 {
            // The hour count travels as a bound datetime modifier, not SQL text. The
            // column is stored in `datetime()` format (normalized by migration025), so
            // the bare comparison is correct AND sargable (uses idx_sessions_last_activity)
            // — do NOT wrap the column in datetime(), which would defeat the index.
            conditions.append("s.last_activity_at >= datetime('now', ?)")
            params.append("-\(sinceHours) hours")
        }
        if let project, !project.isEmpty {
            // `instr(...) > 0`, not `LIKE '%'||?||'%'`: `instr` is a plain substring
            // test, so a project name containing `%` or `_` can't turn into a
            // wildcard. Both sides are lowered, as the CLI's old local filter
            // (`cwd.lowercased().contains(project.lowercased())`) did, so
            // `--project MyApp` finds `…/myapp`.
            conditions.append("instr(lower(s.cwd), lower(?)) > 0")
            params.append(project)
        }
        if !conditions.isEmpty {
            sql += " WHERE " + conditions.joined(separator: " AND ")
        }
        sql += " ORDER BY s.last_activity_at DESC"
        if let limit {
            // Bound in SQL, not by trimming afterwards — the point is that the array
            // is never built past the ceiling in the first place.
            //
            // Non-nil is the whole test: `nil` is the documented "unbounded", so a
            // caller passing 0 must get zero rows, not every session on the machine.
            // Clamped rather than rejected because SQLite reads a negative LIMIT as
            // unbounded, which would turn a caller's arithmetic slip into the exact
            // unbounded scan this parameter exists to prevent.
            sql += " LIMIT ?"
            params.append(max(limit, 0))
        }

        var results: [SessionDTO] = []
        try query(sql, params: params) { row in
            results.append(SessionDTO(
                sessionId: string(row, 0),
                cwd: string(row, 1),
                model: string(row, 2),
                startedAt: string(row, 3),
                lastActivityAt: string(row, 4),
                lastTool: string(row, 5),
                status: string(row, 6),
                gitBranch: string(row, 7),
                summary: string(row, 8),
                pid: Int(int(row, 9)),
                termProgram: string(row, 10),
                projectRoot: string(row, 11),
                termSessionId: string(row, 12),
                transcriptTitle: string(row, 13),
                lastOutput: string(row, 14),
                lastEventType: string(row, 15),
                summaryAt: string(row, 16),
                eventCount: Int(int(row, 17)),
                subagentWorking: int(row, 18) != 0
            ))
        }
        return results
    }

    /// The account a session is billed to (`sessions.account_email`), or `""`
    /// when the session is unknown or predates account stamping. Callers fall
    /// back to `currentAccountEmail`. Re-entrancy-safe: `query` runs inline
    /// when already on the DB queue.
    public func accountEmailForSession(_ sessionId: String) -> String {
        var email = ""
        try? query("SELECT account_email FROM sessions WHERE session_id = ?",
                   params: [sessionId]) { row in
            email = string(row, 0)
        }
        return email
    }

    /// The auth method a session's `account_email` was resolved from
    /// (`token` | `oauth` | `unknown`), or `''` when unstamped/unknown.
    public func authMethodForSession(_ sessionId: String) -> String {
        var method = ""
        try? query("SELECT auth_method FROM sessions WHERE session_id = ?",
                   params: [sessionId]) { row in
            method = string(row, 0)
        }
        return method
    }

    /// One bounded batch of historical account/auth-method backfill (called by
    /// `AccountBackfillTask` off the startup path). Two actions, idempotent:
    ///   1. Any row with a non-empty `account_email` but no `auth_method` is
    ///      tagged `token` — the old write path only ever persisted TOKEN
    ///      emails, so a pre-migration non-empty account is necessarily a token.
    ///   2. Up to `limit` ENDED, still-empty, untried rows are recovered from
    ///      sibling tables (`session_metrics` → `rate_limit_snapshots` →
    ///      `transcript_turns`, cheapest first) and tagged `unknown`; an
    ///      unrecoverable row is tagged `unknown` with `account_email` left ''.
    ///      ENDED-only so live sessions keep self-healing via hooks.
    /// Returns the number of rows processed by action 2 (0 = backlog drained).
    @discardableResult
    public func backfillSessionAuthAttributionBatch(limit: Int = 200) -> Int {
        // Short-circuit once the backlog is fully drained: no new legacy rows can
        // appear (the write path always stamps auth_method; the importer stamps
        // 'unknown'), so re-scanning the table on every idle tick is pure waste.
        if ((try? setting(for: "account_backfill_done")) ?? nil) == "1" { return 0 }

        // Legacy rows with a non-empty account but no method: the old write path
        // only ever persisted TOKEN emails, so a pre-migration non-empty
        // account_email is necessarily a token account.
        try? execute(
            "UPDATE sessions SET auth_method = 'token' WHERE auth_method = '' AND account_email <> ''")

        var ids: [String] = []
        try? query("""
            SELECT session_id FROM sessions
            WHERE status = 'ended' AND auth_method = '' AND account_email = ''
            LIMIT ?
        """, params: [limit]) { row in
            ids.append(string(row, 0))
        }
        if ids.isEmpty {
            // Backlog drained (the token tag above has also run): never scan again.
            try? setSetting("account_backfill_done", "1")
            return 0
        }

        // Recover each account on the READ lane BEFORE opening the write
        // transaction, so the write lane is held only for the UPDATEs — not the
        // up-to-three sibling GROUP BYs per session.
        let recovered = ids.map { (sid: $0, account: recoverAccountFromSiblings($0)) }

        // One transaction per batch (far fewer fsyncs than per-row commits). Each
        // UPDATE is GUARDED on the still-ended-empty state, so a session that
        // resumed — a live hook re-stamped it active/attributed — between the
        // SELECT above and here is left untouched instead of clobbered with a
        // stale 'unknown'. A guarded keyed UPDATE only rolls back on a transient
        // deadline eject (never a persistent per-row failure), so return ids.count
        // regardless and let the scheduler retry the un-marked rows promptly.
        _ = try? transaction {
            for rec in recovered {
                try execute("""
                    UPDATE sessions SET account_email = ?, auth_method = 'unknown'
                    WHERE session_id = ? AND status = 'ended'
                      AND auth_method = '' AND account_email = ''
                """, params: [rec.account, rec.sid])
            }
        }
        return ids.count
    }

    /// The contemporaneously-captured account for a session, recovered from the
    /// cheapest sibling table that has one (`session_metrics` → `rate_limit_snapshots`
    /// → `transcript_turns`), taking the most frequent non-empty value within a
    /// source. `""` when no sibling recorded an account. Table names are fixed
    /// literals (no injection surface).
    private func recoverAccountFromSiblings(_ sessionId: String) -> String {
        for table in ["session_metrics", "rate_limit_snapshots", "transcript_turns"] {
            var best = ""
            try? query("""
                SELECT account_email, COUNT(*) AS c FROM \(table)
                WHERE session_id = ? AND account_email <> ''
                GROUP BY account_email ORDER BY c DESC, account_email LIMIT 1
            """, params: [sessionId]) { row in
                best = string(row, 0)
            }
            if !best.isEmpty { return best }
        }
        return ""
    }

    /// Resolves the account a session should be attributed to: the session's
    /// own stamped `account_email` if it has one, else the currently logged-in
    /// account. Callers that write multiple rows for the same session (e.g.
    /// the JSONL importer) should call this ONCE per session and reuse the
    /// result, rather than re-resolving per row — a per-row `currentEmail()`
    /// fallback can drift mid-import if the global account changes between
    /// rows, splitting one session's attribution across two accounts.
    public func resolvedAccountForSession(_ sessionId: String) -> String {
        let stampedAccount = accountEmailForSession(sessionId)
        return stampedAccount.isEmpty ? currentAccountEmail : stampedAccount
    }

    /// The `subagent_working` column `fetchSessions` and `fetchSession` both
    /// select, kept in one place so the list and the detail cannot disagree.
    ///
    /// Not the raw stamp: whether a subagent is in flight *now*. The freshness
    /// window is the daemon's judgement to make, not every client's, and sending a
    /// bare timestamp would have each of them re-derive it against its own clock.
    /// Measured over a week of real capture, 99.87% of the gaps between one working
    /// subagent's hooks are under five minutes (p99 = 67s), so a live subagent stays
    /// inside the window between tool calls while one that died without its
    /// terminal `SubagentStop` ages out of it.
    private static let subagentWorkingColumn = """
        (s.subagent_activity_at != ''
         AND s.subagent_activity_at >= datetime('now', '-5 minutes')) AS subagent_working
        """

    /// `includeEventCount: false` returns `eventCount = 0` without touching
    /// `event_log`. The count walks every index entry of the session — 148 ms for
    /// a 137k-event session on a 51 GB db — and the daemon's own callers (the
    /// summarizer, oversight) never read it; only the client-facing reads keep it.
    public func fetchSession(sessionId: String, includeEventCount: Bool = true) throws -> SessionDTO? {
        var result: SessionDTO?
        // Same correlated-subquery shape as `fetchSessions`, for the same reason.
        let countExpr = includeEventCount
            ? "(SELECT COUNT(*) FROM event_log e WHERE e.session_id = s.session_id)"
            : "0"
        try query("""
            SELECT s.session_id, s.cwd, s.model, s.started_at, s.last_activity_at,
                   s.last_tool, s.status, s.git_branch, s.summary, s.pid, s.term_program,
                   s.project_root, s.term_session_id, s.transcript_title, s.last_output,
                   s.last_event_type, s.summary_at, \(countExpr) as event_count,
                   \(Self.subagentWorkingColumn)
            FROM sessions s
            WHERE s.session_id = ?
        """, params: [sessionId]) { row in
            result = SessionDTO(
                sessionId: string(row, 0),
                cwd: string(row, 1),
                model: string(row, 2),
                startedAt: string(row, 3),
                lastActivityAt: string(row, 4),
                lastTool: string(row, 5),
                status: string(row, 6),
                gitBranch: string(row, 7),
                summary: string(row, 8),
                pid: Int(int(row, 9)),
                termProgram: string(row, 10),
                projectRoot: string(row, 11),
                termSessionId: string(row, 12),
                transcriptTitle: string(row, 13),
                lastOutput: string(row, 14),
                lastEventType: string(row, 15),
                summaryAt: string(row, 16),
                eventCount: Int(int(row, 17)),
                subagentWorking: int(row, 18) != 0
            )
        }
        return result
    }

    /// Sessions currently shown as alive (`active`/`stale`), so LivenessTask can
    /// end the ones whose `claude` process is gone. (`stale` is legacy — the
    /// process-based reconciliation only produces `active`/`ended`, but old rows
    /// may still carry it.)
    public func fetchActiveSessionsForLiveness()
        throws -> [(sessionId: String, status: String, cwd: String)] {
        var results: [(String, String, String)] = []
        try query("""
            SELECT session_id, status, cwd FROM sessions WHERE status IN ('active', 'stale')
        """) { row in
            results.append((string(row, 0), string(row, 1), string(row, 2)))
        }
        return results
    }

    /// The `limit` most-recently-active session IDs in a directory (any status).
    /// `LivenessTask` uses this to map the `count` live `claude` processes in a
    /// directory to their sessions — resurrecting one that already ended, since a
    /// session is alive whenever its process is, regardless of idle time. Uses
    /// `idx_sessions_cwd`; `datetime()` normalizes mixed timestamp formats so the
    /// ordering is chronological.
    public func recentSessionIds(inCwd cwd: String, limit: Int) throws -> [String] {
        guard limit > 0 else { return [] }
        var ids: [String] = []
        try query("""
            SELECT session_id FROM sessions
            WHERE cwd = ?
            ORDER BY datetime(last_activity_at) DESC
            LIMIT ?
        """, params: [cwd, limit]) { row in
            ids.append(string(row, 0))
        }
        return ids
    }

    /// Which of `ids` have a session row. Liveness asks before promoting a session a
    /// process names, so a process whose session was never ingested (the daemon's own
    /// headless runs are dropped at ingest) doesn't broadcast a status for a row that
    /// isn't there on every tick.
    public func existingSessionIds(_ ids: Set<String>) throws -> Set<String> {
        guard !ids.isEmpty else { return [] }
        var found: Set<String> = []
        try query("""
            SELECT session_id FROM sessions
            WHERE session_id IN (\(Array(repeating: "?", count: ids.count).joined(separator: ",")))
        """, params: ids.sorted()) { row in
            found.insert(string(row, 0))
        }
        return found
    }

    /// One candidate session for liveness matching: which session, where it thinks
    /// it is, and when it last did anything.
    public struct SessionCwdCandidate: Sendable {
        public let sessionId: String
        public let cwd: String
        public let lastActivityAt: String
    }

    /// The most-recently-active sessions **at or below** `directory`, newest first.
    ///
    /// A live `claude` reports the directory it was launched in; the session row
    /// records the *hook shell's* `$PWD`, which an agent moves whenever it runs a
    /// command from a subdirectory. Exact equality therefore stopped matching the
    /// two the moment a session `cd`-ed into a submodule — liveness ended the
    /// session, the next hook resurrected it, and the row blinked in and out of the
    /// Sessions window on alternate ticks.
    ///
    /// Returns more than `limit` on purpose, and returns each row's `cwd` so the
    /// caller can decide ownership: a directory's candidate set spans its whole
    /// subtree, and most of those sessions belong to a *deeper* live directory.
    /// Which ones is not knowable from one directory's query alone.
    ///
    /// `excluding` drops sessions already known to belong to a process. It is applied
    /// in the query rather than by the caller so those sessions can't use up the
    /// `LIMIT` and crowd out the candidates that are still unaccounted for.
    public func recentSessionCandidates(
        underCwd directory: String,
        limit: Int,
        excluding excluded: Set<String> = []
    ) throws -> [SessionCwdCandidate] {
        guard limit > 0, !directory.isEmpty else { return [] }
        // LIKE's wildcards are `%` and `_`; a project path containing either would
        // otherwise match directories it has nothing to do with.
        let escaped = directory
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
        let exclusion = excluded.isEmpty
            ? ""
            : "AND session_id NOT IN (\(Array(repeating: "?", count: excluded.count).joined(separator: ",")))"
        var params: [any Sendable] = [directory, escaped + "/%"]
        params.append(contentsOf: excluded.sorted())
        params.append(max(limit * 4, limit + 20))
        var out: [SessionCwdCandidate] = []
        try query("""
            -- `datetime()` normalises 'T'/'Z' ISO rows to 'YYYY-MM-DD HH:MM:SS' so the
            -- caller can rank candidates with a plain string compare.
            SELECT session_id, cwd, datetime(last_activity_at) FROM sessions
            WHERE (cwd = ? OR cwd LIKE ? ESCAPE '\\') \(exclusion)
            ORDER BY datetime(last_activity_at) DESC
            LIMIT ?
        """, params: params) { row in
            out.append(SessionCwdCandidate(
                sessionId: string(row, 0),
                cwd: string(row, 1),
                lastActivityAt: string(row, 2)
            ))
        }
        return out
    }

    // MARK: - Counts

    public func activeSessionCount() throws -> Int {
        var count = 0
        try query("SELECT COUNT(*) FROM sessions WHERE status = 'active'") { row in
            count = Int(int(row, 0))
        }
        return count
    }

    public func totalEventCount() throws -> Int {
        var count = 0
        try query("SELECT COUNT(*) FROM event_log") { row in
            count = Int(int(row, 0))
        }
        return count
    }

    // MARK: - Session stub (JSONL import)

    /// Create a minimal session row if one doesn't already exist. Used by
    /// the JSONL importer to backfill sessions the hook daemon never saw
    /// (e.g., sessions from before the daemon was installed).
    /// Returns `true` if a new row was created, `false` if one was already
    /// present. Never overwrites existing data.
    @discardableResult
    public func createSessionStubIfMissing(
        sessionId: String,
        cwd: String,
        model: String,
        startedAt: String,
        lastActivityAt: String,
        gitBranch: String = "",
        accountEmail: String,
        authMethod: String = "unknown"
    ) throws -> Bool {
        var created = false
        try write { _ in
            var existing = 0
            try query("SELECT COUNT(*) FROM sessions WHERE session_id = ?", params: [sessionId]) { row in
                existing = Int(int(row, 0))
            }
            if existing > 0 { return }

            try execute("""
                INSERT INTO sessions (
                    session_id, cwd, model, started_at, last_activity_at,
                    last_tool, status, git_branch, summary, pid, term_program,
                    account_email, auth_method
                ) VALUES (?, ?, ?, ?, COALESCE(datetime(?), ?), '', 'ended', ?, '', 0, '', ?, ?)
            """, params: [sessionId, cwd, model, startedAt,
                          lastActivityAt, lastActivityAt, gitBranch, accountEmail, authMethod])
            created = true
        }
        return created
    }
}
#endif
