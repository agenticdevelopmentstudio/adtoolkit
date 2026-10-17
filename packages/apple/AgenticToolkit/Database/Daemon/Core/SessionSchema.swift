// swiftlint:disable identifier_name line_length
#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

/// The session-event schema every session daemon shares: migrations 001-045, the
/// tables behind hook events, sessions, transcripts, settings and the daily
/// rollup. A daemon passes `SessionSchema.migrations` (then appends its own,
/// numbered from 46) and `SessionSchema.postMigration` to ``DaemonDatabase``.
///
/// Moved verbatim from Stenographer's `DatabaseManager`: the bodies are unchanged
/// apart from reaching the database through the `db` parameter.
public enum SessionSchema {

    /// Every shared migration, in the order it runs. Adding one is one line here.
    public static let migrations: [DaemonMigration] = [
        DaemonMigration(version: 1, run: migration001),
        DaemonMigration(version: 2, run: migration002),
        DaemonMigration(version: 3, run: migration003),
        DaemonMigration(version: 4, run: migration004),
        DaemonMigration(version: 5, run: migration005),
        DaemonMigration(version: 6, run: migration006),
        DaemonMigration(version: 7, run: migration007),
        DaemonMigration(version: 8, run: migration008),
        DaemonMigration(version: 9, run: migration009),
        DaemonMigration(version: 10, run: migration010),
        DaemonMigration(version: 11, run: migration011),
        DaemonMigration(version: 12, run: migration012),
        DaemonMigration(version: 13, run: migration013),
        DaemonMigration(version: 14, run: migration014),
        DaemonMigration(version: 15, run: migration015),
        DaemonMigration(version: 16, run: migration016),
        DaemonMigration(version: 17, run: migration017),
        DaemonMigration(version: 18, run: migration018),
        DaemonMigration(version: 19, run: migration019),
        DaemonMigration(version: 20, run: migration020),
        DaemonMigration(version: 21, run: migration021),
        DaemonMigration(version: 22, run: migration022),
        DaemonMigration(version: 23, run: migration023),
        DaemonMigration(version: 24, run: migration024),
        DaemonMigration(version: 25, run: migration025),
        DaemonMigration(version: 26, run: migration026),
        DaemonMigration(version: 27, run: migration027),
        DaemonMigration(version: 28, run: migration028),
        DaemonMigration(version: 29, run: migration029),
        DaemonMigration(version: 30, run: migration030),
        DaemonMigration(version: 31, run: migration031),
        DaemonMigration(version: 32, run: migration032),
        DaemonMigration(version: 33, run: migration033),
        DaemonMigration(version: 34, run: migration034),
        DaemonMigration(version: 35, run: migration035),
        DaemonMigration(version: 36, run: migration036),
        DaemonMigration(version: 37, run: migration037),
        DaemonMigration(version: 38, run: migration038),
        DaemonMigration(version: 39, run: migration039),
        DaemonMigration(version: 40, run: migration040),
        DaemonMigration(version: 41, run: migration041),
        DaemonMigration(version: 42, run: migration042),
        DaemonMigration(version: 43, run: migration043),
        DaemonMigration(version: 44, run: migration044),
        DaemonMigration(version: 45, run: migration045)
    ]

    /// Ensure steps run after every migration pass, outside the version gate (see
    /// ``DaemonDatabase``'s `postMigration`). Belt-and-braces: a DB that installed
    /// the un-pushed pre-rebase branch build recorded version 26 for the guard
    /// CHECK-widening (now migration027), which permanently skips the real
    /// migration026 above — including the guarded self-heal inside it. Cheap
    /// (one PRAGMA table_info per launch) and idempotent.
    public static let postMigration: [@Sendable (DaemonDatabase) throws -> Void] = [
        ensureSessionsAuthMethodColumn,
        ensureConversationIndex,
        // Only a speed-up, and the one ensure step that builds over millions of
        // rows: a full disk or an overrun deadline must not park the daemon.
        // Logged and retried on the next launch (`IF NOT EXISTS`).
        { db in
            do {
                try ensureTranscriptTurnTokenIndex(db)
            } catch {
                logger.error("transcript turn token index not built; Usage reads stay slower: \(error, privacy: .public)")
            }
        }
    ]

    /// How far back an ended session still needs a `last_output`: the Sessions
    /// window's longest "Show" range, seven days. A 24-hour reach left every ended
    /// session older than a day reading "No output yet." under the longer ranges.
    public static let lastOutputReachHours = 7 * 24

    /// The per-type event tables the daily rollup reads, each paired with the
    /// `daily_metric.metric` it produces and the dynamic column that becomes
    /// its `dimension`. `event` (from `event_log` / `event_type`) is handled
    /// separately because that table and column always exist. migration020
    /// indexes `timestamp` on exactly these tables; `recomputeDailyMetrics`
    /// guards each with `tableHasColumn` so a DB that never ingested the type
    /// (dimension column absent) simply produces no rows for that metric.
    public static let perTypeRollups: [(metric: String, table: String, column: String)] = [
        ("tool_use", "pre_tool_use_events", "tool_name"),
        ("tool_failure", "post_tool_use_failure_events", "tool_name"),
        ("subagent_run", "subagent_start_events", "agent_type"),
        ("notification", "notification_events", "notification_type"),
        ("compaction", "pre_compact_events", "trigger")
    ]

    private static func migration001(_ db: DaemonDatabase) throws {
        try db.migrationExecute("""
            CREATE TABLE sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL UNIQUE,
                cwd TEXT NOT NULL DEFAULT '',
                model TEXT NOT NULL DEFAULT '',
                started_at TEXT NOT NULL DEFAULT (datetime('now')),
                last_activity_at TEXT NOT NULL DEFAULT (datetime('now')),
                last_tool TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT 'active'
                    CHECK(status IN ('active','stale','ended')),
                git_branch TEXT NOT NULL DEFAULT '',
                summary TEXT NOT NULL DEFAULT '',
                pid INTEGER NOT NULL DEFAULT 0,
                term_program TEXT NOT NULL DEFAULT ''
            )
        """)
        try db.migrationExecute("CREATE INDEX idx_sessions_session_id ON sessions(session_id)")
        try db.migrationExecute("CREATE INDEX idx_sessions_status ON sessions(status)")
        try db.migrationExecute("CREATE INDEX idx_sessions_cwd ON sessions(cwd)")

        try db.migrationExecute("""
            CREATE TABLE events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                timestamp TEXT NOT NULL DEFAULT (datetime('now')),
                raw_json TEXT NOT NULL DEFAULT '{}',
                FOREIGN KEY (session_id) REFERENCES sessions(session_id)
            )
        """)
        try db.migrationExecute("CREATE INDEX idx_events_session_id ON events(session_id)")
        try db.migrationExecute("CREATE INDEX idx_events_event_type ON events(event_type)")
        try db.migrationExecute("CREATE INDEX idx_events_timestamp ON events(timestamp)")

        try db.migrationExecute("""
            CREATE TABLE settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
        """)
        try db.migrationExecute("""
            INSERT OR IGNORE INTO settings(key, value)
            VALUES ('retention_days', '7'), ('staleness_timeout_seconds', '60')
        """)
    }

    private static func migration002(_ db: DaemonDatabase) throws {
        try db.migrationExecute("""
            CREATE VIEW session_stats AS
            SELECT
                s.session_id,
                s.cwd,
                s.status,
                s.started_at,
                s.last_activity_at,
                s.model,
                s.last_tool,
                s.git_branch,
                s.summary,
                s.pid,
                s.term_program,
                COUNT(e.id) AS event_count,
                COUNT(DISTINCT e.event_type) AS unique_event_types,
                MAX(CASE WHEN e.event_type IN ('PreToolUse','PostToolUse')
                    THEN e.timestamp END) AS last_tool_use_at
            FROM sessions s
            LEFT JOIN events e ON s.session_id = e.session_id
            GROUP BY s.session_id
        """)
    }

    private static func migration003(_ db: DaemonDatabase) throws {
        // Drop old events-based objects
        try db.migrationExecute("DROP VIEW IF EXISTS session_stats")
        try db.migrationExecute("DROP TABLE IF EXISTS events")

        // Unified event timeline — replaces the old events table
        try db.migrationExecute("""
            CREATE TABLE event_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                timestamp TEXT NOT NULL DEFAULT (datetime('now')),
                cwd TEXT NOT NULL DEFAULT '',
                detail TEXT NOT NULL DEFAULT ''
            )
        """)
        try db.migrationExecute("CREATE INDEX idx_event_log_session_id ON event_log(session_id)")
        try db.migrationExecute("CREATE INDEX idx_event_log_event_type ON event_log(event_type)")
        try db.migrationExecute("CREATE INDEX idx_event_log_timestamp ON event_log(timestamp)")

        // Per-type tables for all known event types. Indexes are added by
        // migration013 (per-type session index) and migration014 (tool tables);
        // a fresh DB runs those as part of the migration replay.
        for eventType in HookEventType.allCases {
            try db.migrationExecute("""
                CREATE TABLE \(eventType.tableName) (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    event_log_id INTEGER NOT NULL REFERENCES event_log(id) ON DELETE CASCADE,
                    session_id TEXT NOT NULL DEFAULT '',
                    timestamp TEXT NOT NULL DEFAULT '',
                    cwd TEXT NOT NULL DEFAULT ''
                )
            """)
        }

        // Related tables for nested tool objects
        try db.migrationExecute("""
            CREATE TABLE tool_inputs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_log_id INTEGER NOT NULL REFERENCES event_log(id) ON DELETE CASCADE,
                event_type TEXT NOT NULL DEFAULT ''
            )
        """)
        try db.migrationExecute("""
            CREATE TABLE tool_responses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_log_id INTEGER NOT NULL REFERENCES event_log(id) ON DELETE CASCADE
            )
        """)

        // Recreate session_stats view using event_log
        try db.migrationExecute("""
            CREATE VIEW session_stats AS
            SELECT
                s.session_id,
                s.cwd,
                s.status,
                s.started_at,
                s.last_activity_at,
                s.model,
                s.last_tool,
                s.git_branch,
                s.summary,
                s.pid,
                s.term_program,
                COUNT(e.id) AS event_count,
                COUNT(DISTINCT e.event_type) AS unique_event_types,
                MAX(CASE WHEN e.event_type IN ('PreToolUse','PostToolUse')
                    THEN e.timestamp END) AS last_tool_use_at
            FROM sessions s
            LEFT JOIN event_log e ON s.session_id = e.session_id
            GROUP BY s.session_id
        """)
    }

    /// migration004 — support JSONL transcript imports.
    /// - Adds `event_log.message_id` (dedup key from assistant-turn
    ///   `message.id` in Claude's JSONL). Unique index on non-empty values.
    /// - Creates `session_metrics` table for per-session token / cost
    ///   rollups that hooks can't produce (tokens aren't in the hook
    ///   payload). Populated by the `steno import` command.
    private static func migration004(_ db: DaemonDatabase) throws {
        try db.migrationExecute("ALTER TABLE event_log ADD COLUMN message_id TEXT NOT NULL DEFAULT ''")
        try db.migrationExecute("""
            CREATE UNIQUE INDEX idx_event_log_message_id
            ON event_log(message_id)
            WHERE message_id != ''
        """)

        try db.migrationExecute("""
            CREATE TABLE session_metrics (
                session_id TEXT PRIMARY KEY REFERENCES sessions(session_id) ON DELETE CASCADE,
                total_input_tokens INTEGER NOT NULL DEFAULT 0,
                total_output_tokens INTEGER NOT NULL DEFAULT 0,
                cache_read_tokens INTEGER NOT NULL DEFAULT 0,
                cache_creation_tokens INTEGER NOT NULL DEFAULT 0,
                total_cost_usd REAL NOT NULL DEFAULT 0,
                turn_count INTEGER NOT NULL DEFAULT 0,
                model TEXT NOT NULL DEFAULT '',
                first_turn_at TEXT NOT NULL DEFAULT '',
                last_turn_at TEXT NOT NULL DEFAULT '',
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
    }

    /// migration005 — track which session created each branch/worktree so
    /// a Stop hook can block a session that leaves a merged-but-undeleted
    /// branch behind. Populated from branch-creating hook events in
    /// `ingestEvent`. `repo_path` + `branch_name` is the natural key: a
    /// branch name is only unique within a repo.
    private static func migration005(_ db: DaemonDatabase) throws {
        try db.migrationExecute("""
            CREATE TABLE session_branches (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                repo_path TEXT NOT NULL,
                branch_name TEXT NOT NULL,
                source TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                UNIQUE(repo_path, branch_name)
            )
        """)
        try db.migrationExecute("CREATE INDEX idx_session_branches_session_id ON session_branches(session_id)")
        try db.migrationExecute("CREATE INDEX idx_session_branches_repo_path ON session_branches(repo_path)")
    }

    /// migration006 — per-event process-context snapshot. The `stenographer
    /// hook` CLI subcommand captures a curated set of env vars and process
    /// attributes (claude.*, process.*, system.*, shell.*, session.*,
    /// terminal.*) and the daemon stores the JSON blob here. Historical
    /// rows keep the empty-string default so they don't appear in
    /// `WHERE context_json != ''` filters.
    private static func migration006(_ db: DaemonDatabase) throws {
        try db.migrationExecute("ALTER TABLE event_log ADD COLUMN context_json TEXT NOT NULL DEFAULT ''")
    }

    /// migration007 — consolidate stenographer-status-line data into stenographer.
    /// - `transcript_turns`: per-turn token rows from JSONL imports. Subsumes
    ///   the `turns` table in `~/.claude/usage.db`. Dedup on `message_id` for
    ///   assistant rows; composite `(session_id, timestamp, kind)` for user
    ///   rows that have no message id.
    /// - `rate_limit_snapshots`: time-series of 5h/7d/weekly/projected usage
    ///   percentages from StatusLine payloads. Subsumes `weekly_usage`.
    /// - `claude_versions`: first-seen full JSON blob plus the union of
    ///   dotted field paths observed across captures. Subsumes the
    ///   identically-named CSL table.
    /// - Extended columns on `session_metrics` for fields CSL persists today
    ///   (claude_version, project_dir, transcript_path, context_window_size,
    ///   api_duration_ms, lines_added, lines_removed, context_used_pct). All
    ///   default to safe zero/empty values so existing rows stay intact.
    private static func migration007(_ db: DaemonDatabase) throws {
        try db.migrationExecute("""
            CREATE TABLE transcript_turns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                kind TEXT NOT NULL CHECK(kind IN ('user','assistant')),
                model TEXT NOT NULL DEFAULT '',
                message_id TEXT NOT NULL DEFAULT '',
                input_tokens INTEGER NOT NULL DEFAULT 0,
                output_tokens INTEGER NOT NULL DEFAULT 0,
                cache_read_tokens INTEGER NOT NULL DEFAULT 0,
                cache_creation_tokens INTEGER NOT NULL DEFAULT 0,
                tool_name TEXT NOT NULL DEFAULT '',
                cwd TEXT NOT NULL DEFAULT '',
                event_log_id INTEGER REFERENCES event_log(id) ON DELETE SET NULL
            )
        """)
        try db.migrationExecute("CREATE INDEX idx_transcript_turns_session_id ON transcript_turns(session_id)")
        try db.migrationExecute("CREATE INDEX idx_transcript_turns_timestamp ON transcript_turns(timestamp)")
        try db.migrationExecute("CREATE INDEX idx_transcript_turns_model ON transcript_turns(model)")
        try db.migrationExecute("CREATE INDEX idx_transcript_turns_tool_name ON transcript_turns(tool_name)")
        try db.migrationExecute("""
            CREATE UNIQUE INDEX idx_transcript_turns_message_id
            ON transcript_turns(message_id)
            WHERE message_id != ''
        """)
        // NOTE: this predicate is tightened in migration008. Kept verbatim
        // here so on-disk schema replay matches the historical order.
        try db.migrationExecute("""
            CREATE UNIQUE INDEX idx_transcript_turns_user_dedup
            ON transcript_turns(session_id, timestamp, kind)
            WHERE message_id = ''
        """)

        try db.migrationExecute("""
            CREATE TABLE rate_limit_snapshots (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                session_id TEXT NOT NULL,
                week_start TEXT NOT NULL DEFAULT '',
                elapsed_hours INTEGER NOT NULL DEFAULT 0,
                elapsed_day REAL NOT NULL DEFAULT 0,
                weekly_pct REAL NOT NULL DEFAULT 0,
                daily_avg_pct REAL NOT NULL DEFAULT 0,
                five_hour_pct REAL NOT NULL DEFAULT 0,
                five_hour_resets_at INTEGER NOT NULL DEFAULT 0,
                seven_day_resets_at INTEGER NOT NULL DEFAULT 0,
                projected_pct REAL NOT NULL DEFAULT 0
            )
        """)
        try db.migrationExecute("CREATE INDEX idx_rate_limit_snapshots_session_id ON rate_limit_snapshots(session_id)")
        try db.migrationExecute("CREATE INDEX idx_rate_limit_snapshots_timestamp ON rate_limit_snapshots(timestamp)")
        try db.migrationExecute(
            "CREATE INDEX idx_rate_limit_snapshots_five_hour_resets ON rate_limit_snapshots(five_hour_resets_at)"
        )
        try db.migrationExecute(
            "CREATE INDEX idx_rate_limit_snapshots_seven_day_resets ON rate_limit_snapshots(seven_day_resets_at)"
        )

        try db.migrationExecute("""
            CREATE TABLE claude_versions (
                claude_version TEXT PRIMARY KEY,
                fields TEXT NOT NULL,
                fields_count INTEGER NOT NULL DEFAULT 0,
                first_seen TEXT NOT NULL DEFAULT (datetime('now')),
                field_paths TEXT NOT NULL DEFAULT '[]'
            )
        """)

        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN claude_version TEXT NOT NULL DEFAULT ''")
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN project_dir TEXT NOT NULL DEFAULT ''")
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN transcript_path TEXT NOT NULL DEFAULT ''")
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN context_window_size INTEGER NOT NULL DEFAULT 0")
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN api_duration_ms INTEGER NOT NULL DEFAULT 0")
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN lines_added INTEGER NOT NULL DEFAULT 0")
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN lines_removed INTEGER NOT NULL DEFAULT 0")
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN context_used_pct INTEGER NOT NULL DEFAULT 0")
    }

    /// migration008 — tighten `idx_transcript_turns_user_dedup` to user
    /// turns only. The original predicate (`WHERE message_id = ''`) was
    /// over-broad: a single assistant message that invokes multiple tools
    /// emits one JSONL record per `tool_use` block, all sharing the same
    /// `(session_id, timestamp)` and (frequently) no usage-block `id`. The
    /// previous unique key collapsed those legitimate rows on insert,
    /// causing `transcript_turns` to undercount assistant turns relative
    /// to CSL's `~/.claude/usage.db`. Restricting the predicate to
    /// `kind = 'user'` keeps user-turn idempotency (user JSONL records
    /// never carry a `message_id`) while letting assistant tool-use rows
    /// through unrestricted — matching CSL's semantics, where only a
    /// non-empty `message_id` is constrained.
    private static func migration008(_ db: DaemonDatabase) throws {
        try db.migrationExecute("DROP INDEX IF EXISTS idx_transcript_turns_user_dedup")
        try db.migrationExecute("""
            CREATE UNIQUE INDEX idx_transcript_turns_user_dedup
            ON transcript_turns(session_id, timestamp)
            WHERE kind = 'user' AND message_id = ''
        """)
    }

    /// migration009 — add a dedup key for empty-`message_id` assistant turns.
    /// migration008 removed any uniqueness constraint on them, which fixed
    /// the multi-tool-use over-collapse but left re-imports
    /// (CSLRefreshTask, manual `migrate-csl`) duplicating every empty-mid
    /// row each pass. Empirically: a single overnight refresh inflated
    /// `transcript_turns` ~10× by re-inserting the ~366k empty-mid
    /// `~/.claude/usage.db` rows on every 30-second tick.
    ///
    /// New predicate dedups on `(session_id, timestamp, tool_name)`. This
    /// preserves the migration008 win — sibling rows from a multi-tool-use
    /// assistant message differ in `tool_name` and stay distinct — while
    /// idempotently catching CSL re-imports of the same row. The one
    /// remaining false-collapse is the rare parallel-same-tool case
    /// (two `Bash` calls in one message), which would already collide in
    /// CSL's own dedup model.
    ///
    /// Cleanup step before adding the index: collapse any duplicates that
    /// already snuck in under the unconstrained migration008 state, by
    /// keeping the lowest-`id` row per `(session_id, timestamp, tool_name)`
    /// for empty-mid assistant rows. Without this DELETE the new unique
    /// constraint would fail to install on any DB that was running
    /// CSLRefreshTask while migration008 was the head schema.
    private static func migration009(_ db: DaemonDatabase) throws {
        try db.migrationExecute("""
            DELETE FROM transcript_turns
            WHERE kind = 'assistant' AND message_id = ''
              AND id NOT IN (
                  SELECT MIN(id) FROM transcript_turns
                  WHERE kind = 'assistant' AND message_id = ''
                  GROUP BY session_id, timestamp, tool_name
              )
        """)
        try db.migrationExecute("""
            CREATE UNIQUE INDEX idx_transcript_turns_assistant_empty_mid
            ON transcript_turns(session_id, timestamp, tool_name)
            WHERE kind = 'assistant' AND message_id = ''
        """)
    }

    /// migration010 — account attribution. Stamps each usage row with the
    /// Claude account that owns it so usage stays separable when the user
    /// switches accounts. Adds `account_email` to the three usage tables and
    /// backfills existing rows to the only account they could have come from.
    ///
    /// Column default is `''` (not the backfill value) so any future insert
    /// that forgets to stamp surfaces as an empty "unknown account" sentinel
    /// instead of silently mis-attributing the row. The backfill is a one-time
    /// historical fact, applied with an explicit UPDATE. New rows are stamped
    /// from `~/.claude.json` at insert time (see AccountResolver).
    private static func migration010(_ db: DaemonDatabase) throws {
        try db.migrationExecute("ALTER TABLE session_metrics ADD COLUMN account_email TEXT NOT NULL DEFAULT ''")
        try db.migrationExecute("ALTER TABLE transcript_turns ADD COLUMN account_email TEXT NOT NULL DEFAULT ''")
        try db.migrationExecute("ALTER TABLE rate_limit_snapshots ADD COLUMN account_email TEXT NOT NULL DEFAULT ''")

        try db.migrationExecute(
            "UPDATE session_metrics SET account_email = 'mike@mikefullerton.com' WHERE account_email = ''"
        )
        try db.migrationExecute(
            "UPDATE transcript_turns SET account_email = 'mike@mikefullerton.com' WHERE account_email = ''"
        )
        try db.migrationExecute(
            "UPDATE rate_limit_snapshots SET account_email = 'mike@mikefullerton.com' WHERE account_email = ''"
        )
    }

    /// migration011 — re-attribute usage rows the CSL importer left unstamped.
    /// migration010 stamped every then-untagged usage row a single account
    /// (`mike@mikefullerton.com`), but the importer kept producing
    /// `account_email = ''` rows, and the user runs more than one Claude
    /// account, so a single backfill account is wrong once they switch.
    ///
    /// Attribute each still-untagged row to whichever account was *live* at its
    /// timestamp, inferred from the rows that DID get stamped at ingest time:
    /// the account of the most recent stamped `transcript_turns` row at or
    /// before it, else the earliest stamped row after it. This is generic —
    /// it derives the account-switch timeline from the data itself rather than
    /// hardcoding a cutover instant or account identities, so it stays correct
    /// across any number of switches and on any install. `COALESCE(…, account_email)`
    /// leaves the row untouched (still `''`) when no stamped row exists to
    /// learn from, avoiding a NOT NULL violation on a freshly-seeded DB.
    ///
    /// `transcript_turns` is the authority for "who was active when" (live hooks
    /// stamp it); `rate_limit_snapshots` borrows that timeline since its own
    /// rows were never stamped. Going forward `migrateCSL` stamps at import
    /// time, so no new untagged usage rows are created.
    private static func migration011(_ db: DaemonDatabase) throws {
        let activeAccountAt = { (timeColumn: String) in """
            COALESCE(
                (SELECT a.account_email FROM transcript_turns a
                 WHERE a.account_email != '' AND a.timestamp <= \(timeColumn)
                 ORDER BY a.timestamp DESC LIMIT 1),
                (SELECT a.account_email FROM transcript_turns a
                 WHERE a.account_email != '' AND a.timestamp > \(timeColumn)
                 ORDER BY a.timestamp ASC LIMIT 1),
                account_email
            )
            """
        }
        try db.migrationExecute("""
            UPDATE transcript_turns
            SET account_email = \(activeAccountAt("transcript_turns.timestamp"))
            WHERE account_email = ''
            """)
        try db.migrationExecute("""
            UPDATE rate_limit_snapshots
            SET account_email = \(activeAccountAt("rate_limit_snapshots.timestamp"))
            WHERE account_email = ''
            """)
    }

    /// migration012 — index `account_email` so the account-scoped usage reads
    /// (`turnAggregates` / `activeHours` / `latestRateLimitSnapshot`, all
    /// filtered by the logged-in account) seek instead of scanning the full
    /// table. The composite `(account_email, timestamp)` form also serves the
    /// time-window range the usage queries apply on top of the account filter.
    private static func migration012(_ db: DaemonDatabase) throws {
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_transcript_turns_account_time "
            + "ON transcript_turns(account_email, timestamp)"
        )
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_rate_limit_snapshots_account_time "
            + "ON rate_limit_snapshots(account_email, timestamp)"
        )
    }

    /// Every Usage recompute sums tokens over time windows — today, this week,
    /// and on a cold memo the three weeks behind it — with no account filter.
    /// `(timestamp, session_id)` finds the rows but then fetches each one from
    /// the table, and those rows are scattered through a file of tens of GB: after
    /// a restart with a cold page cache, the first recompute spent ~8 s of one
    /// thread in `pread` for 700k turns. Carrying the summed columns in the
    /// index answers the same query from the index alone, read in order — about
    /// a fifth of the pages, and none of them random.
    ///
    /// Built once (a few seconds over ~3M turns); `IF NOT EXISTS` after that.
    static func ensureTranscriptTurnTokenIndex(_ db: DaemonDatabase) throws {
        let columns = ["timestamp", "model", "input_tokens", "output_tokens", "cache_read_tokens",
                       "cache_creation_tokens", "cache_creation_1h_tokens"]
        // A pre-migration fixture may carry only some of them.
        guard db.tableExists("transcript_turns"),
              columns.allSatisfy({ db.tableHasColumn("transcript_turns", $0) })
        else { return }
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_transcript_turns_time_tokens ON transcript_turns("
            + columns.joined(separator: ", ") + ")"
        )
    }

    /// migration013 — index every per-type event table (created in migration003) on
    /// `(session_id, event_log_id)`. They shipped with no indexes, so session-scoped
    /// reads full-scanned them. `computePostToolDurationMs` ran
    /// `WHERE session_id = ? AND tool_use_id = ? ORDER BY event_log_id DESC LIMIT 1`
    /// against `pre_tool_use_events` on every PostToolUse ingest — a full SCAN plus a
    /// temp-B-tree sort that, on a multi-hundred-thousand-row table, pegged the serial
    /// database queue and starved the HTTP server. The composite index turns that into a
    /// per-session index SEARCH whose `event_log_id` ordering needs no temp B-tree, and
    /// also serves the event-detail read path (`fetchEventDetail`) for every event type.
    /// One-time on upgrade; logged and wrapped in a single transaction (one commit) so a
    /// large DB's index build is atomic and not 29 separate fsyncs.
    private static func migration013(_ db: DaemonDatabase) throws {
        logger.info("migration013: building per-type session indexes…")
        // One real transaction (one commit) so a large DB's index build is atomic
        // and not 29 separate fsyncs; GRDB rolls back automatically if any fail.
        try db.migrationTransaction {
            for eventType in HookEventType.allCases {
                try db.migrationExecute("CREATE INDEX IF NOT EXISTS idx_\(eventType.tableName)_session "
                    + "ON \(eventType.tableName)(session_id, event_log_id)")
            }
        }
        logger.info("migration013: per-type session indexes ready")
    }

    /// migration014 — index `tool_inputs` / `tool_responses` on `event_log_id`.
    /// `fetchEventDetail` looks these two tables up by `event_log_id` alone (neither has
    /// a `session_id` column), which otherwise full-scans them on every `GET /events/:id`.
    /// Separate from migration013 because some installs already recorded schema v13
    /// before these indexes existed. One-time on upgrade; logged and transactional.
    private static func migration014(_ db: DaemonDatabase) throws {
        logger.info("migration014: building tool_inputs/tool_responses indexes…")
        try db.migrationTransaction {
            for table in ["tool_inputs", "tool_responses"] {
                try db.migrationExecute("CREATE INDEX IF NOT EXISTS idx_\(table)_event_log_id "
                    + "ON \(table)(event_log_id)")
            }
        }
        logger.info("migration014: tool table indexes ready")
    }

    /// Adds `project_root` — the top-level (non-submodule) git project root for a
    /// session's cwd, resolved by `SessionEnricher`. Empty until enriched (or when
    /// cwd isn't a git working tree). Lets the Sessions window group by project.
    private static func migration015(_ db: DaemonDatabase) throws {
        // Idempotent: ALTER ADD COLUMN isn't atomic with the schema_migrations
        // insert, so an unclean shutdown between them would re-run this and throw
        // "duplicate column name", wedging startup (cf. migration019).
        if !db.tableHasColumn("sessions", "project_root") {
            try db.migrationExecute("ALTER TABLE sessions ADD COLUMN project_root TEXT NOT NULL DEFAULT ''")
        }
        logger.info("migration015: sessions.project_root column ready")
    }

    /// Resets `project_root` so `SessionEnricher` recomputes it. migration015's
    /// first pass resolved a linked worktree to its own root; project_root now
    /// collapses worktrees to the repo's main working tree, so the stored values
    /// are recomputed by the startup backfill (live sessions first).
    private static func migration016(_ db: DaemonDatabase) throws {
        try db.migrationExecute("UPDATE sessions SET project_root = ''")
        logger.info("migration016: project_root reset for recompute")
    }

    /// Records which version of the project_root algorithm last computed each row.
    /// `SessionEnricher` recomputes only rows below the current version and then
    /// stamps it (even for non-git sessions, which store ''), so the backfill stops
    /// re-running git on already-resolved rows every startup, and a future algorithm
    /// change is a constant bump rather than another blanket-reset migration. New
    /// (default 0) rows are below any real version, so they enrich once.
    private static func migration017(_ db: DaemonDatabase) throws {
        // Idempotent ADD COLUMN — see migration015.
        if !db.tableHasColumn("sessions", "project_root_version") {
            try db.migrationExecute("ALTER TABLE sessions ADD COLUMN project_root_version INTEGER NOT NULL DEFAULT 0")
        }
        logger.info("migration017: sessions.project_root_version column ready")
    }

    /// migration018 — persistent log of ingestion failures, mirroring the
    /// on-disk `errors/*.meta.json` sidecars so recurring failures can be
    /// tracked and fixed (and survive a `Clear`). Keyed by the quarantined
    /// filename; `status` walks failing → exhausted → recovered/cleared.
    private static func migration018(_ db: DaemonDatabase) throws {
        // IF NOT EXISTS so an unclean shutdown between the DDL and the
        // schema_migrations insert self-heals instead of throwing "table already
        // exists" on the next startup (cf. migration019/020).
        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS ingestion_errors (
                filename TEXT PRIMARY KEY,
                event_type TEXT NOT NULL DEFAULT '',
                session_id TEXT NOT NULL DEFAULT '',
                reason TEXT NOT NULL DEFAULT '',
                sqlite_code INTEGER,
                quarantined_at TEXT NOT NULL DEFAULT '',
                retry_count INTEGER NOT NULL DEFAULT 0,
                last_retried_at TEXT,
                status TEXT NOT NULL DEFAULT 'failing',
                resolved_at TEXT,
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        try db.migrationExecute("CREATE INDEX IF NOT EXISTS idx_ingestion_errors_status ON ingestion_errors(status)")
        logger.info("migration018: ingestion_errors table ready")
    }

    /// migration019 — `term_session_id` (the terminal's TERM_SESSION_ID, e.g.
    /// iTerm's "w0t1p0:UUID") so the app can jump to the exact tab/pane on click.
    ///
    /// Idempotent: `ALTER TABLE ADD COLUMN` is not transactional with the
    /// follow-up `INSERT INTO schema_migrations`, so an unclean shutdown between
    /// them leaves the column present but the version unrecorded — re-running
    /// then fails with "duplicate column name" and wedges every subsequent
    /// startup. Guarding the ALTER lets the daemon self-heal: skip the add,
    /// record the version, move on.
    private static func migration019(_ db: DaemonDatabase) throws {
        if !db.tableHasColumn("sessions", "term_session_id") {
            try db.migrationExecute("ALTER TABLE sessions ADD COLUMN term_session_id TEXT NOT NULL DEFAULT ''")
        }
        logger.info("migration019: sessions.term_session_id column ready")
    }

    /// migration020 — `daily_metric`: a permanent, additive daily-rollup fact
    /// table that survives data retention. `RollupTask` aggregates `event_log`
    /// and the per-type event tables into one row per (day, metric, dimension),
    /// so analytics (events/day, tool/subagent/notification/compaction
    /// breakdowns) persist after the raw rows are deleted. Counts and
    /// `value_sum` are additive — averages are computed at read time as
    /// `value_sum / count`. `value_sum` is reserved (0 in this phase) for
    /// future additive measures like tool durations.
    private static func migration020(_ db: DaemonDatabase) throws {
        logger.info("migration020: creating daily_metric + source timestamp indexes…")
        try db.migrationTransaction {
            // IF NOT EXISTS throughout so an unclean shutdown mid-migration
            // (or a re-run) self-heals rather than failing on "table/index
            // already exists" and wedging startup.
            try db.migrationExecute("""
                -- day: 'YYYY-MM-DD' UTC. metric: event|tool_use|tool_failure|
                -- subagent_run|notification|compaction. dimension: the breakdown
                -- value (event_type / tool_name / agent_type / notification_type
                -- / trigger). count + value_sum are additive (avg = sum/count).
                CREATE TABLE IF NOT EXISTS daily_metric (
                    day        TEXT NOT NULL,
                    metric     TEXT NOT NULL,
                    dimension  TEXT NOT NULL DEFAULT '',
                    count      INTEGER NOT NULL DEFAULT 0,
                    value_sum  REAL NOT NULL DEFAULT 0,
                    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                    PRIMARY KEY (day, metric, dimension)
                )
            """)
            try db.migrationExecute("CREATE INDEX IF NOT EXISTS idx_daily_metric_metric_day ON daily_metric(metric, day)")
            // Per-day rollup filters each source table by `timestamp`. event_log
            // already has a timestamp index; the per-type tables are only indexed
            // on (session_id, event_log_id), so without these a daily recompute
            // full-scans hundreds-of-thousands-of-rows tables and wedges the
            // write lane (cf. migration013). Index only the tables the
            // rollup reads. Guard on table existence: per-type tables are created
            // lazily on first ingest (DynamicSchema), so a never-seen event type
            // has no table yet — CREATE INDEX would throw and wedge startup.
            for source in Self.perTypeRollups where db.tableExists(source.table) {
                try db.migrationExecute("CREATE INDEX IF NOT EXISTS idx_\(source.table)_timestamp "
                    + "ON \(source.table)(timestamp)")
            }
        }
        logger.info("migration020: daily_metric rollup table ready")
    }

    /// migration021 — `sessions.account_email`: the account a session is
    /// billed to, resolved once from the session's own token at the hook edge
    /// and read back by every usage-table write. Guarded ADD COLUMN
    /// (not atomic with the schema_migrations insert) so an unclean shutdown
    /// self-heals instead of wedging startup on "duplicate column".
    private static func migration021(_ db: DaemonDatabase) throws {
        if !db.tableHasColumn("sessions", "account_email") {
            try db.migrationExecute("ALTER TABLE sessions ADD COLUMN account_email TEXT NOT NULL DEFAULT ''")
        }
        logger.info("migration021: sessions.account_email column ready")
    }

    /// migration022 — `oversight_findings`: the generic store every `SessionObserver`
    /// writes to. One row per (session, observer, kind); an observer re-detecting the
    /// same condition upserts (refreshing severity/reason and reviving a `stale` row),
    /// so the table tracks *current* findings rather than an append-only history.
    /// `IF NOT EXISTS` throughout so an unclean shutdown mid-migration self-heals.
    private static func migration022(_ db: DaemonDatabase) throws {
        logger.info("migration022: creating oversight_findings…")
        try db.migrationTransaction {
            try db.migrationExecute("""
                CREATE TABLE IF NOT EXISTS oversight_findings (
                    id         INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id TEXT NOT NULL,
                    observer   TEXT NOT NULL,
                    kind       TEXT NOT NULL,
                    severity   INTEGER NOT NULL DEFAULT 0,
                    status     TEXT NOT NULL DEFAULT 'pending'
                        CHECK(status IN ('pending','acted','dismissed','stale')),
                    source     TEXT NOT NULL DEFAULT 'rule',
                    model      TEXT NOT NULL DEFAULT '',
                    reason     TEXT NOT NULL DEFAULT '',
                    detail     TEXT NOT NULL DEFAULT '',
                    created_at TEXT NOT NULL DEFAULT (datetime('now')),
                    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
                    UNIQUE(session_id, observer, kind)
                )
            """)
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_oversight_findings_status ON oversight_findings(status)"
            )
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_oversight_findings_session ON oversight_findings(session_id)"
            )
        }
        logger.info("migration022: oversight_findings table ready")
    }

    /// migration023 — `ai_interactions`: one row per LLM call the daemon made (summaries,
    /// oversight), logged at the `DaemonAIChat` chokepoint. Bounded by pruning to the
    /// newest `maxAIInteractionRows` on every insert (RetentionTask is opt-in/off, so
    /// insert-time pruning is the working bound). `IF NOT EXISTS` throughout so an
    /// unclean shutdown mid-migration self-heals.
    private static func migration023(_ db: DaemonDatabase) throws {
        logger.info("migration023: creating ai_interactions…")
        try db.migrationTransaction {
            try db.migrationExecute("""
                CREATE TABLE IF NOT EXISTS ai_interactions (
                    id            INTEGER PRIMARY KEY AUTOINCREMENT,
                    feature       TEXT NOT NULL,
                    session_id    TEXT NOT NULL DEFAULT '',
                    provider_kind TEXT NOT NULL DEFAULT 'cli'
                        CHECK(provider_kind IN ('plugin','cli')),
                    config_name   TEXT NOT NULL DEFAULT '',
                    model         TEXT NOT NULL DEFAULT '',
                    system_prompt TEXT NOT NULL DEFAULT '',
                    user_prompt   TEXT NOT NULL DEFAULT '',
                    response      TEXT NOT NULL DEFAULT '',
                    duration_ms   INTEGER NOT NULL DEFAULT 0,
                    outcome       TEXT NOT NULL DEFAULT 'ok'
                        CHECK(outcome IN ('ok','error')),
                    error         TEXT NOT NULL DEFAULT '',
                    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_ai_interactions_created ON ai_interactions(created_at)"
            )
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_ai_interactions_session ON ai_interactions(session_id)"
            )
        }
        logger.info("migration023: ai_interactions table ready")
    }

    /// migration024 — `oversight_scripts`: the trigger→response scripts oversight
    /// runs (one `ScriptObserver` per enabled row). `definition` holds the whole
    /// `OversightScript` as JSON (plain camelCase, internal storage); the mirrored
    /// columns exist for cheap listing/filtering. `user_modified` marks rows the
    /// shipped-script upgrader must never overwrite. `IF NOT EXISTS` so an unclean
    /// shutdown mid-migration self-heals.
    private static func migration024(_ db: DaemonDatabase) throws {
        logger.info("migration024: creating oversight_scripts…")
        try db.migrationTransaction {
            try db.migrationExecute("""
                CREATE TABLE IF NOT EXISTS oversight_scripts (
                    id            TEXT PRIMARY KEY,
                    name          TEXT NOT NULL,
                    enabled       INTEGER NOT NULL DEFAULT 1,
                    built_in      INTEGER NOT NULL DEFAULT 0,
                    user_modified INTEGER NOT NULL DEFAULT 0,
                    version       INTEGER NOT NULL DEFAULT 1,
                    definition    TEXT NOT NULL,
                    created_at    TEXT NOT NULL DEFAULT (datetime('now')),
                    updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
        }
        logger.info("migration024: oversight_scripts table ready")
    }

    /// migration025 — normalize `sessions.last_activity_at` to SQLite's `datetime()`
    /// format and index it. Live ingest already writes `datetime(...)` (space-
    /// separated, UTC), but imported history stored raw ISO8601 ("…T…Z"), leaving the
    /// column mixed-format. That broke the `MAX(existing, event)` string comparison on
    /// upsert (ISO8601's 'T' sorts above the space form, so a stale imported value can
    /// beat a newer live event) and forced every recency query to wrap the column in
    /// `datetime()` — non-sargable. Normalize once (unparseable rows left untouched),
    /// then the bare column compares correctly and the index can serve filter + order.
    private static func migration025(_ db: DaemonDatabase) throws {
        // Defensive: only normalize if the column exists. A DB that never created
        // `sessions` (e.g. a synthetic legacy migration fixture) skips it — a no-op
        // there, since later ingest writes datetime() format anyway.
        guard db.tableHasColumn("sessions", "last_activity_at") else {
            logger.info("migration025: no sessions.last_activity_at column — skipping normalization")
            return
        }
        logger.info("migration025: normalizing sessions.last_activity_at…")
        try db.migrationTransaction {
            try db.migrationExecute("""
                UPDATE sessions SET last_activity_at = datetime(last_activity_at)
                WHERE last_activity_at IS NOT NULL AND last_activity_at <> datetime(last_activity_at)
            """)
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_sessions_last_activity ON sessions(last_activity_at)"
            )
        }
        logger.info("migration025: sessions.last_activity_at normalized + indexed")
    }

    /// migration026 — `sessions.auth_method`: how a session's `account_email`
    /// was resolved (`token` | `oauth` | `unknown`; `''` = unresolved). Persisting
    /// the oauth login is now safe because a `token` stamp outranks an `oauth`
    /// stamp in the upsert, so an early wrong-oauth guess self-heals instead of
    /// freezing. Guarded ADD COLUMN so an unclean shutdown self-heals.
    private static func migration026(_ db: DaemonDatabase) throws {
        try ensureSessionsAuthMethodColumn(db)
        logger.info("migration026: sessions.auth_method column ready")
    }

    /// The guarded `sessions.auth_method` ADD COLUMN — shared by `migration026`
    /// and the post-runner self-heal in `runMigrations` so the two can never
    /// drift. Idempotent; a no-op when `sessions` doesn't exist yet (synthetic
    /// legacy fixtures — mirrors migration025's defensive guard).
    static func ensureSessionsAuthMethodColumn(_ db: DaemonDatabase) throws {
        guard db.tableExists("sessions"), !db.tableHasColumn("sessions", "auth_method") else { return }
        try db.migrationExecute("ALTER TABLE sessions ADD COLUMN auth_method TEXT NOT NULL DEFAULT ''")
    }

    /// migration027 — widens `ai_interactions.outcome`'s CHECK to admit the local-model
    /// guard's refusal outcomes (`guard_blocked`, `guard_deferred`), recorded by the
    /// `DaemonAIChat.complete(feature:)` chokepoint when `LocalInferenceGuard` refuses a
    /// request; without this the insert violates the original `CHECK(outcome IN
    /// ('ok','error'))` and the refusal is silently dropped from the log (recording only
    /// the "Failed to record AI interaction" fallback, never the guard row). SQLite has
    /// no `ALTER TABLE ... DROP/ADD CONSTRAINT`, so the table is recreated with the
    /// widened CHECK and its rows copied over. Rename→create→copy→drop reproduces the
    /// same table+data even if re-run against an already-migrated table, so an unclean
    /// shutdown between this migration's commit and its `schema_migrations` marker
    /// self-heals on the next launch — no separate "already migrated" check needed.
    private static func migration027(_ db: DaemonDatabase) throws {
        logger.info("migration027: widening ai_interactions.outcome CHECK for guard outcomes…")
        try db.migrationTransaction {
            try db.migrationExecute("ALTER TABLE ai_interactions RENAME TO ai_interactions_pre027")
            try db.migrationExecute("""
                CREATE TABLE IF NOT EXISTS ai_interactions (
                    id            INTEGER PRIMARY KEY AUTOINCREMENT,
                    feature       TEXT NOT NULL,
                    session_id    TEXT NOT NULL DEFAULT '',
                    provider_kind TEXT NOT NULL DEFAULT 'cli'
                        CHECK(provider_kind IN ('plugin','cli')),
                    config_name   TEXT NOT NULL DEFAULT '',
                    model         TEXT NOT NULL DEFAULT '',
                    system_prompt TEXT NOT NULL DEFAULT '',
                    user_prompt   TEXT NOT NULL DEFAULT '',
                    response      TEXT NOT NULL DEFAULT '',
                    duration_ms   INTEGER NOT NULL DEFAULT 0,
                    outcome       TEXT NOT NULL DEFAULT 'ok'
                        CHECK(outcome IN ('ok','error','guard_blocked','guard_deferred')),
                    error         TEXT NOT NULL DEFAULT '',
                    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
            try db.migrationExecute("""
                INSERT INTO ai_interactions
                    (id, feature, session_id, provider_kind, config_name, model,
                     system_prompt, user_prompt, response, duration_ms, outcome, error, created_at)
                SELECT id, feature, session_id, provider_kind, config_name, model,
                       system_prompt, user_prompt, response, duration_ms, outcome, error, created_at
                FROM ai_interactions_pre027
            """)
            // AUTOINCREMENT high-water: the RENAME carried the table's
            // sqlite_sequence row to the _pre027 name, and the copy only recreates
            // one when rows exist — a table empty at migration time would restart
            // ids at 1, re-using ids of already-pruned rows. Read the old mark
            // before the drop discards it, and restore it below when the copy left
            // none (or a lower one).
            var preSeq: Int?
            try db.query("SELECT seq FROM sqlite_sequence WHERE name = 'ai_interactions_pre027'") { row in
                preSeq = row[0]
            }
            try db.migrationExecute("DROP TABLE ai_interactions_pre027")
            if let preSeq {
                try db.migrationExecute(
                    "UPDATE sqlite_sequence SET seq = ? WHERE name = 'ai_interactions' AND seq < ?",
                    params: [preSeq, preSeq]
                )
                try db.migrationExecute("""
                    INSERT INTO sqlite_sequence(name, seq)
                    SELECT 'ai_interactions', ?
                    WHERE NOT EXISTS (SELECT 1 FROM sqlite_sequence WHERE name = 'ai_interactions')
                """, params: [preSeq])
            }
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_ai_interactions_created ON ai_interactions(created_at)"
            )
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_ai_interactions_session ON ai_interactions(session_id)"
            )
        }
        logger.info("migration027: ai_interactions.outcome CHECK widened")
    }

    /// migration028 — creates `transcript_lines`, the verbatim per-line store for
    /// full session transcripts, and clears the `jsonl_import_last_run_at` cursor so
    /// the next `JSONLImportTask` re-drains all of ~/.claude/projects once and
    /// backfills every existing line. The existing event_log / transcript_turns dedup
    /// indexes make that metadata replay a no-op — only the new raw lines land.
    /// `INSERT OR IGNORE` on `UNIQUE(session_id, line_hash)` makes ongoing re-scans of
    /// a grown file free. Wrapped in a transaction and using IF NOT EXISTS so an
    /// unclean shutdown between this migration's commit and its `schema_migrations`
    /// marker self-heals on the next launch.
    private static func migration028(_ db: DaemonDatabase) throws {
        logger.info("migration028: creating transcript_lines + clearing JSONL import cursor for backfill…")
        try db.migrationTransaction {
            try db.migrationExecute("""
                CREATE TABLE IF NOT EXISTS transcript_lines (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id   TEXT NOT NULL,
                    file_path    TEXT NOT NULL,
                    line_no      INTEGER NOT NULL,
                    entry_uuid   TEXT NOT NULL DEFAULT '',
                    parent_uuid  TEXT NOT NULL DEFAULT '',
                    entry_type   TEXT NOT NULL DEFAULT '',
                    role         TEXT NOT NULL DEFAULT '',
                    timestamp    TEXT NOT NULL DEFAULT '',
                    is_sidechain INTEGER NOT NULL DEFAULT 0,
                    raw_json     TEXT NOT NULL,
                    line_hash    TEXT NOT NULL,
                    imported_at  TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
            try db.migrationExecute("""
                CREATE UNIQUE INDEX IF NOT EXISTS idx_transcript_lines_dedup
                ON transcript_lines(session_id, line_hash)
            """)
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_transcript_lines_session
                ON transcript_lines(session_id, line_no)
            """)
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_transcript_lines_type
                ON transcript_lines(entry_type)
            """)
            // Clear the mtime cursor so the periodic JSONLImportTask sees no `since`
            // and re-drains ~/.claude/projects, backfilling transcript_lines.
            try db.migrationExecute("DELETE FROM settings WHERE key = 'jsonl_import_last_run_at'")
        }
        logger.info("migration028: transcript_lines created; JSONL import cursor cleared for backfill")
    }

    /// migration029 — creates `transcript_file_cursors`, a per-file byte offset so the
    /// JSONL importer resumes a grown transcript at its tail instead of re-reading it
    /// whole. The `jsonl_import_last_run_at` mtime watermark only decides WHICH files
    /// are eligible; every eligible file was then read start-to-finish, so an active
    /// 180 MB transcript was re-slurped (and every line re-hashed, re-probed against
    /// the dedup index) on each pass. Dedup made that free in ROWS, never in work.
    ///
    /// Resume is gated on `inode` + `head_hash` + `file_size >= byte_offset`: a
    /// compacted, rewritten, or replaced file fails the check and is re-read from
    /// zero, preserving the old capture semantics exactly where they matter. No
    /// backfill is needed — a missing row simply means "read from the beginning".
    private static func migration029(_ db: DaemonDatabase) throws {
        logger.info("migration029: creating transcript_file_cursors…")
        try db.migrationTransaction {
            try db.migrationExecute("""
                CREATE TABLE IF NOT EXISTS transcript_file_cursors (
                    file_path   TEXT PRIMARY KEY,
                    byte_offset INTEGER NOT NULL DEFAULT 0,
                    line_no     INTEGER NOT NULL DEFAULT 0,
                    file_size   INTEGER NOT NULL DEFAULT 0,
                    inode       INTEGER NOT NULL DEFAULT 0,
                    head_hash   TEXT NOT NULL DEFAULT '',
                    updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
        }
        logger.info("migration029: transcript_file_cursors ready")
    }

    /// migration030 — records which version of the startup-enrichment pass last
    /// swept each row, so the pass converges instead of re-running forever.
    ///
    /// `sessionsNeedingEnrichment` selects on absence — `git_branch = '' OR
    /// summary = ''` — and absence is not always fixable: a transcript with no
    /// `custom-title` line never yields a summary, and a `cwd` that no longer
    /// exists never yields a branch. Those rows matched on every single launch
    /// and the set only grew (1,263 → 1,266 over three restarts here), so each
    /// start re-read ~0.5 GB of transcripts to learn what the last start already
    /// knew. Stamping a *swept* marker separates "not enriched yet" from
    /// "enrichment had nothing to give", which the value columns alone cannot.
    ///
    /// Same shape as `project_root_version` (migration017): new rows default to 0
    /// and so sweep once, and a future change to what enrichment can extract is a
    /// constant bump rather than a blanket-reset migration.
    private static func migration030(_ db: DaemonDatabase) throws {
        // Idempotent ADD COLUMN — see migration015.
        if !db.tableHasColumn("sessions", "enrichment_version") {
            try db.migrationExecute("ALTER TABLE sessions ADD COLUMN enrichment_version INTEGER NOT NULL DEFAULT 0")
        }
        logger.info("migration030: sessions.enrichment_version column ready")
    }

    /// migration031 — `rate_limit_snapshots.spend_pct` / `.spend_resets_at`, the
    /// `rate_limits.spend_limit` window Claude Code has sent since v2.1.251.
    /// It appears only behind a Claude apps gateway that sets a spend limit, so
    /// on most installs these columns stay at their defaults forever — that is
    /// the expected state, not a fault.
    ///
    /// Deliberately NOT backfilled, unlike migration010's `account_email`. That
    /// column had a knowable historical truth to write; a spend percentage does
    /// not, and `0` is a legitimate reading ("nothing spent this period"), so
    /// inventing one would be indistinguishable from a real measurement.
    ///
    /// `spend_resets_at` is therefore the presence sentinel, the same role it
    /// plays for the five-hour and seven-day windows in `UsageRowsCompute`:
    /// `> 0` means a gateway actually reported this window, and every historical
    /// row reads as absent rather than as 0% spent.
    private static func migration031(_ db: DaemonDatabase) throws {
        // Idempotent ADD COLUMN — see migration015.
        if !db.tableHasColumn("rate_limit_snapshots", "spend_pct") {
            try db.migrationExecute("ALTER TABLE rate_limit_snapshots ADD COLUMN spend_pct REAL NOT NULL DEFAULT 0")
        }
        if !db.tableHasColumn("rate_limit_snapshots", "spend_resets_at") {
            try db.migrationExecute(
                "ALTER TABLE rate_limit_snapshots ADD COLUMN spend_resets_at INTEGER NOT NULL DEFAULT 0"
            )
        }
        logger.info("migration031: rate_limit_snapshots spend columns ready")
    }

    /// migration032 — drop `idx_rate_limit_snapshots_spend_resets`.
    ///
    /// migration031 created it beside the spend columns, by analogy with
    /// `idx_rate_limit_snapshots_five_hour_resets`. The analogy does not hold:
    /// that one answers `latestFutureFiveHourReset`'s
    /// `WHERE five_hour_resets_at > ? AND five_hour_resets_at <= ?`, and nothing
    /// filters, orders, joins or groups on `spend_resets_at` — it appears only in
    /// SELECT lists. So it bought nothing and charged a B-tree write to every
    /// insert on the daemon's busiest table, over entries that are all the same
    /// key (the `0` sentinel every pre-existing row carries).
    ///
    /// Dropped rather than left alone because the index is already on every
    /// install that ran migration031, and migration031 no longer creates it.
    private static func migration032(_ db: DaemonDatabase) throws {
        try db.migrationExecute("DROP INDEX IF EXISTS idx_rate_limit_snapshots_spend_resets")
        logger.info("migration032: dropped unused idx_rate_limit_snapshots_spend_resets")
    }

    /// migration033 — retype `status_line_events`' dynamically-added columns.
    ///
    /// `DynamicSchema` now declares a new column INTEGER or REAL when the value
    /// that created it is a number; before, every dynamic column was TEXT. Left
    /// alone, that fixes new installs and abandons existing ones — the ordering
    /// bug the change was written to stop (TEXT affinity stores 10 as `'10'`, and
    /// `'10' < '9'`) would stay live on every column already created, and the
    /// same field would serialise out of `GET /events/:id` as a JSON string on an
    /// upgraded install and a JSON number on a fresh one, from one daemon build.
    ///
    /// SQLite cannot retype a column in place, so the table is rebuilt. The new
    /// type is inferred from what is actually stored rather than from a guess: a
    /// column whose every non-null value survives a round trip through INTEGER
    /// becomes INTEGER, one that survives REAL becomes REAL, anything else — and
    /// any column holding nothing at all, which offers no evidence — stays TEXT.
    /// One scan answers every column at once. The `INSERT … SELECT` then rewrites
    /// each value through the new column's affinity, so the rows end up with the
    /// storage class their declared type promises, not just a corrected header.
    ///
    /// Scoped to `status_line_events`: it is the only table a whole payload is
    /// flattened into, and so the only one whose dynamic columns are numeric in
    /// enough quantity for a comparison over them to matter.
    private static func migration033(_ db: DaemonDatabase) throws {
        // The five columns every per-type table is created with. Their types are
        // already right, and `id`'s INTEGER PRIMARY KEY AUTOINCREMENT and
        // `event_log_id`'s foreign key have to be reproduced verbatim rather than
        // inferred from the data.
        let fixed = ["id", "event_log_id", "session_id", "timestamp", "cwd"]
        var dynamicColumns: [(name: String, type: String)] = []
        try db.query("PRAGMA table_info(status_line_events)") { row in
            let name = db.string(row, 1)
            guard !fixed.contains(name) else { return }
            dynamicColumns.append((name, db.string(row, 2).uppercased()))
        }
        // Only TEXT (and typeless) columns are candidates. One that already reads
        // INTEGER or REAL was created by this branch and is correct.
        let candidates = dynamicColumns
            .filter { $0.type != "INTEGER" && $0.type != "REAL" }
            .map(\.name)
            .filter { DynamicSchema.isSafeColumnName($0) }
        guard !candidates.isEmpty else {
            logger.info("migration033: status_line_events has no TEXT columns to retype")
            return
        }

        // Three counts per candidate in a single pass: how many non-null values
        // it holds, and how many of those change when cast to INTEGER / to REAL
        // and back. Zero changed means every value is exactly representable, so
        // the cast is lossless and the type is honest.
        var selects: [String] = []
        for name in candidates {
            let col = #""\#(name)""#
            selects.append("SUM(CASE WHEN \(col) IS NOT NULL THEN 1 ELSE 0 END)")
            selects.append(
                "SUM(CASE WHEN \(col) IS NOT NULL "
                    + "AND CAST(CAST(\(col) AS INTEGER) AS TEXT) <> CAST(\(col) AS TEXT) "
                    + "THEN 1 ELSE 0 END)"
            )
            selects.append(
                "SUM(CASE WHEN \(col) IS NOT NULL "
                    + "AND CAST(CAST(\(col) AS REAL) AS TEXT) <> CAST(\(col) AS TEXT) "
                    + "THEN 1 ELSE 0 END)"
            )
        }
        var inferred: [String: String] = [:]
        try db.query("SELECT \(selects.joined(separator: ", ")) FROM status_line_events") { row in
            for (offset, name) in candidates.enumerated() {
                let present = db.int64(row, offset * 3)
                let notInteger = db.int64(row, offset * 3 + 1)
                let notReal = db.int64(row, offset * 3 + 2)
                if present == 0 {
                    inferred[name] = "TEXT"
                } else if notInteger == 0 {
                    inferred[name] = "INTEGER"
                } else if notReal == 0 {
                    inferred[name] = "REAL"
                } else {
                    inferred[name] = "TEXT"
                }
            }
        }
        let retyped = candidates.filter { inferred[$0] != "TEXT" }
        guard !retyped.isEmpty else {
            logger.info("migration033: status_line_events' TEXT columns hold no numbers")
            return
        }

        // Indexes are dropped with the old table, so re-create them from their
        // own recorded DDL afterwards rather than from a hard-coded list that
        // would silently lose one added by a later migration.
        var indexSQL: [String] = []
        try db.query("""
            SELECT sql FROM sqlite_master
            WHERE type = 'index' AND tbl_name = 'status_line_events' AND sql IS NOT NULL
        """) { row in
            indexSQL.append(db.string(row, 0))
        }

        let newColumns = dynamicColumns.map { column -> String in
            let type = inferred[column.name] ?? (column.type.isEmpty ? "TEXT" : column.type)
            return #""\#(column.name)" \#(type)"#
        }
        let allNames = (fixed + dynamicColumns.map(\.name)).map { #""\#($0)""# }
            .joined(separator: ", ")

        // One transaction: a rebuild interrupted between the DROP and the RENAME
        // would leave the daemon with no status_line_events at all.
        try db.migrationTransaction {
            // `retyped` being non-empty means `newColumns` is too, so the
            // trailing comma after `cwd` always has something to introduce.
            try db.migrationExecute(
                "CREATE TABLE status_line_events_migration033 ("
                    + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                    + "event_log_id INTEGER NOT NULL REFERENCES event_log(id) ON DELETE CASCADE, "
                    + "session_id TEXT NOT NULL DEFAULT '', "
                    + "timestamp TEXT NOT NULL DEFAULT '', "
                    + "cwd TEXT NOT NULL DEFAULT '', "
                    + newColumns.joined(separator: ", ")
                    + ")"
            )
            try db.migrationExecute("""
                INSERT INTO status_line_events_migration033 (\(allNames))
                SELECT \(allNames) FROM status_line_events
            """)
            try db.migrationExecute("DROP TABLE status_line_events")
            try db.migrationExecute(
                "ALTER TABLE status_line_events_migration033 RENAME TO status_line_events"
            )
            for sql in indexSQL {
                try db.migrationExecute(sql)
            }
        }
        // The cache holds the old table's column set, which is still accurate by
        // name — but not by type, and nothing else here reads types. Invalidate
        // anyway: the table object it described no longer exists.
        db.dynamicSchema.invalidate(table: "status_line_events")
        logger.info("migration033: retyped \(retyped.count, privacy: .public) status_line_events columns")
    }

    /// migration034 — subagent attribution + dispatch metadata + transcript
    /// titles, replicating claude-usage's schema:
    /// - `transcript_turns.is_subagent` / `.agent_id`: which turns belong to
    ///   a dispatched subagent (Task/Agent tool), detected by the scanner via
    ///   the `isSidechain` flag, a record-level `agentId`, or a `subagents/`
    ///   transcript path.
    /// - `agent_dispatches`: one row per subagent dispatch, keyed by
    ///   `agent_id`, from the parent session's `toolUseResult` record
    ///   (analogous to claude-usage's `agents` table). Re-imports upsert.
    /// - `sessions.transcript_title` / `.title_source`: session titles from
    ///   `custom-title` / `ai-title` JSONL records. Separate columns from
    ///   `summary` so imports never clobber the daemon's own summarizer — or
    ///   `SessionEnricher`, which lands the latest `custom-title` INTO
    ///   `summary` from the already-stored `transcript_lines`. These columns
    ///   keep the raw provenance (`custom` vs `ai`) that path discards.
    ///
    /// ALTERs are guarded (cf. migration019) and CREATEs use IF NOT EXISTS
    /// (cf. migration020) so an unclean shutdown mid-migration — or a branch
    /// divergence that re-runs the version — self-heals instead of wedging
    /// startup on "duplicate column name".
    private static func migration034(_ db: DaemonDatabase) throws {
        if !db.tableHasColumn("transcript_turns", "is_subagent") {
            try db.migrationExecute(
                "ALTER TABLE transcript_turns ADD COLUMN is_subagent INTEGER NOT NULL DEFAULT 0"
            )
        }
        if !db.tableHasColumn("transcript_turns", "agent_id") {
            try db.migrationExecute(
                "ALTER TABLE transcript_turns ADD COLUMN agent_id TEXT NOT NULL DEFAULT ''"
            )
        }
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_transcript_turns_agent_id ON transcript_turns(agent_id)"
        )

        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS agent_dispatches (
                agent_id TEXT PRIMARY KEY,
                session_id TEXT NOT NULL,
                agent_type TEXT NOT NULL DEFAULT '',
                started_at TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT '',
                total_tokens INTEGER NOT NULL DEFAULT 0,
                total_duration_ms INTEGER NOT NULL DEFAULT 0,
                total_tool_use_count INTEGER NOT NULL DEFAULT 0,
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_agent_dispatches_session_id ON agent_dispatches(session_id)"
        )
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_agent_dispatches_agent_type ON agent_dispatches(agent_type)"
        )

        if !db.tableHasColumn("sessions", "transcript_title") {
            try db.migrationExecute(
                "ALTER TABLE sessions ADD COLUMN transcript_title TEXT NOT NULL DEFAULT ''"
            )
        }
        if !db.tableHasColumn("sessions", "title_source") {
            try db.migrationExecute(
                "ALTER TABLE sessions ADD COLUMN title_source TEXT NOT NULL DEFAULT ''"
            )
        }
        logger.info("migration034: subagent attribution + agent_dispatches + transcript titles ready")
    }

    /// migration035 — record each turn's **1-hour** cache-creation tokens.
    ///
    /// Cache writes bill at 1.25× base input at the 5-minute default and 2× at
    /// 1h, and transcripts have carried the split all along in
    /// `usage.cache_creation.ephemeral_1h_input_tokens` — stenographer just
    /// never read it, so every persisted cost assumed 5m and understated 1h
    /// traffic by 37.5% of its cache-creation line. Existing rows keep the
    /// column's `0` default, which *is* the old assumption; a re-import of a
    /// touched transcript upgrades them in place.
    ///
    /// Guarded ALTER (cf. migration019) so a re-run of the version self-heals
    /// rather than wedging startup on "duplicate column name".
    private static func migration035(_ db: DaemonDatabase) throws {
        if !db.tableHasColumn("transcript_turns", "cache_creation_1h_tokens") {
            try db.migrationExecute(
                "ALTER TABLE transcript_turns ADD COLUMN cache_creation_1h_tokens "
                + "INTEGER NOT NULL DEFAULT 0"
            )
        }
        logger.info("migration035: transcript_turns.cache_creation_1h_tokens ready")
    }

    /// migration036 — retype `file_size_bytes` on the two tables
    /// `FileFingerprintEnricher` writes.
    ///
    /// The enricher hands `DynamicSchema` a Swift `Int`, which `affinity(for:)`
    /// declares INTEGER — so a fresh install gets an INTEGER column. Every
    /// install that predates that (the enricher's first shape put a string in
    /// the dict) has the same column as TEXT, and `migration033` cannot help:
    /// it is scoped to `status_line_events`. The result is one daemon build
    /// answering the same question two different ways — `ORDER BY
    /// file_size_bytes` sorts 9 after 10 on the upgraded DB, and
    /// `GET /events/:id` serialises the size as a JSON string there and a JSON
    /// number on a fresh one.
    ///
    /// `file_sha256` is deliberately left alone: a hex digest is TEXT on both,
    /// and a 64-character hex string is not a number in any affinity.
    ///
    /// Both tables are per-type event tables, so they share the same five fixed
    /// columns and the rebuild can be table-parameterised.
    private static func migration036(_ db: DaemonDatabase) throws {
        for table in ["config_change_events", "instructions_loaded_events"] {
            try retypeToInteger(db, table: table, column: "file_size_bytes")
        }
        logger.info("migration036: file_size_bytes affinity reconciled")
    }

    /// migration037 — index every per-type table on `event_log_id` alone.
    ///
    /// `event_log_id` is the child key of an `ON DELETE CASCADE` foreign key,
    /// and SQLite resolves a cascade by *querying the child table* for the
    /// parent's key. migration013's `(session_id, event_log_id)` cannot serve
    /// that query — `event_log_id` is not the leftmost column — so every
    /// cascaded delete degrades to a full scan of the child. Measured on a live
    /// capture DB:
    ///
    /// ```
    /// sqlite> EXPLAIN QUERY PLAN DELETE FROM status_line_events WHERE event_log_id = 1;
    /// `--SCAN status_line_events
    /// ```
    ///
    /// with 841,264 rows in that table. `RetentionTask` deletes 50 `event_log`
    /// rows per batch, so one batch is 50 full scans of every per-type table —
    /// on the serial database queue that ingest and the HTTP reader share. This
    /// is why retention on a large capture appears to hang rather than run.
    ///
    /// Retention is opt-in and off by default, which is the only reason this has
    /// gone unnoticed; it is also why the fix has to land before anyone turns it
    /// on. Same shape as migration013: `IF NOT EXISTS`, one transaction so a
    /// large DB's index build is one commit rather than 29 fsyncs.
    private static func migration037(_ db: DaemonDatabase) throws {
        logger.info("migration037: building per-type event_log_id indexes…")
        try db.migrationTransaction {
            for eventType in HookEventType.allCases {
                try db.migrationExecute(
                    "CREATE INDEX IF NOT EXISTS idx_\(eventType.tableName)_event_log "
                    + "ON \(eventType.tableName)(event_log_id)"
                )
            }
        }
        logger.info("migration037: per-type event_log_id indexes ready")
    }

    /// migration038 — the Conversations feed's index over `transcript_lines`.
    ///
    /// The feed is one global newest-first timeline across every observed
    /// session, so its query has no session to narrow on — it orders 4.4M rows
    /// (2.8M of them conversational) by `timestamp` and takes the first page.
    /// migration028's three indexes are all session- or type-leading, so without
    /// this the read is a full scan plus a temp B-tree sort, on the serial
    /// database queue that ingest shares.
    ///
    /// Partial, because the feed never wants the other 1.6M rows and a partial
    /// index is both smaller and cheaper to maintain on ingest. The `WHERE`
    /// clause is written as an explicit `OR` rather than `IN ('user',
    /// 'assistant')` because SQLite matches a partial index by comparing the
    /// query's `WHERE` terms against the index's syntactically — the query has
    /// to repeat this expression verbatim to qualify. Verified against the real
    /// schema:
    ///
    /// ```
    /// sqlite> EXPLAIN QUERY PLAN SELECT … ORDER BY t.timestamp DESC LIMIT 500;
    /// `--SCAN t USING INDEX idx_transcript_lines_conversation
    /// ```
    ///
    /// — no `USE TEMP B-TREE FOR ORDER BY`, which is the part that mattered.
    private static func migration038(_ db: DaemonDatabase) throws {
        logger.info("migration038: building the conversation timestamp index…")
        try ensureConversationIndex(db)
        logger.info("migration038: conversation timestamp index ready")
    }

    /// The guarded `idx_transcript_lines_conversation` CREATE — shared by
    /// `migration038` and the post-runner self-heal in `runMigrations`, the same
    /// pairing `ensureSessionsAuthMethodColumn` uses, so the two can never drift.
    ///
    /// Outside the version gate because `conversationEntries` names this index with
    /// `INDEXED BY`, and that is not a hint: SQLite refuses to *prepare* a statement
    /// naming an index that isn't there ("no such index"). A DB that drifted — a
    /// branch-switched install, a migration that recorded its marker without its
    /// index — would fail every call, and the XPC caller's `try?` turns that into a
    /// permanently empty Conversations window with nothing logged. Naming the index
    /// is deliberate (see `conversationEntries`), so the way to keep it honest is to
    /// guarantee the index exists on every launch. Idempotent, and a no-op before
    /// `transcript_lines` exists (synthetic legacy fixtures).
    static func ensureConversationIndex(_ db: DaemonDatabase) throws {
        guard db.tableExists("transcript_lines") else { return }
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_transcript_lines_conversation
            ON transcript_lines(timestamp)
            WHERE is_sidechain = 0 AND (entry_type = 'user' OR entry_type = 'assistant')
        """)
    }

    /// migration039 — the three columns the Sessions window's tight row layout needs, none of
    /// which the hook payload carries directly:
    ///
    /// - `last_output`      — the agent's most recent prose reply, tailed out of the
    ///                        transcript when the Stop hook fires (the row's second line).
    /// - `last_event_type`  — the last hook seen for the session, which is the only
    ///                        signal that separates *working* from *idle* from
    ///                        *waiting for you* (the row's activity icon).
    /// - `summary_at`       — when `summary` was written. `summary = ''` alone cannot
    ///                        express "summarized, but the session has moved on since",
    ///                        so an active session's summary froze at its first value.
    ///
    /// Guarded ALTERs: a DB that rode a pre-rebase branch may already carry one.
    private static func migration039(_ db: DaemonDatabase) throws {
        if !db.tableHasColumn("sessions", "last_output") {
            try db.migrationExecute(
                "ALTER TABLE sessions ADD COLUMN last_output TEXT NOT NULL DEFAULT ''"
            )
        }
        if !db.tableHasColumn("sessions", "last_event_type") {
            try db.migrationExecute(
                "ALTER TABLE sessions ADD COLUMN last_event_type TEXT NOT NULL DEFAULT ''"
            )
        }
        if !db.tableHasColumn("sessions", "summary_at") {
            try db.migrationExecute(
                "ALTER TABLE sessions ADD COLUMN summary_at TEXT NOT NULL DEFAULT ''"
            )
        }
        // Existing summaries predate the stamp. Treat them as written at the
        // session's last activity rather than at the epoch, so the widened
        // "needs a summary" query doesn't re-bill a model call for every row
        // in the table on the first pass after upgrading.
        //
        // Column-guarded like the ALTERs above, and for the same reason: a DB whose
        // early migrations were recorded without being run has a `sessions` table
        // from the base schema, without the columns this statement reads.
        if db.tableHasColumn("sessions", "summary_at"),
           db.tableHasColumn("sessions", "last_activity_at"),
           db.tableHasColumn("sessions", "summary") {
            try db.migrationExecute(
                "UPDATE sessions SET summary_at = last_activity_at WHERE summary != '' AND summary_at = ''"
            )
        }
    }

    /// migration040 — forget the `last_output` previews migration039's first reader
    /// stored, for the sessions the startup pass reads again.
    ///
    /// That reader collapsed the agent's markdown onto one line, which destroys it:
    /// a list item or table row is only one because it starts a line, so the
    /// Sessions row was left showing stray `-` and `|`. The reader now stores the
    /// text as written, but only a new `Stop` would replace an old preview, and an
    /// idle session never sends one. Emptied, these rows are exactly what
    /// ``sessionIdsMissingLastOutput(recentHours:)`` selects, so the next launch
    /// re-reads each from its transcript. Rows outside that reach keep their
    /// flattened text: nothing shows them, and nothing would re-read them.
    private static func migration040(_ db: DaemonDatabase) throws {
        guard db.tableHasColumn("sessions", "last_output"),
              db.tableHasColumn("sessions", "last_activity_at") else { return }
        try db.migrationExecute("""
            UPDATE sessions SET last_output = ''
            WHERE last_output != ''
              AND (status != '\(SessionStatus.ended.rawValue)'
                   OR last_activity_at >= datetime('now', '-\(Self.lastOutputReachHours) hours'))
        """)
    }

    /// How many of a session's newest hook events migration041 walks looking for one
    /// that sets its turn state. A subagent's fan-out is dozens of events at most.
    private static let turnStateHealEventLimit = 500

    /// migration041 — add `sessions.turn_state_at`, and re-derive `last_event_type`
    /// (with the time it was set) for every active session under
    /// ``HookEventType/setsTurnState(_:hookData:)``.
    ///
    /// The old upsert let any non-ambient event set the state, so a session whose
    /// subagent finished after the turn's `Stop`, or that got the idle reminder
    /// `Notification` a minute later, is stored as working or waiting — and an idle
    /// session sends nothing that would correct it. Each active session's state is
    /// read back off its own newest hook events (imported transcript rows carry a
    /// `message_id` and never set the state), with the detail each rule needs taken
    /// from the event's per-type table. Ended sessions are left alone: they read as
    /// idle whatever they store.
    ///
    /// `turn_state_at` is what `InterruptedTurnTask` weighs an interrupt against. The
    /// ALTER is guarded: a DB that rode a pre-rebase branch may already carry it. A
    /// legacy fixture's `sessions` without `status` has no live sessions to heal.
    private static func migration041(_ db: DaemonDatabase) throws {
        guard db.tableHasColumn("sessions", "last_event_type") else { return }
        if !db.tableHasColumn("sessions", "turn_state_at") {
            try db.migrationExecute("ALTER TABLE sessions ADD COLUMN turn_state_at TEXT NOT NULL DEFAULT ''")
        }
        guard db.tableHasColumn("sessions", "status") else { return }
        var sessionIds: [String] = []
        try db.query(
            "SELECT session_id FROM sessions WHERE status = ?",
            params: [SessionStatus.active.rawValue],
            deadline: DaemonDatabase.migrationWriteDeadline
        ) { row in
            sessionIds.append(db.string(row, 0))
        }
        var detailColumns: [String: Set<String>] = [:]
        for sessionId in sessionIds {
            let state = try turnStateFromEventLog(db, sessionId: sessionId, detailColumns: &detailColumns)
            try db.migrationExecute(
                """
                UPDATE sessions SET last_event_type = ?, turn_state_at = COALESCE(datetime(?), '')
                WHERE session_id = ?
                """,
                params: [state.type, state.timestamp, sessionId]
            )
        }
        logger.info("migration041: re-derived turn state for \(sessionIds.count) active session(s)")
    }

    /// migration042 — widen the `transcript_turns` timestamp index to cover
    /// `session_id`, so the burst walk reads the index and never the table.
    ///
    /// ``burstIntervals`` selects exactly `(session_id, timestamp)` over a
    /// week-wide range, and the status line asks for it four times per
    /// `usageCacheTTL`. Against the single-column `idx_transcript_turns_timestamp`
    /// that range scan had to seek the table b-tree once per row to pick up
    /// `session_id` — on a 2.5M-row table in a 41 GB file, ~200k random `pread`s
    /// per call. The daemon never reached idle: 33% of a core, sustained, with 189
    /// of 264 stack samples inside that one query.
    ///
    /// With `(timestamp, session_id)` the same statement plans as a COVERING INDEX
    /// scan. Measured on that DB, one week: 1.25s → 0.21s.
    ///
    /// The old single-column index is dropped rather than kept alongside.
    /// `timestamp` is this index's leftmost column, so every lookup the old one
    /// served is served here too; keeping both would only buy write amplification
    /// on the most heavily inserted table in the schema.
    private static func migration042(_ db: DaemonDatabase) throws {
        logger.info("migration042: building the transcript-turns burst index…")
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_transcript_turns_time_session "
            + "ON transcript_turns(timestamp, session_id)"
        )
        try db.migrationExecute("DROP INDEX IF EXISTS idx_transcript_turns_timestamp")
        logger.info("migration042: burst index ready")
    }

    /// migration043 — add `sessions.subagent_activity_at`: when a subagent of this
    /// session was last seen doing something, or '' when none is in flight.
    ///
    /// `turn_state_at` deliberately ignores everything a subagent does — every hook
    /// a subagent fires carries an `agent_id`, and ``HookEventType/setsTurnState(_:hookData:)``
    /// refuses all of them, because a background agent's `SubagentStop` landing after
    /// the main turn's `Stop` used to leave a finished session spinning forever. That
    /// is the right rule for the *turn*, and it leaves a real gap: a session whose
    /// main agent has handed back while a background subagent is still working reads
    /// as idle, when the honest answer is that work is in flight.
    ///
    /// This is that answer, kept on its own clock so the turn's is untouched. No
    /// backfill: it describes what is happening *now*, and the first event from any
    /// live subagent fills it within seconds. The ALTER is guarded — a DB that rode
    /// a pre-rebase branch may already carry the column, and an unguarded
    /// `ALTER … ADD COLUMN` that throws takes the whole daemon down with exit 0.
    private static func migration043(_ db: DaemonDatabase) throws {
        guard db.tableHasColumn("sessions", "turn_state_at") else { return }
        if !db.tableHasColumn("sessions", "subagent_activity_at") {
            try db.migrationExecute(
                "ALTER TABLE sessions ADD COLUMN subagent_activity_at TEXT NOT NULL DEFAULT ''")
        }
        logger.info("migration043: subagent activity clock ready")
    }

    /// migration044 — `conversation_queued_prompts`: which `transcript_lines` rows
    /// are prompts the human typed while the agent was working.
    ///
    /// Claude Code records such a prompt as an `attachment` entry, not a `user`
    /// one (see ``ConversationExtractor``), so the Conversations feed, which
    /// reads user and assistant rows through migration038's partial index,
    /// never saw them. Widening that index to cover attachments would put 1.7M
    /// rows in it to find the 0.5% that are prompts. Widening it to only the
    /// prompts would need a column saying which attachments are prompts, and
    /// finding them means reading `raw_json`, measured at 98s for the existing
    /// attachments. That is too long for a migration, which runs before the
    /// daemon serves anything.
    ///
    /// So they get a table of their own, created empty here and cheap to create.
    /// The importer adds new prompts as it stores their lines, and
    /// ``QueuedPromptBackfillTask`` fills in the history in batches once the
    /// daemon is up. It holds ids and timestamps, not text: the feed joins back
    /// to `transcript_lines` for the line itself, so the extractor stays the one
    /// place that decides what a line says.
    private static func migration044(_ db: DaemonDatabase) throws {
        guard db.tableExists("transcript_lines") else { return }
        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS conversation_queued_prompts (
                line_id    INTEGER PRIMARY KEY,
                session_id TEXT NOT NULL,
                timestamp  TEXT NOT NULL
            )
        """)
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_conversation_queued_prompts_time
            ON conversation_queued_prompts(timestamp)
        """)
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_conversation_queued_prompts_session
            ON conversation_queued_prompts(session_id, timestamp)
        """)
        logger.info("migration044: queued-prompt table ready")
    }

    /// migration045 — add `sessions.subagent_stopped_at`: the newest moment a
    /// subagent was known to have ended (a `SubagentStop`, a subagent's
    /// `StopFailure`, or an interrupt of the turn).
    ///
    /// Clearing `subagent_activity_at` to '' on a stop forgot *when* the stop
    /// happened, so any older subagent event ingested afterwards — a drained
    /// drop-dir backlog, a quarantine re-feed, an async hook overtaken by the stop —
    /// compared above '' and re-stamped a finished subagent as live for the whole
    /// freshness window. A re-stamp now has to be newer than this too. No
    /// backfill: '' sorts below every real time, which is exactly the old rule.
    private static func migration045(_ db: DaemonDatabase) throws {
        guard db.tableHasColumn("sessions", "subagent_activity_at") else { return }
        if !db.tableHasColumn("sessions", "subagent_stopped_at") {
            try db.migrationExecute(
                "ALTER TABLE sessions ADD COLUMN subagent_stopped_at TEXT NOT NULL DEFAULT ''")
        }
        logger.info("migration045: subagent stop clock ready")
    }

    /// The newest of `sessionId`'s hook events that sets its turn state, and its time —
    /// both "" if none of the last ``turnStateHealEventLimit`` does. `detailColumns`
    /// caches each per-type table's columns across sessions.
    private static func turnStateFromEventLog(
        _ db: DaemonDatabase,
        sessionId: String,
        detailColumns: inout [String: Set<String>]
    ) throws -> (type: String, timestamp: String) {
        var events: [(id: Int, type: String, timestamp: String)] = []
        try db.query("""
            SELECT id, event_type, timestamp FROM event_log
            WHERE session_id = ? AND message_id = ''
            ORDER BY timestamp DESC, id DESC
            LIMIT ?
        """, params: [sessionId, Self.turnStateHealEventLimit], deadline: DaemonDatabase.migrationWriteDeadline) { row in
            events.append((id: db.int(row, 0), type: db.string(row, 1), timestamp: db.string(row, 2)))
        }
        let detailKeys = ["agent_id", "notification_type", "source"]
        for event in events {
            var hookData: [String: Any] = [:]
            if let table = HookEventType(rawValue: event.type)?.tableName {
                if detailColumns[table] == nil {
                    var columns: Set<String> = []
                    try? db.query("PRAGMA table_info(\(table))") { row in columns.insert(db.string(row, 1)) }
                    detailColumns[table] = columns
                }
                let wanted = detailKeys.filter { detailColumns[table]?.contains($0) ?? false }
                if !wanted.isEmpty {
                    let select = wanted.map { "COALESCE(\($0), '')" }.joined(separator: ", ")
                    try db.query(
                        "SELECT \(select) FROM \(table) WHERE event_log_id = ? LIMIT 1",
                        params: [event.id],
                        deadline: DaemonDatabase.migrationWriteDeadline
                    ) { row in
                        for (index, key) in wanted.enumerated() {
                            hookData[key] = db.string(row, index)
                        }
                    }
                }
            }
            if HookEventType.setsTurnState(event.type, hookData: hookData) { return (event.type, event.timestamp) }
        }
        return ("", "")
    }

    /// Rebuild `table` with `column` declared INTEGER, preserving every other
    /// column's declared type, the row contents, and the table's indexes.
    ///
    /// No-ops when the table or the column is absent, when the column already
    /// reads INTEGER, or — the safety valve — when the column holds a non-null
    /// value that does not survive a round trip through INTEGER. That last case
    /// is the only one where retyping would *lose* something, and it means the
    /// column is not what this migration believes it to be; leaving it TEXT and
    /// saying so beats silently truncating a value.
    ///
    /// SQLite cannot retype in place, so this is the `migration033` rebuild:
    /// create, `INSERT … SELECT` (which rewrites each value through the new
    /// column's affinity, so the rows end up with the storage class the header
    /// now promises), drop, rename, re-create the indexes from their own
    /// recorded DDL. One transaction, because a rebuild interrupted between the
    /// DROP and the RENAME would leave the daemon with no table at all.
    private static func retypeToInteger(_ db: DaemonDatabase, table: String, column: String) throws {
        guard DynamicSchema.isSafeColumnName(column) else { return }
        // The five columns every per-type table is created with. `id`'s INTEGER
        // PRIMARY KEY AUTOINCREMENT and `event_log_id`'s foreign key have to be
        // reproduced verbatim rather than inferred from `table_info`.
        let fixed = ["id", "event_log_id", "session_id", "timestamp", "cwd"]
        var dynamicColumns: [(name: String, type: String)] = []
        var found = false
        try db.query("PRAGMA table_info(\(table))") { row in
            let name = db.string(row, 1)
            let type = db.string(row, 2).uppercased()
            if name == column { found = true }
            guard !fixed.contains(name) else { return }
            dynamicColumns.append((name, type))
        }
        guard found else { return }
        guard dynamicColumns.first(where: { $0.name == column })?.type != "INTEGER" else { return }
        guard dynamicColumns.allSatisfy({ DynamicSchema.isSafeColumnName($0.name) }) else {
            logger.error(
                "migration036: \(table, privacy: .public) has an unquotable column; skipped"
            )
            return
        }

        let quoted = #""\#(column)""#
        var lossy: Int64 = 0
        try db.query("""
            SELECT SUM(CASE WHEN \(quoted) IS NOT NULL
                             AND CAST(CAST(\(quoted) AS INTEGER) AS TEXT) <> CAST(\(quoted) AS TEXT)
                        THEN 1 ELSE 0 END)
            FROM \(table)
        """) { row in
            lossy = db.int64(row, 0)
        }
        guard lossy == 0 else {
            logger.error(
                """
                migration036: \(table, privacy: .public).\(column, privacy: .public) holds \
                \(lossy, privacy: .public) non-integer values; left TEXT
                """
            )
            return
        }

        // Indexes are dropped with the old table; re-create them from their own
        // recorded DDL rather than a hard-coded list that would silently lose
        // one added by a later migration.
        var indexSQL: [String] = []
        try db.query("""
            SELECT sql FROM sqlite_master
            WHERE type = 'index' AND tbl_name = '\(table)' AND sql IS NOT NULL
        """) { row in
            indexSQL.append(db.string(row, 0))
        }

        let rebuilt = table + "_migration036"
        let newColumns = dynamicColumns.map { entry -> String in
            let type = entry.name == column
                ? "INTEGER"
                : (entry.type.isEmpty ? "TEXT" : entry.type)
            return #""\#(entry.name)" \#(type)"#
        }
        let allNames = (fixed + dynamicColumns.map(\.name)).map { #""\#($0)""# }
            .joined(separator: ", ")

        try db.migrationTransaction {
            // `found` being true means the target column is in `dynamicColumns`,
            // so the trailing comma after `cwd` always has something to
            // introduce.
            try db.migrationExecute(
                "CREATE TABLE \(rebuilt) ("
                    + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                    + "event_log_id INTEGER NOT NULL REFERENCES event_log(id) ON DELETE CASCADE, "
                    + "session_id TEXT NOT NULL DEFAULT '', "
                    + "timestamp TEXT NOT NULL DEFAULT '', "
                    + "cwd TEXT NOT NULL DEFAULT '', "
                    + newColumns.joined(separator: ", ")
                    + ")"
            )
            try db.migrationExecute("""
                INSERT INTO \(rebuilt) (\(allNames))
                SELECT \(allNames) FROM \(table)
            """)
            try db.migrationExecute("DROP TABLE \(table)")
            try db.migrationExecute("ALTER TABLE \(rebuilt) RENAME TO \(table)")
            for sql in indexSQL {
                try db.migrationExecute(sql)
            }
        }
        // The cache holds the old table object's column set — still accurate by
        // name, but describing a table that no longer exists.
        db.dynamicSchema.invalidate(table: table)
        logger.info(
            "migration036: retyped \(table, privacy: .public).\(column, privacy: .public) to INTEGER"
        )
    }
}

extension SessionSchema: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
// swiftlint:enable identifier_name line_length
