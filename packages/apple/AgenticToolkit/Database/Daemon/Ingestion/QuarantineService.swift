#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import OSLog

/// Owns the ingestion `errors/` directory: lists quarantined events (with their
/// `.meta.json` reasons + retry counts), counts them for the menubar badge,
/// self-heals by retrying them through a supplied ingest closure, mirrors every
/// failure into the DB log, and clears the directory. The single source of truth
/// behind both the XPC and HTTP ingestion-error surfaces.
///
/// Retry budget: each failed retry bumps the file's `retryCount`; once it
/// reaches `maxRetries` the file is "exhausted" — the periodic batch stops
/// retrying it and the menubar badge lights (only exhausted files alert). A
/// manual "Retry All" force-retries everything, exhausted included.
public final class QuarantineService: @unchecked Sendable {
    private let errorsDirectory: URL
    /// Persistent error log mirror. Optional so tests can construct the service
    /// without a database; DB writes become no-ops when nil.
    private let database: DaemonDatabase?
    /// Retries a file may survive before it's considered exhausted.
    private let maxRetries: Int

    /// Serializes the background "Retry All" batch off the XPC/HTTP reply thread.
    private let retryQueue: DispatchQueue
    /// Guards the retry-progress counters below and the `running` mutex shared by
    /// the manual ("Retry All") and automatic (periodic) batches, so the two can
    /// never run over the same files at once.
    private let lock = NSLock()
    private var running = false
    private var total = 0
    private var processed = 0
    private var recovered = 0
    private var stillFailing = 0

    /// Outcome of re-feeding one quarantined file.
    private enum RetryOutcome { case recovered, stillFailing, vanished }

    /// - Parameter queueLabel: label of the background retry queue, so a daemon
    ///   can put it under its own subsystem.
    public init(
        errorsDirectory: URL,
        database: DaemonDatabase? = nil,
        maxRetries: Int = 3,
        queueLabel: String = "quarantine-retry"
    ) {
        self.errorsDirectory = errorsDirectory
        self.database = database
        // Clamp to ≥1 so a misconfigured 0 can't instantly "exhaust" every file
        // (lighting the badge and disabling auto-retry before a single attempt).
        self.maxRetries = max(1, maxRetries)
        self.retryQueue = DispatchQueue(label: queueLabel)
    }

    /// Number of quarantined event files (excludes `.meta.json` sidecars).
    public func count() -> Int {
        eventFiles().count
    }

    /// Number of quarantined events that have used up their retry budget
    /// (`retryCount >= maxRetries`). Drives the menubar alert badge — only
    /// exhausted failures are surfaced as an alert.
    public func exhaustedCount() -> Int {
        eventFiles().reduce(0) { acc, url in
            acc + ((readMeta(for: url)?.retryCount ?? 0) >= maxRetries ? 1 : 0)
        }
    }

    /// Total + exhausted counts in a single directory scan / sidecar pass — for
    /// the badge endpoint, which is polled every few seconds. Cheaper than
    /// calling `count()` and `exhaustedCount()` separately (two scans + a second
    /// sidecar pass).
    public func counts() -> (total: Int, exhausted: Int) {
        let files = eventFiles()
        let exhausted = files.reduce(0) { acc, url in
            acc + ((readMeta(for: url)?.retryCount ?? 0) >= maxRetries ? 1 : 0)
        }
        return (files.count, exhausted)
    }

    /// All quarantined events as DTOs, newest first. Reads each file's meta
    /// sidecar for the reason + retry count, falling back to a placeholder for
    /// legacy files.
    public func list() -> [IngestionErrorDTO] {
        eventFiles().map { url in
            if let meta = readMeta(for: url) {
                return IngestionErrorDTO(
                    filename: url.lastPathComponent,
                    eventType: meta.eventType,
                    sessionId: meta.sessionId,
                    quarantinedAt: meta.quarantinedAt,
                    reason: meta.reason,
                    retryCount: meta.retryCount,
                    lastRetriedAt: meta.lastRetriedAt,
                    exhausted: meta.isExhausted(maxRetries: maxRetries)
                )
            }
            let (eventType, sessionId) = peek(url)
            return IngestionErrorDTO(
                filename: url.lastPathComponent,
                eventType: eventType,
                sessionId: sessionId,
                quarantinedAt: modifiedAt(url),
                reason: "unknown (quarantined before reason capture)"
            )
        }
        .sorted { $0.quarantinedAt > $1.quarantinedAt }
    }

    /// Deletes every quarantined event file and meta sidecar, and marks the
    /// corresponding DB-log rows cleared (keeping their history for tracking).
    public func clear() {
        let fileManager = FileManager.default
        let entries = (try? fileManager.contentsOfDirectory(
            at: errorsDirectory, includingPropertiesForKeys: nil
        )) ?? []
        for url in entries {
            try? fileManager.removeItem(at: url)
        }
        do {
            try database?.clearActiveIngestionErrors()
        } catch {
            // Surface rather than swallow: the on-disk files are gone but the log
            // rows would otherwise stay "failing"/"exhausted" until the next pass.
            logger.warning(
                "Failed to mark ingestion-error log rows cleared: \(error.localizedDescription, privacy: .public)"
            )
        }
        logger.info("Cleared \(entries.count, privacy: .public) quarantine entr(ies)")
    }

    /// Records a freshly-quarantined event: writes its `.meta.json` sidecar and
    /// mirrors the row into the DB log. Called by the ingestor right after
    /// it moves a permanently-failed event into `errors/`, so the sidecar +
    /// DB-log writes (and their timestamp format) live in exactly one place
    /// rather than being duplicated at the quarantine site.
    ///
    /// `retryCount` is the number of ingest attempts the event has **already**
    /// spent before arriving here, and defaults to 0 — the drop-file path, where
    /// quarantine is the first failure. `IngestDrainer` passes the attempts the
    /// spool charged it, because those were real ingest attempts against the
    /// same database with the same permanent error: counting them from zero
    /// again would hide a doomed event from the badge (which only alerts on
    /// exhausted) and hand the auto-retry three more passes to rediscover what
    /// five already established.
    public func recordInitialQuarantine(
        eventURL: URL, reason: String, code: Int32?, parsed: ParsedEvent?, retryCount: Int = 0
    ) {
        let eventType = parsed?.eventType ?? ""
        let sessionId = (parsed?.hookData["session_id"] as? String) ?? ""
        let now = Self.iso8601.string(from: Date())
        let spent = max(0, retryCount)
        QuarantineMeta(
            reason: reason,
            sqliteCode: code.map(Int.init),
            quarantinedAt: now,
            eventType: eventType,
            sessionId: sessionId,
            retryCount: spent
        ).writeSidecar(for: eventURL)
        try? database?.recordIngestionError(
            filename: eventURL.lastPathComponent,
            eventType: eventType,
            sessionId: sessionId,
            reason: reason,
            sqliteCode: code.map(Int.init),
            quarantinedAt: now,
            retryCount: spent,
            lastRetriedAt: nil,
            // Derived here, not passed in: `maxRetries` is this type's budget,
            // and the two surfaces that read exhaustion (the sidecar via
            // `isExhausted`, the DB log via this flag) must never disagree.
            exhausted: spent >= maxRetries
        )
        logger.warning("Quarantined \(eventURL.lastPathComponent, privacy: .public): \(reason, privacy: .public)")
    }

    /// Reason text for an empty drop file, shared by the live scan and the retry
    /// path so the log reads the same whichever noticed it first.
    static let lostEventReason = "empty drop file — the event was lost before it was written"

    /// Logs a drop file that arrived empty. The file carries no event and no
    /// retry can conjure one, so it is never quarantined: this writes a terminal
    /// `lost` row to the ingestion-error log and nothing else. The loss stays
    /// visible in `GET /ingestion/errors/log` while the menubar badge — which
    /// counts exhausted quarantine *files* — stays dark.
    public func recordLostEvent(filename: String) {
        try? database?.recordLostIngestionEvent(
            filename: filename, detectedAt: Self.iso8601.string(from: Date())
        )
        logger.error("Lost event in \(filename, privacy: .public): \(Self.lostEventReason, privacy: .public)")
    }

    /// Starts re-feeding **every** quarantined event (exhausted included — this is
    /// the user-driven force retry) through `parse` + `ingest` on a background
    /// queue, returning a snapshot of the now-running progress. The batch runs off
    /// the caller's thread so a large backlog never times out the XPC/HTTP reply.
    /// Idempotent: if a batch is already running (manual or automatic) this is a
    /// no-op that returns the live progress.
    @discardableResult
    public func startRetry(
        parse: @escaping @Sendable (String) -> ParseResult,
        ingest: @escaping @Sendable (ParsedEvent) throws -> Void
    ) -> RetryProgressDTO {
        let files = eventFiles()
        let started: Bool = lock.withLock {
            if running { return false }
            running = true
            total = files.count
            processed = 0
            recovered = 0
            stillFailing = 0
            return true
        }
        guard started else { return retryProgress() }

        retryQueue.async { [weak self] in
            guard let self else { return }
            for url in files {
                // One pool per file. This loop is synchronous with no suspension
                // point, and `retryOne` reads the file with `String(contentsOf:)`,
                // so without a pool every file's buffer stays live until the whole
                // backlog finishes — the same shape as the startup-backfill and
                // importer bugs. `files` is the entire quarantine directory with no
                // cap, and this is user-triggered ("Retry All"), so the backlog size
                // is exactly what it costs.
                let outcome = autoreleasepool {
                    self.retryOne(url, parse: parse, ingest: ingest)
                }
                self.lock.withLock {
                    self.processed += 1
                    switch outcome {
                    case .recovered: self.recovered += 1
                    case .stillFailing: self.stillFailing += 1
                    case .vanished: break  // cleared/removed elsewhere — neither recovered nor failing
                    }
                }
            }
            self.lock.withLock { self.running = false }
        }
        return retryProgress()
    }

    /// Self-healing periodic batch: retries up to `limit` **non-exhausted**
    /// quarantined files, least-recently-attempted first, through the same
    /// parse+ingest path as the manual batch. Runs synchronously on the caller
    /// (the scheduler's detached task) in a small bounded batch so it never holds
    /// up live ingestion. Mutually exclusive with a running manual batch (returns
    /// zeros, leaving the work for the next interval). It populates the same
    /// progress counters as `startRetry`, so `retryProgress()` stays truthful
    /// while a periodic batch runs. `remaining` is how many non-exhausted files
    /// were left unattempted by this (limit-bounded) batch.
    @discardableResult
    public func retryDueBatch(
        limit: Int,
        parse: (String) -> ParseResult,
        ingest: (ParsedEvent) throws -> Void
    ) -> (recovered: Int, stillFailing: Int, remaining: Int) {
        let claimed: Bool = lock.withLock {
            if running { return false }
            running = true
            return true
        }
        // A manual "Retry All" is in flight — leave this cycle to the next tick.
        guard claimed else { return (0, 0, 0) }
        defer { lock.withLock { running = false } }

        let due = dueFiles()  // single scan; reused for the batch and `remaining`
        let batch = Array(due.prefix(limit))
        lock.withLock {
            total = batch.count
            processed = 0
            recovered = 0
            stillFailing = 0
        }
        for url in batch {
            let outcome = retryOne(url, parse: parse, ingest: ingest)
            lock.withLock {
                processed += 1
                switch outcome {
                case .recovered: recovered += 1
                case .stillFailing: stillFailing += 1
                case .vanished: break
                }
            }
        }
        let (rec, fail) = lock.withLock { (recovered, stillFailing) }
        return (rec, fail, max(0, due.count - batch.count))
    }

    /// Snapshot of the current (or most recent) retry batch — manual or periodic.
    /// The UI polls this after `startRetry` until `running` is false.
    public func retryProgress() -> RetryProgressDTO {
        lock.withLock {
            RetryProgressDTO(
                running: running, total: total, processed: processed,
                recovered: recovered, stillFailing: stillFailing
            )
        }
    }

    // MARK: - Private

    /// Re-feeds one quarantined file. On success the event file + meta sidecar are
    /// removed and the DB row is marked recovered (`.recovered`); on parse/ingest
    /// failure the retry count is bumped and the sidecar + DB row refreshed
    /// (`.stillFailing`); if the file is already gone (a concurrent
    /// `clear()`/recover), `.vanished` — so it isn't miscounted.
    private func retryOne(
        _ url: URL,
        parse: (String) -> ParseResult,
        ingest: (ParsedEvent) throws -> Void
    ) -> RetryOutcome {
        guard FileManager.default.fileExists(atPath: url.path) else { return .vanished }
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return .vanished }
        let parsed: ParsedEvent
        switch parse(raw) {
        case .event(let event):
            parsed = event
        case .skip(let reason):
            // Well-formed but untrackable (no session_id): resolve it — remove from
            // quarantine and mark the DB row recovered — rather than re-quarantining
            // it every retry until it exhausts the budget and lights the badge.
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: metaURL(for: url))
            try? database?.resolveIngestionError(filename: url.lastPathComponent)
            logger.info("""
                Discarded untrackable quarantined \(url.lastPathComponent, privacy: .public): \
                \(reason, privacy: .public)
                """)
            return .recovered
        case .lostEvent:
            // Empty file: there is no event here to recover, and re-parsing it
            // next pass only reaches this same point — which is how one 0-byte
            // spill burned its whole retry budget and left the badge lit for
            // good. Drop it and record the loss instead. `.vanished` because it
            // counts as neither recovered nor still-failing: nothing was saved.
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: metaURL(for: url))
            recordLostEvent(filename: url.lastPathComponent)
            return .vanished
        case .unparseable:
            recordFailure(url, parsed: nil, reason: "unparseable event JSON", code: nil)
            return .stillFailing
        }
        do {
            try ingest(parsed)
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: metaURL(for: url))
            try? database?.resolveIngestionError(filename: url.lastPathComponent)
            logger.info("Recovered quarantined \(url.lastPathComponent, privacy: .public)")
            return .recovered
        } catch {
            let code = (error as? DaemonDatabaseError)?.sqliteCode
            recordFailure(url, parsed: parsed, reason: error.localizedDescription, code: code)
            return .stillFailing
        }
    }

    /// Records a (re)failed ingestion: bumps `retryCount`, rewrites the sidecar
    /// (preserving the original quarantine time), mirrors the row into the DB log,
    /// and logs to os_log. Shared by parse failures and ingest failures.
    private func recordFailure(_ eventURL: URL, parsed: ParsedEvent?, reason: String, code: Int32?) {
        let existing = readMeta(for: eventURL)
        let (eventType, sessionId): (String, String) = {
            if let parsed { return (parsed.eventType, parsed.hookData["session_id"] as? String ?? "") }
            if let existing { return (existing.eventType, existing.sessionId) }
            return peek(eventURL)
        }()
        // Preserve the original quarantine time across retries; fall back to the
        // file's mtime for legacy files that never had a sidecar, so a failed
        // retry never re-stamps the row with "now".
        let quarantinedAt = existing?.quarantinedAt ?? modifiedAt(eventURL)
        let retryCount = (existing?.retryCount ?? 0) + 1
        let now = Self.iso8601.string(from: Date())
        let meta = QuarantineMeta(
            reason: reason,
            sqliteCode: code.map(Int.init),
            quarantinedAt: quarantinedAt,
            eventType: eventType,
            sessionId: sessionId,
            retryCount: retryCount,
            lastRetriedAt: now
        )
        meta.writeSidecar(for: eventURL)

        let exhausted = meta.isExhausted(maxRetries: maxRetries)
        try? database?.recordIngestionError(
            filename: eventURL.lastPathComponent,
            eventType: eventType,
            sessionId: sessionId,
            reason: reason,
            sqliteCode: code.map(Int.init),
            quarantinedAt: quarantinedAt,
            retryCount: retryCount,
            lastRetriedAt: now,
            exhausted: exhausted
        )
        if exhausted {
            logger.error("""
                Quarantined \(eventURL.lastPathComponent, privacy: .public) exhausted \
                \(retryCount, privacy: .public) retries: \(reason, privacy: .public)
                """)
        } else {
            logger.warning("""
                Retry \(retryCount, privacy: .public)/\(self.maxRetries, privacy: .public) failed for \
                \(eventURL.lastPathComponent, privacy: .public): \(reason, privacy: .public)
                """)
        }
    }

    /// Non-exhausted quarantined files, least-recently-attempted first
    /// (never-retried first), so the periodic batch rotates fairly through the
    /// backlog instead of hammering the same head every interval.
    private func dueFiles() -> [URL] {
        eventFiles().compactMap { url -> (url: URL, lastRetried: String)? in
            let meta = readMeta(for: url)
            if (meta?.retryCount ?? 0) >= maxRetries { return nil }
            return (url, meta?.lastRetriedAt ?? "")
        }
        .sorted { $0.lastRetried < $1.lastRetried }
        .map(\.url)
    }

    /// Quarantined event files: `error-*.json` excluding the `.meta.json` sidecars.
    private func eventFiles() -> [URL] {
        let entries = (try? FileManager.default.contentsOfDirectory(
            at: errorsDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        )) ?? []
        return entries.filter {
            $0.pathExtension == "json"
                && $0.lastPathComponent.hasPrefix("error-")
                && !$0.lastPathComponent.hasSuffix(".meta.json")
        }
    }

    private func metaURL(for eventURL: URL) -> URL {
        QuarantineMeta.sidecarURL(for: eventURL)
    }

    /// Pooled at the allocation site rather than at each loop that calls it.
    /// `Data(contentsOf:)` returns an autoreleased buffer, and every caller
    /// (`counts`, `exhaustedCount`, `list`) walks the whole quarantine directory
    /// synchronously — with nothing to drain the pool, one sidecar per file stayed
    /// live for the length of the scan. `counts` backs the badge, which is polled
    /// every few seconds, and a backlog is largest during exactly the ingestion
    /// outage that makes these paths matter. Putting the pool here means a future
    /// caller can't reintroduce the problem by forgetting one.
    private func readMeta(for eventURL: URL) -> QuarantineMeta? {
        autoreleasepool {
            guard let data = try? Data(contentsOf: metaURL(for: eventURL)) else { return nil }
            return try? Self.metaDecoder.decode(QuarantineMeta.self, from: data)
        }
    }

    /// Best-effort event type + session id read directly from a legacy event
    /// file that has no meta sidecar. Pooled for the same reason as `readMeta`.
    private func peek(_ url: URL) -> (eventType: String, sessionId: String) {
        autoreleasepool {
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return ("", "")
            }
            let eventType = json["event"] as? String ?? ""
            let sessionId = (json["hook_data"] as? [String: Any])?["session_id"] as? String ?? ""
            return (eventType, sessionId)
        }
    }

    private nonisolated(unsafe) static let iso8601 = ISO8601DateFormatter()
    /// Reused across `readMeta` calls (per-call allocation showed up on the
    /// badge-poll path). `JSONDecoder` is `Sendable` and `decode` is reentrant,
    /// so a single shared instance is safe.
    private static let metaDecoder = JSONDecoder()

    private func modifiedAt(_ url: URL) -> String {
        guard let date = try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
        else { return "" }
        return Self.iso8601.string(from: date)
    }
}

extension QuarantineService: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
