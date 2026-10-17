#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB

/// The newest-first conversation feed, read from stored transcript lines.
///
/// Holds the database it reads and the cache of parsed lines, so a poll
/// re-parses only what is new — see ``ConversationExtractCache``. Value-typed
/// and cheap to copy: both properties are shared references.
public struct ConversationStore: Sendable {
    public let database: DaemonDatabase
    public let extractCache: ConversationExtractCache

    public init(database: DaemonDatabase, extractCache: ConversationExtractCache = ConversationExtractCache()) {
        self.database = database
        self.extractCache = extractCache
    }

    // MARK: - Conversations feed

    /// The newest conversation lines across every observed session, newest first.
    ///
    /// Rows are classified by ``ConversationExtractor`` at read time rather than
    /// materialised into a table of their own. The alternative — a
    /// `conversation_entries` table filled on ingest — would need a 4.4M-row
    /// backfill and a second copy of every prompt and reply, to serve a window
    /// that reads a few hundred rows at a time. Parsing at query time keeps the
    /// classification rules in one place and disposable: changing what counts as
    /// a reply is an edit to the extractor, not a migration.
    ///
    /// The cost of that choice is that the *kind* filter can only be applied
    /// after parsing, so a `limit` of showable entries needs more than `limit`
    /// rows scanned. `scanMultiplier` covers the shortfall: most scanned rows
    /// are tool calls and tool results, which yield no line at all whatever the
    /// options say, so the shortfall is large either way. `maxScan` is the
    /// backstop for a stretch of transcript that is all tool traffic; hitting it
    /// returns a short page rather than walking the whole table, and the caller
    /// pages on with `before`.
    ///
    /// - Parameters:
    ///   - limit: how many entries to return.
    ///   - includeWorkOutput: include the two kinds that are the agent talking
    ///     about its own work — `progress` and `thinking`. Off, the feed is the
    ///     conversation only: what the human typed and what the agent said back.
    ///   - before: return only entries strictly older than this ISO-8601
    ///     timestamp — the paging cursor, taken from the oldest entry of the
    ///     previous page.
    ///   - sessionId: narrow to one session. Not a filter over the merged
    ///     result: that result is a *page* — the newest few hundred lines across
    ///     every session, of which one session's share may be two — so a
    ///     conversation sieved out of it has holes in it. Scoped, the query
    ///     takes a different index and a different order; see below.
    public func conversationEntries(
        limit: Int,
        includeWorkOutput: Bool,
        before: String?,
        sessionId: String? = nil
    ) throws -> [ConversationEntryDTO] {
        // Measured, not guessed: with work output off, a merged read of 200
        // entries at a multiplier of 6 came back with 42. Most scanned rows
        // yield nothing at all — a tool call, a tool result, a hook's notice —
        // and turning work output off throws away most of what is left, so the
        // shortfall is worst exactly where the window spends its time. Twelve
        // is what it was before it was halved, and the scan is index-ordered,
        // so the extra rows are read in `LIMIT` order rather than sorted.
        let scanMultiplier = includeWorkOutput ? 3 : 12
        let maxScan = 20_000
        let scanLimit = min(max(limit, 1) * scanMultiplier, maxScan)

        // `timestamp != ''` because not every captured entry type carries one,
        // and an empty string sorts below every real timestamp — it would
        // otherwise fill the oldest page. The `is_sidechain` / `entry_type`
        // terms are repeated verbatim from migration038's partial index; see
        // that migration for why the shape matters.
        //
        // `INDEXED BY` because repeating those terms is what makes the partial
        // index *usable*, not what makes it *chosen*. Left to its own costing —
        // and there is no `sqlite_stat1` here, so costing is guesswork — the
        // planner preferred `idx_transcript_lines_type (entry_type=?)`, which
        // answers `ORDER BY timestamp DESC LIMIT n` by reading every user and
        // assistant row in the table, seeking out each one's `raw_json`, and
        // sorting the lot in a temp b-tree to keep the newest few thousand. On a
        // 4.7M-row `transcript_lines` whose `raw_json` is 16.8 GB that is minutes
        // per call, and the Conversations window asks on a timer: one reader lane
        // pinned at 100% for as long as the window is open. Named outright, the
        // partial index supplies the DESC order itself, so `LIMIT` stops the scan
        // — measured 2400 rows in 0.11s. The name is a hard dependency on
        // migration038 on purpose: if that index ever goes, this fails loudly
        // instead of silently falling back to the plan that wedged the daemon.
        //
        // Scoped to one session, the index changes but the ORDER BY must not.
        // `idx_transcript_lines_session (session_id, line_no)` answers
        // `session_id = ?` with its rows already in `line_no` order, which is
        // free to walk — but `line_no` is a position within a transcript
        // *file*, and a session that was resumed has more than one (326 of
        // them in the live database). Ordered by `line_no DESC`, two files'
        // lines interleave, so the newest-first page is not in time order and
        // the `before` cursor — which cuts on `timestamp` — skips whatever sits
        // on the wrong side of the shuffle. Those rows are then unreachable:
        // the next page asks for older still.
        //
        // So the scoped read sorts on `timestamp` too, and keeps the cheap
        // index by doing it in two steps: an inner pick that takes the session's
        // ids in time order (the index supplies the rows; the sort carries two
        // small columns, not 3 KB of `raw_json` each), and the outer join that
        // fetches the page those ids name.
        let scoped = (sessionId?.isEmpty == false) ? sessionId : nil
        var params: [any Sendable] = []
        let columns = """
            t.id, t.session_id, t.timestamp, t.raw_json,
                   s.project_root, s.cwd, s.git_branch, s.transcript_title,
                   s.term_program
            """
        let sql: String
        if let scoped {
            params.append(scoped)
            var pick = """
                SELECT id FROM transcript_lines INDEXED BY idx_transcript_lines_session
                WHERE session_id = ?
                  AND is_sidechain = 0
                  AND (entry_type = 'user' OR entry_type = 'assistant')
                  AND timestamp != ''
                """
            if let before, !before.isEmpty {
                pick += "\n  AND timestamp < ?"
                params.append(before)
            }
            pick += "\nORDER BY timestamp DESC\nLIMIT ?"
            params.append(scanLimit)
            sql = """
                SELECT \(columns)
                FROM transcript_lines t
                JOIN (\(pick)) AS pick ON pick.id = t.id
                LEFT JOIN sessions s ON s.session_id = t.session_id
                ORDER BY t.timestamp DESC
                """
        } else {
            var merged = """
                SELECT \(columns)
                FROM transcript_lines t INDEXED BY idx_transcript_lines_conversation
                LEFT JOIN sessions s ON s.session_id = t.session_id
                WHERE t.is_sidechain = 0
                  AND (t.entry_type = 'user' OR t.entry_type = 'assistant')
                  AND t.timestamp != ''
                """
            if let before, !before.isEmpty {
                merged += "\n  AND t.timestamp < ?"
                params.append(before)
            }
            merged += "\nORDER BY t.timestamp DESC\nLIMIT ?"
            params.append(scanLimit)
            sql = merged
        }

        // Prompts typed mid-turn are attachment rows, which the scans above
        // never reach (see migration044), so they come from their own table and
        // are woven into the timeline below. `limit` of them is as many as a
        // page can hold, since each yields at least one entry.
        //
        // Only their ids and times are read up front: most of them are older
        // than the page the scan fills and are never shown, and a line's
        // `raw_json` runs to tens of KB. The few that are woven in are fetched
        // whole, one primary-key read each, when they are reached.
        var queuedParams: [any Sendable] = []
        var queuedSQL = """
            SELECT q.line_id, q.timestamp
            FROM conversation_queued_prompts q
            JOIN transcript_lines t ON t.id = q.line_id
            WHERE q.timestamp != '' AND t.is_sidechain = 0
            """
        if let scoped {
            queuedSQL += "\n  AND q.session_id = ?"
            queuedParams.append(scoped)
        }
        if let before, !before.isEmpty {
            queuedSQL += "\n  AND q.timestamp < ?"
            queuedParams.append(before)
        }
        queuedSQL += "\nORDER BY q.timestamp DESC\nLIMIT ?"
        queuedParams.append(max(limit, 1))

        return try database.read { _ in
            var queued: [(lineId: Int, timestamp: String)] = []
            try database.query(queuedSQL, params: queuedParams) { row in
                queued.append((lineId: self.database.int(row, 0), timestamp: self.database.string(row, 1)))
            }

            var entries: [ConversationEntryDTO] = []
            var done = false
            func consume(_ feedRow: FeedRow) {
                guard !done else { return }
                let lines = self.extractCache.lines(
                    lineId: feedRow.id, rawJSON: feedRow.rawJSON
                )
                guard !lines.isEmpty else { return }

                let sessionId = feedRow.sessionId
                let timestamp = feedRow.timestamp
                // `project_root` is the enriched value and can still be empty on
                // a session the enricher hasn't reached; `cwd` is written at
                // session start and always there.
                let projectPath = feedRow.projectRoot.isEmpty ? feedRow.cwd : feedRow.projectRoot
                let projectName = projectPath.isEmpty
                    ? ""
                    : (projectPath as NSString).lastPathComponent
                // The title only. `summary` is the summarizer's running line
                // about what the session is *doing* ("writing
                // test_status_cmd.py"), and headed as a name it reads as one the
                // session was given — an unnamed session stays unnamed here.
                let sessionName = feedRow.title
                // One transcript entry can hold several blocks (a thinking block
                // and the text that followed it), so ids are suffixed to stay
                // unique — the window keys its rows on them.
                //
                // The index is taken BEFORE the work-output filter, so a block's
                // id is a property of the transcript rather than of the caller's
                // options: filtering first renumbered every line whenever the
                // window's "show work output" toggle moved, and the window saw
                // that as a feed full of brand-new rows.
                //
                // Emitted in reverse document order, because this whole result
                // is newest-first and the reader flips it to render oldest-at-
                // top: two reversals leave the blocks of one entry in the order
                // the model produced them.
                // The cap is on the OFFSET, so it is taken before the filter and
                // not after it. `prefix` after `filter` counts kept lines, and
                // the id is built from the offset: an entry whose thousandth
                // block is the fiftieth one this caller wants would keep an
                // offset of 1000+ and collide with the next entry's ids — the
                // exact collision the stride exists to prevent.
                let shown = Array(
                    lines
                        .enumerated()
                        .prefix(Self.maxLinesPerConversationEntry)
                        .filter { includeWorkOutput || !$0.element.kind.isWorkOutput }
                        .reversed()
                )
                guard !shown.isEmpty else { return }

                // Whole entries only. Pages are cut on `timestamp`, and every
                // block of one transcript entry carries the SAME timestamp — so
                // a page that stopped mid-entry didn't defer the rest, it lost
                // it: the next page asks for `timestamp < thatTimestamp`, which
                // excludes the entry it half-rendered. The one exception is an
                // entry bigger than `limit` all by itself, which is emitted
                // whole (a short overshoot) because otherwise it would wedge
                // paging at that point forever.
                if !entries.isEmpty, entries.count + shown.count > limit {
                    done = true
                    return
                }
                for (offset, line) in shown {
                    entries.append(ConversationEntryDTO(
                        id: feedRow.id * Self.maxLinesPerConversationEntry + offset,
                        sessionId: sessionId,
                        kind: line.kind.rawValue,
                        text: line.text,
                        timestamp: timestamp,
                        projectName: projectName,
                        gitBranch: feedRow.gitBranch,
                        sessionName: sessionName,
                        termProgram: feedRow.termProgram
                    ))
                }
                if entries.count >= limit { done = true }
            }
            func consumeQueued(_ lineId: Int) throws {
                guard !done else { return }
                try database.query("""
                    SELECT \(columns)
                    FROM transcript_lines t
                    LEFT JOIN sessions s ON s.session_id = t.session_id
                    WHERE t.id = ?
                    """, params: [lineId]) { row in
                    consume(FeedRow(row: row, reader: self.database))
                }
            }

            // Both lists are newest first, so the queued prompts newer than each
            // scanned row go in ahead of it. A scan that came back full stops
            // short of the older history, so the queued prompts older than its
            // last row wait for the next page, which starts from there. A scan
            // that came back short reached the start, so they all belong here.
            var next = 0
            var scanned = 0
            try database.query(sql, params: params) { row in
                guard !done else { return }
                scanned += 1
                let feedRow = FeedRow(row: row, reader: self.database)
                while next < queued.count, queued[next].timestamp > feedRow.timestamp {
                    try consumeQueued(queued[next].lineId)
                    next += 1
                }
                consume(feedRow)
            }
            if scanned < scanLimit {
                while next < queued.count, !done {
                    try consumeQueued(queued[next].lineId)
                    next += 1
                }
            }
            return entries
        }
    }

    /// One row of the Conversations feed's scans, read out of the shared column
    /// list both of them select.
    private struct FeedRow {
        let id: Int
        let sessionId: String
        let timestamp: String
        let rawJSON: String
        let projectRoot: String
        let cwd: String
        let gitBranch: String
        let title: String
        let termProgram: String

        init(row: Row, reader: DaemonDatabase) {
            id = reader.int(row, 0)
            sessionId = reader.string(row, 1)
            timestamp = reader.string(row, 2)
            rawJSON = reader.string(row, 3)
            projectRoot = reader.string(row, 4)
            cwd = reader.string(row, 5)
            gitBranch = reader.string(row, 6)
            title = reader.string(row, 7)
            termProgram = reader.string(row, 8)
        }
    }

    /// The id stride between two transcript entries, and therefore the cap on
    /// how many lines one entry may contribute.
    ///
    /// `id = transcript_lines.id * stride + blockIndex` only stays unique while
    /// `blockIndex < stride`; at the old stride of 100, an entry with 100 blocks
    /// produced ids that collided with the next entry's. A thousand is far past
    /// anything a real message holds, and lines beyond it are dropped rather
    /// than allowed to collide — a silently missing line is recoverable, two
    /// rows fighting over one identity in the window is not.
    private static let maxLinesPerConversationEntry = 1000
}
#endif
