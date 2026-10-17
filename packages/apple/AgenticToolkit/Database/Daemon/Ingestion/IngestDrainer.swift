#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import OSLog

/// Moves spooled events into the main database — the only reader of
/// `IngestSpool`, and the only writer of captured events into the daemon's store.
///
/// It is a signalled loop rather than a scheduled task on purpose. A scheduled
/// drain would put its whole interval between a hook firing and the app seeing
/// the event, turning the live Sessions feed into a polling one; waking on
/// enqueue keeps an idle daemon's latency at roughly what it was when the hook
/// wrote to the main DB directly, while a burst still coalesces into batches
/// because everything that arrives during one pass is waiting at the start of
/// the next. The periodic wake is a floor, not the mechanism: it re-drains a
/// backlog left by a kill, and covers a lost signal.
///
/// **Delivery is at-least-once.** A batch is deleted from the spool only after
/// the main-DB transaction commits, so an unclean kill in that gap replays it.
/// That is the deliberate direction to be wrong in: the whole point of the
/// spool is that an event is never discarded because the daemon was busy, and
/// the window is one batch wide.
public final class IngestDrainer: @unchecked Sendable {

    /// Events per pass. Large enough that a backlog amortizes into few main-DB
    /// transactions, small enough that one pass never holds the single writer
    /// long enough to starve a serving read.
    private let batchSize: Int
    /// How long an idle loop sleeps before looking again without being woken.
    private let idlePoll: TimeInterval
    /// How long to wait out a transient DB error (BUSY/LOCKED/IOERR) before
    /// re-reading the same batch. Never charged to an event's attempt count —
    /// contention is the daemon's problem, not the event's.
    private let transientBackoff: TimeInterval
    /// Ceiling for the doubling in ``backoffDelay(after:)``. Reached only after
    /// a run of consecutive failures long enough to mean the database is not
    /// merely busy, where the cost of waiting is latency on a daemon that is
    /// already broken and the cost of not waiting is a spin against it.
    private let maxBackoff: TimeInterval = 30

    private let spool: IngestSpool
    /// Ingests a whole batch in one main-DB transaction, broadcasting only once
    /// it commits. Throws without writing or broadcasting anything if any event
    /// in the batch fails, which is what lets the isolation pass below find it.
    private let ingestBatch: @Sendable ([ParsedEvent]) throws -> Void
    /// Ingests one event, for the isolation pass after a batch fails.
    private let ingestOne: @Sendable (ParsedEvent) throws -> Void
    /// Where an event that can never drain goes. Reusing the file quarantine
    /// rather than growing a `state` column on the spool is what keeps the spool
    /// a queue: `/ingestion/errors`, its badge, and "Retry All" already read
    /// that directory, so a doomed spooled event needs no new surface anywhere.
    private let quarantine: QuarantineService
    private let errorsDirectory: URL
    /// Name of the drain thread, so a daemon can put it under its own subsystem.
    private let threadName: String

    private let condition = NSCondition()
    /// All four are guarded by `condition`. `thread` included: `start()` used to
    /// read and assign it unlocked while every other access took the lock.
    private var pendingWake = false
    private var stopped = false
    private var thread: Thread?
    /// Signalled once `loop()` returns, so `stop()` can wait for the pass in
    /// flight instead of merely asking it to end.
    private let finished = DispatchSemaphore(value: 0)

    public init(
        spool: IngestSpool,
        quarantine: QuarantineService,
        errorsDirectory: URL,
        ingestBatch: @escaping @Sendable ([ParsedEvent]) throws -> Void,
        ingestOne: @escaping @Sendable (ParsedEvent) throws -> Void,
        batchSize: Int = 50,
        idlePoll: TimeInterval = 5,
        transientBackoff: TimeInterval = 0.5,
        threadName: String = "ingest-drain"
    ) {
        self.spool = spool
        self.quarantine = quarantine
        self.errorsDirectory = errorsDirectory
        self.ingestBatch = ingestBatch
        self.ingestOne = ingestOne
        self.batchSize = batchSize
        self.idlePoll = idlePoll
        self.transientBackoff = transientBackoff
        self.threadName = threadName
    }

    // MARK: - Lifecycle

    /// Starts draining. Call only once the main database is migrated — this is
    /// the writer that the migration is protecting the schema for.
    public func start() {
        condition.lock()
        guard thread == nil, !stopped else { return condition.unlock() }
        let thread = Thread { [weak self] in self?.loop() }
        thread.name = threadName
        thread.qualityOfService = .utility
        self.thread = thread
        condition.unlock()
        thread.start()
        logger.info("Ingest drain started (\(self.spool.pendingCount(), privacy: .public) pending)")
    }

    /// Signals that something was enqueued. Cheap and safe to call from the
    /// hook-delivery path — it takes a lock and returns, never touching SQLite.
    public func wake() {
        condition.lock()
        pendingWake = true
        condition.signal()
        condition.unlock()
    }

    /// Asks the loop to end and **waits for the pass in flight to finish**, so
    /// the shutdown sequence's promise that an in-flight batch completes is a
    /// fact rather than a hope. A pass is bounded by one main-DB transaction;
    /// the timeout exists only so a wedged writer cannot hold up the daemon's
    /// exit, which launchd would resolve with SIGKILL anyway.
    public func stop() {
        condition.lock()
        let running = thread != nil && !stopped
        stopped = true
        pendingWake = true
        condition.signal()
        condition.unlock()

        guard running else { return }
        if finished.wait(timeout: .now() + 5) == .timedOut {
            logger.warning("Ingest drain did not finish within 5s of stop; exiting anyway")
        }
    }

    private var isStopped: Bool {
        condition.lock()
        defer { condition.unlock() }
        return stopped
    }

    // MARK: - Loop

    private func loop() {
        defer { finished.signal() }
        var consecutiveBackoffs = 0
        while !isStopped {
            // Consume the wake token *before* the pass, not after it. Clearing it
            // afterwards discarded the one signal that matters — an event queued
            // while the pass was already reading — and left the flag set from a
            // wake the pass did see, which made the wait below a no-op under any
            // live traffic at all.
            condition.lock()
            pendingWake = false
            condition.unlock()

            switch drainOnce() {
            case .drained(let count) where count >= batchSize:
                consecutiveBackoffs = 0
                continue  // A full batch means more is probably waiting.
            case .drained:
                consecutiveBackoffs = 0
                waitForWork(upTo: idlePoll, honouringWake: true)
            case .backoff:
                consecutiveBackoffs += 1
                waitForWork(upTo: backoffDelay(after: consecutiveBackoffs), honouringWake: false)
            }
        }
    }

    /// How long to wait after `count` consecutive failed passes: the base delay,
    /// doubling, capped. A fixed delay is right for the one-off BUSY this was
    /// written for and wrong for everything else — a database that stays
    /// unwritable turns a fixed 0.5s into a spin, and a spool whose DELETE keeps
    /// failing turns it into a spin that re-ingests the same batch twice a
    /// second. Public so the escalation is a tested property, not a detail.
    public func backoffDelay(after count: Int) -> TimeInterval {
        guard count > 1 else { return transientBackoff }
        let doublings = min(count - 1, 16)  // 2^16 × base already exceeds any cap
        return min(transientBackoff * pow(2, Double(doublings)), maxBackoff)
    }

    /// Waits up to `timeout`, or until stopped.
    ///
    /// `honouringWake` is the difference between "nothing to do" and "the
    /// database pushed back". An idle wait exists to be cut short by an arriving
    /// event; a backoff exists precisely to *not* be, or the wake that every
    /// enqueue fires would cancel the wait for the contention that enqueue is
    /// part of.
    private func waitForWork(upTo timeout: TimeInterval, honouringWake: Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        condition.lock()
        defer { condition.unlock() }
        while !stopped, Date() < deadline {
            if honouringWake, pendingWake { break }
            condition.wait(until: deadline)
        }
        pendingWake = false
    }

    /// The outcome of one pass. Public because one pass is the unit the tests
    /// drive: `start()` would make every assertion a race.
    public enum Progress: Equatable {
        /// How many events left the spool this pass — drained or discarded.
        case drained(Int)
        /// The database was contended; nothing is wrong with the events.
        case backoff
    }

    // MARK: - One pass

    @discardableResult
    public func drainOnce() -> Progress {
        let batch: [SpooledEvent]
        do {
            batch = try spool.pendingBatch(limit: batchSize)
        } catch {
            logger.error("Spool read failed: \(error.localizedDescription, privacy: .public)")
            return .backoff
        }
        guard !batch.isEmpty else { return .drained(0) }

        // Everything that leaves the spool this pass, deleted in one write at the
        // end — a per-event DELETE would put back exactly the per-event write
        // transaction the batching is here to remove.
        var completed: [Int64] = []
        var ready: [(row: SpooledEvent, event: ParsedEvent)] = []

        for row in batch {
            switch Self.parse(row) {
            case .event(let parsed):
                ready.append((row, parsed))
            case .skip(let reason):
                // Well-formed but untrackable. `EnvelopeBuilder` already drops
                // these before they are spooled, so reaching here means the rules
                // changed under a queued event — discard it quietly, exactly as
                // the drop-file path does, and never light the error badge.
                logger.debug("Discarding untrackable spooled event: \(reason, privacy: .public)")
                completed.append(row.id)
            case .lostEvent:
                // An empty envelope: the row's payload never landed. No retry can
                // recover it, so forget it rather than requeue it forever — but
                // record the loss, the same way the drop-file path does.
                quarantine.recordLostEvent(filename: "spool-row-\(row.id)")
                completed.append(row.id)
            case .unparseable:
                // Only forget it once there is a copy somewhere else. A
                // quarantine that could not be written leaves the row queued,
                // where the next pass will try again.
                if quarantine(row, parsed: nil, reason: "unparseable spooled envelope", code: nil) {
                    completed.append(row.id)
                }
            }
        }

        var backoff = false
        if !ready.isEmpty {
            do {
                try ingestBatch(ready.map(\.event))
                completed.append(contentsOf: ready.map(\.row.id))
            } catch let dbError as DaemonDatabaseError where dbError.isTransient {
                // The whole transaction rolled back and nothing is wrong with the
                // events. Leave every one of them where it is and try again.
                backoff = true
            } catch {
                // One of them is bad and took the batch down with it. Re-run
                // singly so the good ones still land and the bad one is named.
                completed.append(contentsOf: isolate(ready, transientHalt: &backoff))
            }
        }

        do {
            try spool.complete(ids: completed)
        } catch {
            // The events ARE in the main DB; only the receipt failed, so the next
            // pass reads the same rows and writes them again. One replay after a
            // kill is the at-least-once contract working as designed. A replay
            // every pass is a duplicate factory — hook events carry no
            // `message_id`, so nothing downstream deduplicates them — and
            // reporting a full batch as `.drained` is what would make the loop
            // `continue` straight back into it with no delay at all. A pass whose
            // receipt failed made no durable progress, so say so: the caller
            // backs off, and the backoff escalates for as long as it keeps
            // failing.
            let reason = error.localizedDescription
            logger.error("""
                Spool delete failed; \(completed.count, privacy: .public) event(s) \
                will replay: \(reason, privacy: .public)
                """)
            return .backoff
        }
        return backoff ? .backoff : .drained(completed.count)
    }

    /// Re-ingests a failed batch one event at a time. Returns the ids that left
    /// the spool — drained, or quarantined after spending their last attempt.
    /// A permanent failure does not stop the pass: one poisoned event must not
    /// hold up every session behind it, which is how the drop-file path has
    /// always behaved. A transient one does, and sets `transientHalt`.
    private func isolate(
        _ ready: [(row: SpooledEvent, event: ParsedEvent)],
        transientHalt: inout Bool
    ) -> [Int64] {
        var completed: [Int64] = []
        for (row, event) in ready {
            do {
                try ingestOne(event)
                completed.append(row.id)
            } catch let dbError as DaemonDatabaseError where dbError.isTransient {
                transientHalt = true
                break
            } catch {
                let reason = error.localizedDescription
                let code = (error as? DaemonDatabaseError)?.sqliteCode
                logger.error("Drain failed for \(row.eventType, privacy: .public): \(reason, privacy: .public)")
                // A read failure here reads as exhausted (see `recordFailure`),
                // so a counter we cannot maintain quarantines rather than loops.
                let exhausted = (try? spool.recordFailure(id: row.id, reason: reason)) ?? true
                if exhausted,
                   quarantine(
                       row, parsed: event, reason: reason, code: code,
                       // The attempt just charged, so the quarantine inherits a
                       // true count of ingest attempts instead of restarting at
                       // zero and re-earning what these five already proved.
                       attempts: row.attempts + 1
                   ) {
                    completed.append(row.id)
                }
            }
        }
        return completed
    }

    // MARK: - Helpers

    private static func parse(_ row: SpooledEvent) -> ParseResult {
        guard let json = String(data: row.envelope, encoding: .utf8) else { return .unparseable }
        return ParseResult.parse(envelopeJSON: json)
    }

    /// Writes a doomed event into `errors/` in the drop-file format and records
    /// it, so it lands in the same place, with the same sidecar and DB-log row,
    /// as a drop file that could not be ingested. `QuarantineService.retry`
    /// re-feeds it by re-parsing that file — which is why the envelope written
    /// here is the same shape a drop file has.
    ///
    /// **Returns whether the event is now safely somewhere else**, and the caller
    /// must not `complete` it otherwise: the spooled row is the only copy of the
    /// event that exists, so a quarantine that could not be written is a reason
    /// to keep the row, not a reason to delete it. `attempts` is how many ingest
    /// attempts it has already spent (see `recordInitialQuarantine`).
    private func quarantine(
        _ row: SpooledEvent, parsed: ParsedEvent?, reason: String, code: Int32?, attempts: Int = 0
    ) -> Bool {
        let destination = errorsDirectory
            .appendingPathComponent("error-spool-\(row.id)-\(UUID().uuidString).json")
        do {
            try FileManager.default.createDirectory(
                at: errorsDirectory, withIntermediateDirectories: true
            )
            try row.envelope.write(to: destination)
        } catch {
            let failure = error.localizedDescription
            logger.error("""
                Could not quarantine spooled event \(row.id, privacy: .public); \
                it stays queued: \(failure, privacy: .public)
                """)
            return false
        }
        quarantine.recordInitialQuarantine(
            eventURL: destination, reason: reason, code: code, parsed: parsed,
            retryCount: attempts
        )
        return true
    }
}

extension IngestDrainer: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
