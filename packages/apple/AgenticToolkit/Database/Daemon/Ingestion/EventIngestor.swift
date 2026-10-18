#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import OSLog

/// Ingests hook events into a session database: scans a drop directory, parses
/// each event file, writes it, publishes it through a ``SessionEventSink`` and
/// deletes the source file on success (moves it to `errors/` on failure).
///
/// It is transport- and trigger-neutral. A daemon decides what wakes it (a
/// directory watcher, a socket, a spool drain) and what carries the published
/// events (SSE, XPC, both); this type only ingests.
///
/// `@unchecked Sendable`: the only mutable state is `probedSessions`, guarded by
/// its lock, and the `ingestOverride` test seam, which is set before use.
public final class EventIngestor: @unchecked Sendable {
    private let dropDirectory: URL
    private let database: DaemonDatabase
    /// Where an ingested event and a session status change are published.
    private let sink: any SessionEventSink
    /// Owns the `errors/` quarantine directory: writes the `.meta.json` sidecar
    /// and the DB-log row for a quarantined file, so that schema lives in one
    /// place (here we only decide *what* to quarantine and move the file).
    private let quarantine: QuarantineService
    /// Runs when a session stops or ends, after its title and last output are
    /// refreshed. Nil when the daemon has nothing to do at that moment.
    private let summarizeOnStop: (@Sendable (String) async -> Void)?
    /// A short process-footprint suffix for the backfill log lines. A closure so
    /// this layer does not depend on how a daemon measures its own memory.
    private let footprintSuffix: @Sendable () -> String

    /// Keeps each writing session's transcript current in the database, off the
    /// ingestion path. Owned rather than injected: it holds only pacing state, and
    /// a handler that ingests events without one would leave the tables it feeds
    /// five minutes behind — which is a property of the daemon, not a choice a
    /// call site should get to make.
    private let transcriptTailer: TranscriptTailer
    /// Resumes each transcript's title scan where the last Stop left it.
    private let titleScanner = TranscriptTitleScanner()

    /// Test seam: when set, replaces the real `ingest` so tests can inject
    /// deterministic success / transient / permanent outcomes. Nil in production.
    public var ingestOverride: ((ParsedEvent) throws -> Void)?

    /// Sessions `healProjectRootIfNeeded` has already looked up, so the probe costs
    /// one DB read per session per daemon lifetime rather than one per event. Guarded
    /// by a lock because ingestion reaches this from the drop-directory scan *and*
    /// from the HTTP/XPC quarantine-retry path.
    private var probedSessions: Set<String> = []
    private let probedSessionsLock = NSLock()

    /// Sessions enriched per `stampSessionEnrichment` write in `runStartupBackfill`.
    /// Sized to be the loss ceiling for a restart mid-sweep (~a few seconds of
    /// enrichment) while keeping a first sweep of ~1,260 rows to a dozen-odd
    /// writer trips rather than one per row.
    private static let stampBatchSize = 100

    /// How long a session must have been inactive before an unreachable `cwd` is
    /// treated as gone for good rather than temporarily unmounted, and the row is
    /// stamped anyway. See `DaemonDatabase.stampSessionEnrichment`.
    private static let abandonedCwdDays = 30

    /// - Parameters:
    ///   - tailerQueueLabel: label of the queue the transcript tailer imports on,
    ///     so a daemon can put it under its own subsystem.
    ///   - summarizeOnStop: called with the session id after `Stop` / `SessionEnd`.
    ///   - footprintSuffix: appended to the backfill log lines; empty by default.
    public init(
        dropDirectory: URL,
        database: DaemonDatabase,
        sink: any SessionEventSink,
        quarantine: QuarantineService,
        tailerQueueLabel: String,
        summarizeOnStop: (@Sendable (String) async -> Void)? = nil,
        footprintSuffix: @escaping @Sendable () -> String = { "" }
    ) {
        self.dropDirectory = dropDirectory
        self.database = database
        self.sink = sink
        self.quarantine = quarantine
        self.summarizeOnStop = summarizeOnStop
        self.footprintSuffix = footprintSuffix
        self.transcriptTailer = TranscriptTailer(database: database, queueLabel: tailerQueueLabel)
    }

    // MARK: - Draining

    /// Processes every event file currently in the drop directory, oldest name first.
    public func drainDirectoryOnce() {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(
            at: dropDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let jsonFiles = entries
            .filter { $0.pathExtension == "json" && !$0.lastPathComponent.hasPrefix("error-") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        if !jsonFiles.isEmpty {
            logger.debug("Scan found \(jsonFiles.count) file(s) to process")
        }

        for fileURL in jsonFiles {
            // One pool per file. `attributesOfItem` and `processFile`'s
            // `Data(contentsOf:)` both return autoreleased objects, and this loop is
            // synchronous — the same shape that made the startup backfill peak at
            // 482 MB. Individual hook events are KB-sized, so this only bites on a
            // burst (a restart draining a backlogged drop directory), which is
            // precisely when the daemon is least able to absorb it.
            let skip: Bool = autoreleasepool {
                guard let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                      let created = attrs[.creationDate] as? Date else { return false }
                return Date().timeIntervalSince(created) < 0.1
            }
            if skip { continue }
            autoreleasepool { processFile(at: fileURL) }
        }
    }

    private func processFile(at url: URL) {
        let fileManager = FileManager.default
        guard let data = try? Data(contentsOf: url),
              let rawJson = String(data: data, encoding: .utf8) else {
            quarantine(url, parsed: nil, reason: "unreadable file", code: nil)
            return
        }

        switch Self.parseEventFile(rawJson: rawJson) {
        case .skip(let reason):
            // Well-formed event we intentionally don't track (e.g. a StatusLine
            // drop with no session_id). Discard it quietly — quarantining a
            // non-error would light the menubar error badge and, because every
            // retry re-parses to the same skip, exhaust the retry budget forever.
            logger.debug("Skipping untrackable \(url.lastPathComponent, privacy: .public): \(reason, privacy: .public)")
            try? fileManager.removeItem(at: url)

        case .lostEvent:
            // Nothing to ingest and nothing a retry could recover, so the file
            // goes — but the loss is real, so it is logged at error level and
            // written to the ingestion-error log as a terminal `lost` row. That
            // keeps it visible in `GET /ingestion/errors/log` without leaving a
            // quarantine file behind to light the menubar badge forever.
            quarantine.recordLostEvent(filename: url.lastPathComponent)
            try? fileManager.removeItem(at: url)

        case .unparseable:
            quarantine(url, parsed: nil, reason: "unparseable event JSON", code: nil)

        case .event(let parsed):
            do {
                try ingestWithRetry(parsed)
                try? fileManager.removeItem(at: url)
            } catch let dbErr as DaemonDatabaseError where dbErr.isTransient {
                // Transient DB error (BUSY/LOCKED/IOERR) — the daemon is typically
                // wedged or contended. Leave the file in place so a later scan (or
                // the next daemon start) retries it; never quarantine recoverable data.
                logger.warning(
                    "Transient ingest error for \(url.lastPathComponent, privacy: .public); leaving for retry"
                )
            } catch {
                let name = url.lastPathComponent
                let desc = error.localizedDescription
                logger.error("Ingest failed for \(name, privacy: .public): \(desc, privacy: .public)")
                quarantine(url, parsed: parsed, reason: desc, code: (error as? DaemonDatabaseError)?.sqliteCode)
            }
        }
    }

    /// Ingests with a short bounded retry for transient DB errors. Permanent
    /// errors propagate immediately. If still transient after the last attempt,
    /// the transient error propagates so the caller leaves the file for retry.
    private func ingestWithRetry(_ parsed: ParsedEvent) throws {
        let maxAttempts = 3
        var attempt = 1
        while true {
            do {
                if let ingestOverride { try ingestOverride(parsed) } else { try ingest(parsed) }
                return
            } catch let dbErr as DaemonDatabaseError where dbErr.isTransient && attempt < maxAttempts {
                attempt += 1
                usleep(50_000)  // 50ms backoff before retrying transient contention
            }
        }
    }

    /// Ingests an already-parsed event: writes to the DB, publishes it through the
    /// sink, schedules enrichment. Shared by the directory scanner (drop files),
    /// the spool drain and the quarantine retry.
    public func ingest(_ parsed: ParsedEvent) throws {
        let ingested = try database.ingestEvent(
            eventType: parsed.eventType,
            timestamp: parsed.timestamp,
            hookData: parsed.hookData,
            context: parsed.context,
            accountEmail: parsed.accountEmail,
            oauthAccountEmail: parsed.oauthAccountEmail
        )
        logger.debug("Ingested \(parsed.eventType, privacy: .public) for \(ingested.sessionId, privacy: .public)")
        broadcastIngestedEvent(ingested)
        scheduleEnrichmentIfNeeded(for: parsed, sessionId: ingested.sessionId, cwd: ingested.cwd)
    }

    /// Ingests a whole batch in ONE database transaction, for `IngestDrainer`.
    ///
    /// The spool exists so that a burst of hook deliveries doesn't become a burst
    /// of write-lane trips: draining fifty events one at a time is fifty separate
    /// transactions through the single writer, each competing with the reads that
    /// are serving the app. One transaction is one trip.
    ///
    /// Atomicity is what makes the drainer's retry safe: if any event throws, the
    /// whole transaction rolls back, so re-running the batch cannot double-write
    /// the events that had already succeeded. Nothing is broadcast until the
    /// commit returns, for the same reason — announcing a row that a rollback
    /// then erased would put a session in the app's live feed that isn't in the
    /// database behind it.
    public func ingestBatch(_ events: [ParsedEvent]) throws {
        guard !events.isEmpty else { return }
        // The test seam replaces ingestion wholesale, so there is no real write to
        // wrap; honouring it here keeps a test's injected outcomes meaningful on
        // the drain path too.
        if let ingestOverride {
            for event in events { try ingestOverride(event) }
            return
        }

        var ingested: [(ParsedEvent, IngestedEvent)] = []
        ingested.reserveCapacity(events.count)
        // Resolve the oauth fallback BEFORE the transaction opens. `currentEmail()`
        // stats — and on a change re-parses — `~/.claude.json`, and inside the
        // transaction that is one filesystem round-trip per event with the single
        // writer held against every read the app is making. Only envelopes older
        // than `oauth_account_email` need it at all; the rest carry the answer
        // resolved when their hook fired, so on a live daemon this is nil.
        let oauthFallback: String? = events.contains { $0.oauthAccountEmail == nil }
            ? database.currentAccountEmail
            : nil
        try database.transaction {
            for event in events {
                let row = try database.ingestEvent(
                    eventType: event.eventType,
                    timestamp: event.timestamp,
                    hookData: event.hookData,
                    context: event.context,
                    accountEmail: event.accountEmail,
                    oauthAccountEmail: event.oauthAccountEmail ?? oauthFallback
                )
                ingested.append((event, row))
            }
        }

        logger.debug("Ingested batch of \(ingested.count) event(s)")
        for (event, row) in ingested {
            broadcastIngestedEvent(row)
            scheduleEnrichmentIfNeeded(for: event, sessionId: row.sessionId, cwd: row.cwd)
        }
    }

    private func broadcastIngestedEvent(_ event: IngestedEvent) {
        // Encoded here, once, and the same bytes go to the sink — so every daemon
        // publishes identical payloads and no transport serializes the event twice
        // on the ingest hot path.
        guard let payload = SessionEventEncoding.encode(event) else {
            logger.debug("broadcast encode failed for \(event.event, privacy: .public)")
            return
        }
        sink.broadcast(eventType: event.event, payload: payload, sessionId: event.sessionId)
    }

    /// Publishes a session status change (ended / stale) through the sink. Called
    /// when a session's liveness changes outside any hook event.
    public func broadcastSessionStatus(sessionId: String, status: SessionStatus) {
        sink.broadcastSessionStatus(sessionId: sessionId, status: status)
    }

    /// Schedules session-metadata enrichment off the ingestion path so
    /// the scan loop isn't blocked by git/subprocess/file I/O. Only
    /// SessionStart triggers a full enrichment (branch + title); Stop /
    /// SessionEnd just refresh the title since it can change mid-session.
    ///
    /// Every event, whatever its type, additionally gets the healing probe below
    /// and a transcript tail.
    private func scheduleEnrichmentIfNeeded(for event: ParsedEvent, sessionId: String, cwd: String) {
        let transcriptPath = event.hookData["transcript_path"] as? String
        let database = self.database
        let summarizeOnStop = self.summarizeOnStop

        healProjectRootIfNeeded(sessionId: sessionId)

        // A hook firing means the session just wrote to its transcript, and the
        // payload says which file. That is the whole signal the five-minute sweep
        // re-walks the tree to reconstruct, so hand it straight to the tailer:
        // every event type, because every one of them is a line being written,
        // and the tailer is what decides how often a given file is worth reading.
        if let transcriptPath {
            let tailer = self.transcriptTailer
            Task { await tailer.noteActivity(transcriptPath: transcriptPath, sessionId: sessionId) }
        }

        switch event.eventType {
        case "SessionStart":
            Task.detached {
                SessionEnricher.enrich(
                    sessionId: sessionId,
                    cwd: cwd,
                    // Force a fresh project_root at session start (cwd is authoritative
                    // then); it's a single session, so the recompute cost is trivial.
                    projectRootVersion: 0,
                    // The hook fired for this session just now, so the file is the
                    // only source that can be current — the importer may not have
                    // reached it yet. One session, so the scan cost is trivial.
                    titleSource: .transcriptFile(path: transcriptPath),
                    database: database
                )
            }
        case "Stop", "SessionEnd":
            Task.detached {
                let path = transcriptPath ?? SessionEnricher.findTranscriptPath(sessionId: sessionId)
                guard let path else { return }
                if let title = self.titleScanner.title(path: path), !title.isEmpty {
                    try? database.updateSessionTranscriptTitle(
                        sessionId: sessionId, title: title, source: "custom"
                    )
                }
                // Stop fires the instant the agent finishes speaking, which is the
                // only moment its last reply is knowable: no hook payload carries
                // the text, and the JSONL importer is five minutes behind.
                SessionEnricher.refreshLastOutput(
                    sessionId: sessionId, transcriptPath: path, database: database
                )
                await summarizeOnStop?(sessionId)
            }
        default:
            break
        }
    }

    /// Gives a session its `project_root` as soon as any event arrives for it, rather
    /// than only at `SessionStart`.
    ///
    /// A session whose `SessionStart` this daemon never saw — it was already running
    /// when the daemon started, or the hooks were installed mid-session — stays at
    /// `project_root_version = 0` with no root, and the only thing that ever filled
    /// one in was the *startup* backfill. So a live session could sit in the Sessions
    /// window for its whole life labelled with its `cwd`'s last path component and
    /// grouped alone: two worktrees of one project showed up as two projects, each
    /// named after the worktree directory rather than the project.
    ///
    /// Bounded by `probedSessions`: one DB read per session per daemon lifetime, not
    /// one per event. A session that comes back `.undetermined` (git wouldn't answer)
    /// is not retried until the next launch — the same terms as every other enrichment
    /// retry, and the alternative is re-running `git` for every event of a session
    /// whose repository is simply unhealthy.
    ///
    /// Takes no `cwd`: the directory to repair from is the session's own, and that is
    /// read back from the row alongside the version.
    private func healProjectRootIfNeeded(sessionId: String) {
        probedSessionsLock.lock()
        let alreadyProbed = !probedSessions.insert(sessionId).inserted
        probedSessionsLock.unlock()
        guard !alreadyProbed else { return }

        let database = self.database
        Task.detached {
            // No row (or an unreadable DB) means the probe learned nothing, so re-open
            // it rather than spending the session's one chance on a non-answer.
            // `try?` flattens the throw and the missing row into one nil, and both
            // mean the same thing here: nothing was learned.
            guard let stored = try? database.sessionProjectRootProbe(sessionId: sessionId) else {
                self.reopenProbe(sessionId: sessionId)
                return
            }
            guard stored.version < SessionEnricher.projectRootAlgoVersion,
                  !stored.cwd.isEmpty else { return }
            SessionEnricher.enrich(
                sessionId: sessionId,
                // The session's OWN cwd, read back from the row — never the `cwd` of
                // the hook that triggered this. The session cwd is frozen on purpose;
                // the hook's is wherever the agent's shell happens to be standing, and
                // `enrich` derives `git_branch` from what it is handed. Passing the
                // hook's meant one `cd ../sibling-repo` stamped that repo's branch onto
                // this session — permanently, since the write is unguarded and this
                // probe never runs twice.
                cwd: stored.cwd,
                projectRootVersion: stored.version,
                // The importer has this session's lines or it doesn't; either way this
                // is a repair pass, not a live-title refresh, so it must not burn a
                // full transcript scan.
                titleSource: .importedLines,
                database: database
            )
        }
    }

    /// Lets `healProjectRootIfNeeded` probe `sessionId` again on a later event.
    private func reopenProbe(sessionId: String) {
        probedSessionsLock.lock()
        probedSessions.remove(sessionId)
        probedSessionsLock.unlock()
    }

    /// On daemon start, gives every session the Sessions window can show a
    /// `last_output` if it lacks one, read from the tail of its transcript.
    ///
    /// The `Stop` hook is the only other writer, so without this a session already
    /// running when the daemon started shows "No output yet." until the agent next
    /// finishes a turn — and an idle session never does. Separate from
    /// `runStartupBackfill` because that pass is stamped once per session and this
    /// one must look again at a live session on every launch. Each session costs a
    /// bounded tail read (`SessionEnricher.tailByteWindow`), not a transcript scan.
    public func runLastOutputBackfill() {
        let database = self.database
        Task.detached {
            guard let sessionIds = try? database.sessionIdsMissingLastOutput() else { return }
            for sessionId in sessionIds {
                autoreleasepool {
                    SessionEnricher.refreshLastOutput(
                        sessionId: sessionId, transcriptPath: nil, database: database
                    )
                }
            }
            Self.logger.notice("last_output backfill: \(sessionIds.count) session(s) examined")
        }
    }

    /// On daemon start, scans for existing sessions that are missing a
    /// git branch or summary and enriches them in the background. Safe
    /// to run even when all sessions are already populated — it's just
    /// a no-op pass.
    public func runStartupBackfill() {
        let database = self.database
        let footprintSuffix = self.footprintSuffix
        Task.detached {
            guard let rows = try? database.sessionsNeedingEnrichment(
                currentProjectRootVersion: SessionEnricher.projectRootAlgoVersion,
                currentEnrichmentVersion: SessionEnricher.enrichmentAlgoVersion
            ) else { return }
            // `.notice`, not `.info`: this pass is the daemon's largest startup
            // allocation, and `.info` lives only in the memory-backed log ring —
            // which this process's Network.framework chatter wraps within minutes,
            // so these two lines were already gone by the time a boot was over.
            Self.logger.notice(
                "SessionEnricher backfill: \(rows.count) session(s) \(footprintSuffix(), privacy: .public)"
            )
            // Batched rather than one UPDATE per session: a first sweep stamps
            // ~1,260 rows, and per-row writes are that many separate trips through
            // the single writer, each with its own transaction, competing with
            // ingest on the startup path.
            //
            // Batched, though, NOT deferred to the end. The enrichment itself is
            // the expensive part (a `git` subprocess and a title lookup per row,
            // ~55 s for a first sweep), and holding every stamp until it finishes
            // means a daemon restart — or a crash — inside that window discards
            // the record of ALL of it and re-runs the whole pass from scratch.
            // Flushing every `stampBatchSize` rows caps what a restart can lose at
            // one batch while keeping the writer trips proportional to
            // rows/batch rather than rows.
            var stampable: [String] = []
            // Sessions whose cwd wasn't on disk. Stamped too, but only once the row
            // has been inactive for `abandonedCwdDays` — see `stampSessionEnrichment`
            // for why a permanently-deleted directory otherwise re-enriches forever.
            var unreachable: [String] = []
            var stampedCount = 0
            func flushStamps() {
                if !stampable.isEmpty {
                    database.stampSessionEnrichment(
                        version: SessionEnricher.enrichmentAlgoVersion,
                        sessionIds: stampable
                    )
                    stampedCount += stampable.count
                    stampable.removeAll(keepingCapacity: true)
                }
                if !unreachable.isEmpty {
                    database.stampSessionEnrichment(
                        version: SessionEnricher.enrichmentAlgoVersion,
                        sessionIds: unreachable,
                        onlyInactiveForDays: Self.abandonedCwdDays
                    )
                    unreachable.removeAll(keepingCapacity: true)
                }
            }
            for row in rows {
                // One pool per session. This loop is synchronous with no suspension
                // point, so without it NOTHING autoreleased here drains until the
                // whole backfill returns — every transcript buffer and every `git`
                // subprocess's Pipe/Data for all ~1,300 rows stays live at once.
                // That was the daemon's startup peak: a monotone staircase from
                // 32 MB to 482 MB over 55 s, then one cliff back down when this
                // task finally unwound.
                let outcome = autoreleasepool {
                    SessionEnricher.enrich(
                        sessionId: row.sessionId,
                        cwd: row.cwd,
                        projectRootVersion: row.projectRootVersion,
                        // The DB already holds every line of these transcripts, and
                        // re-streaming them here was 40 MB of the daemon's startup
                        // peak — see `DaemonDatabase.latestCustomTitle`.
                        titleSource: .importedLines,
                        database: database
                    )
                }
                // Stamp when enrichment actually looked: "we looked and there was
                // nothing" is the case the value columns can't express, and it's the
                // one that made this pass repeat forever. `.inputsUnavailable` is the
                // opposite case — the cwd wasn't on disk, so nothing was looked at,
                // and stamping would permanently retire a row that a remount fixes,
                // so it takes the age-gated stamp instead of this one.
                // Only ended sessions take the stamp — see `stampSessionEnrichment`.
                switch outcome {
                case .complete: stampable.append(row.sessionId)
                case .inputsUnavailable: unreachable.append(row.sessionId)
                }
                if stampable.count >= Self.stampBatchSize
                    || unreachable.count >= Self.stampBatchSize { flushStamps() }
            }
            flushStamps()
            Self.logger.notice("""
                SessionEnricher backfill done — \(rows.count) session(s) \
                stamped=\(stampedCount) \(footprintSuffix(), privacy: .public)
                """)
        }
    }

    /// Moves a file that could not be ingested into the quarantine's errors directory and writes a
    /// sibling `<name>.meta.json` recording why, so the failure is inspectable
    /// (and recoverable) via the Ingestion Errors surface instead of vanishing
    /// into the log. Reserved for permanent failures — transient errors are
    /// left in place for retry, never quarantined.
    private func quarantine(_ url: URL, parsed: ParsedEvent?, reason: String, code: Int32?) {
        let errDir = self.quarantine.errorsDirectory
        let dest = errDir.appendingPathComponent("error-\(url.lastPathComponent)")
        do {
            try FileManager.default.createDirectory(at: errDir, withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: url, to: dest)
        } catch {
            // The move failed (e.g. errors/ uncreatable). Don't write an orphaned
            // meta sidecar for a file that isn't there; leave the source in the
            // drop dir so the next scan retries it.
            let desc = error.localizedDescription
            logger.error("Could not quarantine \(url.lastPathComponent, privacy: .public): \(desc, privacy: .public)")
            return
        }

        // The file is now in errors/; QuarantineService owns the sidecar + DB-log
        // write (and logs the quarantine), keeping that schema in one place.
        quarantine.recordInitialQuarantine(eventURL: dest, reason: reason, code: code, parsed: parsed)
    }

    // MARK: - Parsing

    /// Parses the envelope format:
    /// `{"event": "PreToolUse", "timestamp": "...", "hook_data": {...}, "context": {...}}`
    /// `context` is optional — present in v5+ drops, absent in legacy v4 drops or
    /// hand-crafted test fixtures.
    public static func parseEventFile(rawJson: String) -> ParseResult {
        ParseResult.parse(envelopeJSON: rawJson)
    }
}

extension EventIngestor: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
