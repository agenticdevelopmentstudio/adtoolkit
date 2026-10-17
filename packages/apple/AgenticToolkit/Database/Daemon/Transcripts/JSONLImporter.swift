#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Imports Claude Code's JSONL transcript history into a daemon's
/// event log + session_metrics table.
///
/// Flow per file:
/// 1. Resume at the file's stored byte offset (`transcript_file_cursors`) and
///    stream from there in bounded chunks — never the whole file at once. Each
///    chunk yields both the `[ParsedTurn]` metrics view and the verbatim
///    `[RawTranscriptLine]` view of the same lines, written in one transaction.
/// 2. Accumulate per-session session-stub stats only (cwd, model, git
///    branch, first/last timestamp) — NOT token totals or cost.
/// 3. For each turn, insert a synthetic event — `UserPromptSubmit` for
///    user turns, `PreToolUse` for assistant turns that call a tool —
///    keyed by `message_id` (or a synthetic id for user turns). Assistant
///    turns without tool calls produce no event. Every turn is persisted
///    to `transcript_turns`.
/// 4. Pass 2: materialize each touched session, then UPSERT its
///    `session_metrics` with totals (token sums + per-model cost)
///    recomputed from `transcript_turns`, not the in-memory accumulator.
///    Then upsert the run's subagent dispatches (keyed by `agent_id`) and
///    apply session titles — after the stubs exist, so a title can land on
///    a session created earlier in this same run.
///
/// Idempotent: re-running an import against the same JSONL files inserts
/// zero new events (dedup via `event_log.message_id` unique index) and
/// leaves `transcript_turns` / `agent_dispatches` unchanged (upserts write
/// back identical values). Existing `sessions` rows are never overwritten
/// (titles set only the migration034 title columns, never the summarizer's
/// `summary`).
public final class JSONLImporter {

    public struct Options: Sendable {
        public let since: Date?
        public let dryRun: Bool
        /// Maximum number of files to process in a single `run()` call.
        /// Nil = unbounded (a one-shot import drains in
        /// one pass). A periodic import sets this to its
        /// batch size (50 is typical) so the serial DB queue gets yielded
        /// between chunks and HTTP / other tasks aren't starved by a
        /// multi-file backlog.
        ///
        /// Chunking can't corrupt metrics regardless of how sessions map
        /// to files: pass 2 recomputes each touched session's totals from
        /// the persisted, deduplicated `transcript_turns` rows (see
        /// `sessionMetricsFromTranscriptTurns`), not from the current
        /// chunk's slice, so the REPLACE upsert always writes complete
        /// per-session totals.
        public let maxFiles: Int?

        /// Run against exactly these files instead of discovering every
        /// transcript under `sourceDirectory`.
        ///
        /// The periodic sweep learns what changed by walking the tree — 4,600
        /// files and climbing on this machine — because it has no other way to
        /// know. A hook does: it fires the moment a session writes, and its
        /// payload names the file. Handed that name, none of the walk is worth
        /// doing, and what is left is one `stat` and the file's new tail.
        ///
        /// Everything downstream is unchanged, which is the point of routing the
        /// fast path through the same importer rather than a second, lighter
        /// reader: the byte cursor, the per-line dedup, the synthesized events
        /// and the pass-2 metrics recompute all behave exactly as they do in a
        /// sweep, so whichever path reaches a line first, the other finds nothing
        /// left to do.
        ///
        /// Two things a scoped run must not do, both because this list is a
        /// couple of files rather than the tree: prune the cursor table (which
        /// would read the absence of every other file as "deleted"), and report a
        /// cutoff (which is a watermark for a walk that didn't happen).
        public let only: [URL]?

        /// Whether pass 2 recomputes each touched session's metrics.
        ///
        /// The recompute is a whole-session `GROUP BY model` over
        /// `transcript_turns` — 2.6M rows across the table, 40–50 ms for a
        /// session with tens of thousands of turns — and it costs the same
        /// whether the run added one line or a hundred thousand. A sweep pays
        /// it once per session per five minutes, which is what it was measured
        /// against. A tail runs once per quiet period for as long as a session
        /// keeps writing, and paying it there is hundreds of times the work to
        /// keep a token total nothing reads in real time a couple of seconds
        /// fresher.
        ///
        /// So the tail turns it off and runs it on a clock of its own
        /// (a live tail): the lines still land immediately, which is
        /// what a tail is for, and the totals are brought up to date when the
        /// session stops writing. Turning it off does **not** hand the work
        /// back to the sweep — the tail consumed the file's bytes, so the sweep
        /// finds it unchanged and passes over it.
        public let refreshesSessionMetrics: Bool

        public init(
            since: Date? = nil,
            dryRun: Bool = false,
            maxFiles: Int? = nil,
            only: [URL]? = nil,
            refreshesSessionMetrics: Bool = true
        ) {
            self.since = since
            self.dryRun = dryRun
            self.maxFiles = maxFiles
            self.only = only
            self.refreshesSessionMetrics = refreshesSessionMetrics
        }
    }

    /// Lines buffered before a write. Bounds the importer's peak memory to
    /// O(chunk + longest line) instead of O(file size), and makes each chunk one
    /// transaction rather than one per turn.
    private static let linesPerChunk = 500

    private let sourceDirectory: URL
    private let database: DaemonDatabase
    private let options: Options

    /// External callers that only have a request use `ImportCoordinator.run(_:openDatabase:)`.
    public init(sourceDirectory: URL, database: DaemonDatabase, options: Options = Options()) {
        self.sourceDirectory = sourceDirectory
        self.database = database
        self.options = options
    }

    public func run() throws -> ImportSummary {
        // Each file arrives already annotated with its mtime, read during the
        // directory walk — see `discoverFilesWithModificationDates` for why that
        // is not a separate `attributesOfItem` pass any more. Pre-filter by
        // `since` so the `maxFiles` budget counts only files we'll actually
        // process. Strict `>` (not `>=`): when the task saves the
        // latest-processed file's mtime as the next cutoff, that file is
        // excluded from the next chunk's scan.
        let discovered = options.only.map(Self.annotate(_:))
            ?? JSONLScanner.discoverFilesWithModificationDates(under: sourceDirectory)
        let annotated = discovered
            .filter { entry in
                guard let since = options.since else { return true }
                return entry.modified > since
            }
        // Process oldest-first so the saved cutoff advances monotonically;
        // a partial drain leaves later-mtime files for subsequent chunks.
        let eligibleFiles = annotated.sorted { $0.modified < $1.modified }

        let cap = options.maxFiles ?? Int.max
        var files = Array(eligibleFiles.prefix(cap))
        // Never split files that share the boundary mtime across a chunk
        // edge. The saved cutoff is mtime-based and the next chunk excludes
        // `mtime <= cutoff`, so any equal-mtime file left behind here would
        // be skipped permanently. Pull in every remaining file at the
        // boundary mtime even if that overruns `cap` — `maxFiles` is a
        // soft fairness budget, not a hard cap, and correctness wins over
        // a perfectly even batch.
        if let boundaryMTime = files.last?.modified {
            var index = files.count
            while index < eligibleFiles.count, eligibleFiles[index].modified == boundaryMTime {
                files.append(eligibleFiles[index])
                index += 1
            }
        }
        let hasMore = eligibleFiles.count > files.count

        // A file whose work errored must NOT be sealed behind the mtime cursor:
        // the next pass drops everything with `mtime <= since`, so advancing past
        // a failed file loses its lines and turns permanently. Track the earliest
        // failing mtime and stop the cursor short of it, so that file and every
        // later one is re-scanned next pass — free, because every insert on these
        // paths dedups. A permanently-failing file therefore parks the cursor and
        // keeps reporting itself, rather than silently swallowing a transcript.
        var earliestFailedMTime: Date?
        func noteFailure(at mtime: Date) {
            if let current = earliestFailedMTime, current <= mtime { return }
            earliestFailedMTime = mtime
        }

        var filesScanned = 0
        var turnsSeen = 0
        var eventsInserted = 0
        var eventsSkipped = 0
        var sessionsCreated = 0
        var sessionsTouched = 0
        var metricsUpserted = 0
        var linesSeen = 0
        var linesInserted = 0
        // Permanently-dropped undecodable lines. Deliberately NOT routed into
        // `errors`: an error parks the mtime cursor for a re-scan, and an
        // undecodable line is permanent, so that would re-read the file forever.
        var linesSkipped = 0
        // Bytes read vs bytes the cursors let us skip. The pair is the health
        // signal for this whole path: a steady state reads kilobytes and skips
        // gigabytes, and `bytesSkipped == 0` across scanned files means the
        // cursors are being rejected and every pass is re-reading from zero.
        var bytesRead: Int64 = 0
        var bytesSkipped: Int64 = 0
        var errors: [String] = []
        // Session titles harvested from custom-title / ai-title records.
        // One winner per session for this run: a custom title replaces
        // anything; an ai title never displaces a custom one (matching
        // claude-usage's precedence — the DB update enforces the same rule
        // against titles persisted by earlier runs).
        var titles: [String: JSONLScanner.ParsedTitle] = [:]
        // Subagent dispatches keyed by agent_id — last record wins, matching
        // claude-usage's `agents` accumulator.
        var dispatches: [String: JSONLScanner.AgentDispatch] = [:]

        // Reclaim cursors whose transcript is gone. `discovered` is the only
        // COMPLETE on-disk set in this method — `annotated`/`files` above are
        // already narrowed by `since` and `maxFiles`, and pruning against either
        // would delete cursors for live files and force a full re-read of every
        // file the narrowing excluded. Best-effort: a failure here costs a little
        // dead state, never the import, so it's reported and stepped over. Skipped
        // under `dryRun`, which promises to write nothing — and under `only`, where
        // `discovered` is the caller's short list rather than the on-disk set, so
        // pruning against it would read every file not named as deleted.
        if !options.dryRun, options.only == nil {
            do {
                try database.pruneTranscriptFileCursors(
                    existingPaths: Set(discovered.map(\.url.path)),
                    under: sourceDirectory.path
                )
            } catch {
                errors.append("cursor prune: \(error.localizedDescription)")
            }
        }

        // Per-session accumulator for the session stub (cwd/model/branch/
        // first+last timestamp) and the `turns > 0` materialize guard.
        // Token totals are NOT accumulated here — metrics are sourced from
        // the persisted transcript_turns in pass 2 so chunking can't clobber
        // them (see `sessionMetricsFromTranscriptTurns`).
        struct Bucket {
            var turns = 0
            var model = ""
            var firstTs = ""
            var lastTs = ""
            var cwd = ""
            var gitBranch = ""
        }
        var buckets: [String: Bucket] = [:]

        /// Folds a chunk of turns into `turnsSeen` and `buckets`, and its
        /// title / dispatch records into the run-scoped accumulators. Called
        /// only once the chunk is known to be durable (or in a dry run, where
        /// nothing is written at all) — see `flush()`. Titles and dispatches
        /// are staged for the same reason turns are: a rolled-back chunk must
        /// not seed pass 2 with records whose turns are not in the database.
        func accumulate(
            _ turns: [JSONLScanner.ParsedTurn],
            _ chunkTitles: [JSONLScanner.ParsedTitle] = [],
            _ chunkDispatches: [JSONLScanner.AgentDispatch] = []
        ) {
            for title in chunkTitles
            where title.source == .custom || titles[title.sessionId]?.source != .custom {
                titles[title.sessionId] = title
            }
            for dispatch in chunkDispatches {
                dispatches[dispatch.agentId] = dispatch
            }
            for turn in turns {
                turnsSeen += 1
                var bucket = buckets[turn.sessionId] ?? Bucket()
                bucket.turns += 1
                if !turn.model.isEmpty { bucket.model = turn.model }
                if !turn.cwd.isEmpty { bucket.cwd = turn.cwd }
                if !turn.gitBranch.isEmpty { bucket.gitBranch = turn.gitBranch }
                if bucket.firstTs.isEmpty
                    || (turn.timestamp < bucket.firstTs && !turn.timestamp.isEmpty) {
                    bucket.firstTs = turn.timestamp
                }
                if !turn.timestamp.isEmpty, turn.timestamp > bucket.lastTs {
                    bucket.lastTs = turn.timestamp
                }
                buckets[turn.sessionId] = bucket
            }
        }

        // Resolve each session's billed account ONCE per run and reuse it for
        // every row (event, turn, stub, metrics) belonging to that session —
        // rather than re-resolving per turn (an extra SELECT each time, and a
        // fallback that could drift mid-import if the global account changes
        // between turns). See `DaemonDatabase.resolvedAccountForSession`.
        var sessionAccounts: [String: String] = [:]
        func resolvedAccount(for sessionId: String) -> String {
            if let cached = sessionAccounts[sessionId] { return cached }
            let resolved = database.resolvedAccountForSession(sessionId)
            sessionAccounts[sessionId] = resolved
            return resolved
        }

        for (file, mtime) in files {
            // Mtime pre-filter already applied above when building `files`.
            filesScanned += 1
            let filePath = file.path
            let fileStem = file.deletingPathExtension().lastPathComponent

            // Where to resume. The mtime watermark only says a file CHANGED; the
            // per-file byte cursor says how much of it we already ingested, so a
            // live 180 MB transcript costs its new tail rather than a full re-read
            // (plus a re-hash and a dedup-index probe per line) every pass.
            //
            // Resume only when the file is the same file, unchanged at the head,
            // and no shorter than where we stopped. A compacted / rewritten /
            // replaced transcript fails that and is re-read from zero — exactly
            // the old behaviour, kept for the case where it actually matters.
            // Pooled: `attributesOfItem` returns an autoreleased dictionary of
            // autoreleased values, and this loop is synchronous with no suspension
            // point — so one per file stays live to the end of the run. That is the
            // same staircase `discoverFilesWithModificationDates` was rewritten to
            // avoid, and with `maxFiles` nil (a full import, not the 50-file
            // scheduled batch) this loop walks every transcript on the machine.
            //
            // A failed stat is a per-file error, not a `(0, 0)` default. Those
            // two numbers ARE the file's identity: inode 0 matches no cursor, so
            // the resume check fails and the file is re-read from byte zero — and
            // then the run stores `inode: 0` back, so the NEXT pass re-reads it
            // from zero too. One unlucky stat of a live 180 MB transcript quietly
            // costs two full re-reads. Skipping the file leaves the previous
            // cursor untouched and the watermark un-advanced, so the next pass
            // picks it up exactly where this one would have.
            let identity: (fileSize: Int64, inode: UInt64)? = autoreleasepool {
                guard let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
                      let size = (attributes[.size] as? NSNumber)?.int64Value,
                      let inode = (attributes[.systemFileNumber] as? NSNumber)?.uint64Value
                else { return nil }
                return (size, inode)
            }
            guard let (fileSize, inode) = identity else {
                errors.append("\(file.lastPathComponent): could not read file attributes")
                noteFailure(at: mtime)
                continue
            }

            var startOffset: Int64 = 0
            var lineNo = 0
            do {
                if let cursor = try database.transcriptFileCursor(for: filePath),
                   cursor.inode == inode,
                   fileSize >= cursor.byteOffset,
                   // Re-hash exactly the prefix the stored hash was taken over, so
                   // the check sees only bytes the cursor already covered.
                   cursor.headHash == (
                       try JSONLScanner.resumeFingerprint(at: file, upTo: cursor.byteOffset)
                   ) {
                    startOffset = cursor.byteOffset
                    lineNo = cursor.lineNo
                }
            } catch {
                errors.append("\(file.lastPathComponent): \(error.localizedDescription)")
                noteFailure(at: mtime)
                continue
            }
            let startLineNo = lineNo

            // Accumulate at most `linesPerChunk` lines before writing, so peak
            // memory is O(chunk), not O(file). Both the turns and the verbatim
            // lines of a chunk go in ONE transaction.
            var pendingLines: [JSONLScanner.RawTranscriptLine] = []
            var pendingTurns: [JSONLScanner.ParsedTurn] = []
            var pendingTitles: [JSONLScanner.ParsedTitle] = []
            var pendingDispatches: [JSONLScanner.AgentDispatch] = []
            // A property of the FILE, not of any line — the third subagent
            // marker, resolved once per file rather than per parsed line.
            let isSubagentFile = JSONLScanner.isSubagentPath(filePath)
            // A chunk write failure is reported by `flush()` appending to `errors`;
            // comparing the count around the file is how the cursor decision below
            // learns about it.
            let errorCountBeforeFile = errors.count

            func flush() {
                defer {
                    pendingLines.removeAll(keepingCapacity: true)
                    pendingTurns.removeAll(keepingCapacity: true)
                    pendingTitles.removeAll(keepingCapacity: true)
                    pendingDispatches.removeAll(keepingCapacity: true)
                }
                guard !pendingLines.isEmpty || !pendingTurns.isEmpty
                    || !pendingTitles.isEmpty || !pendingDispatches.isEmpty else { return }
                // A dry run writes nothing at all, so there is no rollback to
                // survive: the summary is a forecast, and it folds in every turn.
                guard !options.dryRun else {
                    return accumulate(pendingTurns, pendingTitles, pendingDispatches)
                }
                // Staged, not incremented in place: the closure below runs inside a
                // transaction that is rolled back WHOLE on any throw, but Swift locals
                // keep every increment made before it. Counting straight into the
                // summary therefore reported events that are not in the database —
                // wrong precisely when the write path is failing, which is the one
                // moment an operator reads these numbers.
                //
                // `turnsSeen` and `buckets` are staged for the same reason and were
                // NOT: they were folded in as each line parsed, so a rolled-back
                // chunk still counted its turns AND still seeded pass 2, which then
                // created a session stub for a session whose turns are not in the
                // database.
                var batchEventsInserted = 0
                var batchEventsSkipped = 0
                var batchLinesInserted = 0
                do {
                    try database.transaction {
                        for turn in pendingTurns {
                            var eventLogId: Int64?
                            if let result = try maybeInsertEvent(for: turn) {
                                if result.inserted { batchEventsInserted += 1 } else { batchEventsSkipped += 1 }
                                eventLogId = result.eventLogId
                            }
                            try database.insertTranscriptTurn(
                                sessionId: turn.sessionId,
                                timestamp: turn.timestamp,
                                kind: turn.kind.rawValue,
                                model: turn.model,
                                messageId: turn.messageId,
                                inputTokens: turn.inputTokens,
                                outputTokens: turn.outputTokens,
                                cacheReadTokens: turn.cacheReadTokens,
                                cacheCreationTokens: turn.cacheCreationTokens,
                                cacheCreation1hTokens: turn.cacheCreation1hTokens,
                                toolName: turn.toolName,
                                cwd: turn.cwd,
                                eventLogId: eventLogId,
                                accountEmail: resolvedAccount(for: turn.sessionId),
                                isSubagent: turn.isSubagent,
                                agentId: turn.agentId
                            )
                        }
                        batchLinesInserted = try database.insertTranscriptLines(
                            pendingLines, filePath: filePath
                        )
                    }
                    // Only now are these rows actually committed.
                    eventsInserted += batchEventsInserted
                    eventsSkipped += batchEventsSkipped
                    linesInserted += batchLinesInserted
                    accumulate(pendingTurns, pendingTitles, pendingDispatches)
                } catch {
                    // The whole chunk is rolled back together, so the staged counts
                    // are dropped with it. The byte cursor is not advanced for a
                    // failed file, so the next pass re-reads from the last good
                    // offset — free, because every insert on this path dedups.
                    errors.append("\(file.lastPathComponent): \(error.localizedDescription)")
                }
            }

            let streamed: JSONLScanner.StreamResult
            do {
                streamed = try JSONLScanner.streamCompleteLines(
                    at: file, startingAtByte: startOffset, linesPerChunk: Self.linesPerChunk
                ) { chunk in
                    // Drain the parse work per chunk. Both parse paths go through
                    // JSONSerialization, and this task runs synchronously with no
                    // suspension point of its own, so without an explicit pool the
                    // autoreleased Foundation objects for EVERY line of all 50
                    // files in a batch stay live to the end of the run. The scanner
                    // pools its own reads, so this nests inside that one — it covers
                    // the allocations this loop makes, which are not the scanner's to
                    // know about.
                    autoreleasepool {
                        for text in chunk {
                            lineNo += 1
                            // Every line is captured verbatim — summaries, system
                            // entries, malformed lines — not just the turns below.
                            pendingLines.append(
                                JSONLScanner.parseRawLine(text, lineNo: lineNo, fileStem: fileStem)
                            )

                            // Title / dispatch records are not turns and never
                            // reach `parse`. One guarded call covers both, and
                            // rejects the overwhelming majority of lines on a
                            // substring check before decoding any JSON.
                            let extras = JSONLScanner.parseExtras(text)
                            if let title = extras.title { pendingTitles.append(title) }
                            if let dispatch = extras.dispatch { pendingDispatches.append(dispatch) }

                            guard let turn = JSONLScanner.parse(
                                text, isSubagentFile: isSubagentFile
                            ) else { continue }
                            if let since = options.since,
                               let tsDate = TimestampParsing.parse(turn.timestamp),
                               tsDate < since {
                                continue
                            }
                            // Staged only — `flush()` folds these into `turnsSeen`
                            // and `buckets` once the chunk is committed.
                            pendingTurns.append(turn)
                        }
                        flush()
                    }
                }
            } catch {
                errors.append("\(file.lastPathComponent): \(error.localizedDescription)")
                noteFailure(at: mtime)
                continue
            }
            flush()
            linesSeen += streamed.linesEmitted
            linesSkipped += streamed.linesSkipped
            bytesRead += streamed.bytesConsumed - startOffset
            bytesSkipped += startOffset

            if errors.count > errorCountBeforeFile {
                noteFailure(at: mtime)
            } else if !options.dryRun {
                // Step the cursor only over what was actually ingested. Bytes of a
                // torn trailing entry are excluded from `bytesConsumed`, so the next
                // pass re-reads that line from the same offset. The stored hash is
                // taken over the prefix of that same region, which is what the resume
                // check above re-hashes.
                do {
                    try database.setTranscriptFileCursor(
                        DaemonDatabase.TranscriptFileCursor(
                            byteOffset: streamed.bytesConsumed,
                            lineNo: startLineNo + streamed.linesEmitted,
                            fileSize: fileSize,
                            inode: inode,
                            headHash: try JSONLScanner.resumeFingerprint(
                                at: file, upTo: streamed.bytesConsumed
                            )
                        ),
                        filePath: filePath
                    )
                } catch {
                    errors.append("\(file.lastPathComponent) (cursor): \(error.localizedDescription)")
                    noteFailure(at: mtime)
                }
            }
        }

        // Pass 2: materialize sessions + metrics from the buckets.
        for (sessionId, bucket) in buckets {
            guard !sessionId.isEmpty, bucket.turns > 0 else { continue }
            sessionsTouched += 1

            if !options.dryRun {
                do {
                    let created = try database.createSessionStubIfMissing(
                        sessionId: sessionId,
                        cwd: bucket.cwd,
                        model: bucket.model,
                        startedAt: bucket.firstTs,
                        lastActivityAt: bucket.lastTs,
                        gitBranch: bucket.gitBranch,
                        // Import-only sessions the live daemon never saw: attribute
                        // best-effort to the account resolved at import time (token if
                        // a prior hook stamped one, else the oauth login), tagged
                        // `unknown` because the import path can't tell contemporaneous
                        // from import-time. A later live token hook still heals it via
                        // the source-tagged upsert.
                        accountEmail: resolvedAccount(for: sessionId),
                        authMethod: "unknown"
                    )
                    if created { sessionsCreated += 1 }

                    // Source metrics from the persisted, deduplicated
                    // transcript_turns rather than this chunk's in-memory
                    // bucket: a session whose turns span multiple
                    // files/chunks — or a growing file re-scanned with a
                    // `since` turn-filter — must sum every turn, not just
                    // this slice, since the REPLACE upsert would otherwise
                    // clobber earlier totals.
                    if options.refreshesSessionMetrics,
                       let metrics = try database.sessionMetricsFromTranscriptTurns(sessionId: sessionId) {
                        try database.upsertSessionMetrics(
                            metrics, accountEmail: resolvedAccount(for: metrics.sessionId)
                        )
                        metricsUpserted += 1
                    }
                } catch {
                    errors.append("session materialize (\(sessionId)): \(error.localizedDescription)")
                }
            }
        }

        if !options.dryRun {
            // Subagent dispatches: keyed upserts, so a re-import (or a later
            // record for the same agent_id) refreshes rather than duplicates.
            for dispatch in dispatches.values {
                do {
                    try database.upsertAgentDispatch(
                        agentId: dispatch.agentId,
                        sessionId: dispatch.sessionId,
                        agentType: dispatch.agentType,
                        startedAt: dispatch.timestamp,
                        status: dispatch.status,
                        totalTokens: dispatch.totalTokens,
                        totalDurationMs: dispatch.totalDurationMs,
                        totalToolUseCount: dispatch.totalToolUseCount
                    )
                } catch {
                    errors.append("agent dispatch (\(dispatch.agentId)): \(error.localizedDescription)")
                }
            }

            // Session titles, after the stubs above exist. UPDATE-only: a
            // title whose session has no turns anywhere never materializes a
            // phantom row. custom-over-ai precedence is enforced both by the
            // accumulator (within this run) and by the UPDATE's guard
            // (against titles persisted by earlier runs).
            for (sessionId, title) in titles {
                do {
                    try database.updateSessionTranscriptTitle(
                        sessionId: sessionId,
                        title: title.title,
                        source: title.source.rawValue
                    )
                } catch {
                    errors.append("session title (\(sessionId)): \(error.localizedDescription)")
                }
            }
        }

        // Advance the cursor only as far as the newest file processed cleanly
        // *before* the earliest failure; nil (no such file) means "don't move
        // the cursor at all", so the whole batch is retried next pass.
        //
        // A scoped run reports none: its newest mtime is the newest of the two or
        // three files it was handed, and storing that as the sweep's watermark
        // would seal every older file that changed while it ran behind a cutoff no
        // walk ever justified.
        let cutoffMTime: Date?
        if options.only != nil {
            cutoffMTime = nil
        } else if let failed = earliestFailedMTime {
            cutoffMTime = files.last { $0.modified < failed }?.modified
        } else {
            cutoffMTime = files.last?.modified
        }

        let cutoffISO: String? = cutoffMTime.map { date in
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return fmt.string(from: date)
        }
        return ImportSummary(
            filesScanned: filesScanned,
            turnsSeen: turnsSeen,
            eventsInserted: eventsInserted,
            eventsSkipped: eventsSkipped,
            sessionsCreated: sessionsCreated,
            sessionsTouched: sessionsTouched,
            metricsUpserted: metricsUpserted,
            linesSeen: linesSeen,
            linesInserted: linesInserted,
            linesSkipped: linesSkipped,
            bytesRead: bytesRead,
            bytesSkipped: bytesSkipped,
            errors: errors,
            hasMore: hasMore,
            cutoffISO: cutoffISO
        )
    }

    /// The mtime pairing `run()` expects, for files it was handed rather than
    /// found. A file that has vanished between the hook firing and this stat is
    /// dropped: the sweep's own walk would not have returned it either, and the
    /// alternative — `.distantPast`, the walk's fallback for an unreadable
    /// date — is a real date that would sort ahead of live files and be reported
    /// as a cutoff. Sorted by path so a multi-file scoped run is ordered the same
    /// way a walk's results are.
    ///
    /// Each file is taken by its CANONICAL path, because the byte cursor is keyed
    /// by path string and both paths have to agree on that key or they stop
    /// sharing the cursor. `FileManager`'s enumerator hands the sweep a canonical
    /// path — `/private/var/…` where its own caller said `/var/…` — while a scoped
    /// run's URL is spelled however the hook payload spelled it. Two spellings are
    /// two cursor rows for one file, and a sweep re-reading from byte zero
    /// everything a tail already ingested. (Not `resolvingSymlinksInPath()`, which
    /// resolves the other way and *strips* a leading `/private`.)
    private static func annotate(_ urls: [URL]) -> [(url: URL, modified: Date)] {
        urls
            .compactMap { url -> (url: URL, modified: Date)? in
                guard let values = try? url.resourceValues(
                    forKeys: [.contentModificationDateKey, .canonicalPathKey]
                ),
                    let modified = values.contentModificationDate,
                    let canonical = values.canonicalPath
                else { return nil }
                return (URL(fileURLWithPath: canonical), modified)
            }
            .sorted { $0.url.path < $1.url.path }
    }

    // MARK: - Per-turn event synthesis

    /// One synthesized-event outcome: whether a new row was inserted, and
    /// (if so) its `event_log.id` so the matching `transcript_turns` row
    /// can be FK-linked.
    private struct EventOutcome {
        let inserted: Bool
        let eventLogId: Int64?
    }

    /// Synthesizes an event for this turn if appropriate. Returns:
    /// - `EventOutcome(inserted: true,  eventLogId: id)`  → new event row
    /// - `EventOutcome(inserted: false, eventLogId: nil)` → dedup hit
    /// - `nil`                                            → no event for this turn
    ///   (e.g. assistant turn with no tool call)
    private func maybeInsertEvent(for turn: JSONLScanner.ParsedTurn) throws -> EventOutcome? {
        switch turn.kind {
        case .user:
            // User turns have no message_id — synthesize one from session + timestamp
            // so re-imports dedup cleanly.
            let messageId = "user:\(turn.sessionId):\(turn.timestamp)"
            let detail = "" // JSONL doesn't include the prompt text without walking content blocks
            let id = try database.insertImportedEvent(
                eventType: "UserPromptSubmit",
                timestamp: turn.timestamp,
                sessionId: turn.sessionId,
                cwd: turn.cwd,
                detail: detail,
                messageId: messageId
            )
            return EventOutcome(inserted: id != nil, eventLogId: id)

        case .assistant:
            guard !turn.toolName.isEmpty else {
                return nil
            }
            let messageId = turn.messageId.isEmpty
                ? "asst:\(turn.sessionId):\(turn.timestamp):\(turn.toolName)"
                : turn.messageId
            let id = try database.insertImportedEvent(
                eventType: "PreToolUse",
                timestamp: turn.timestamp,
                sessionId: turn.sessionId,
                cwd: turn.cwd,
                detail: turn.toolName,
                messageId: messageId
            )
            return EventOutcome(inserted: id != nil, eventLogId: id)
        }
    }

    // MARK: - Helpers

    /// Convenience: default source directory — Claude Code's transcript root.
    public static var defaultSourceDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
    }
}
#endif
