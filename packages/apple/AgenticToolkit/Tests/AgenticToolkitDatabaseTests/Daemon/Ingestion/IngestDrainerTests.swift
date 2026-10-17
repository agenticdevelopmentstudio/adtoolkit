import AgenticToolkitCore
import XCTest
import Foundation
import SQLite3
@testable import AgenticToolkitDatabase

/// Verifies one drain pass: the batch fast path, the per-event isolation a
/// permanent failure falls back to, and the two ways an event can leave the
/// spool without reaching the main database (a quiet skip, and quarantine).
final class IngestDrainerTests: XCTestCase {

    private var tmpDir: URL!
    private var errorsDir: URL!
    private var spool: IngestSpool!

    /// Batches handed to `ingestBatch`, in order, so a test can assert the drain
    /// amortized rather than fell back to one transaction per event.
    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var _batches: [[String]] = []
        private var _singles: [String] = []
        var batches: [[String]] { lock.lock(); defer { lock.unlock() }; return _batches }
        var singles: [String] { lock.lock(); defer { lock.unlock() }; return _singles }
        func batch(_ events: [ParsedEvent]) {
            lock.lock(); _batches.append(events.map(\.eventType)); lock.unlock()
        }
        func single(_ event: ParsedEvent) {
            lock.lock(); _singles.append(event.eventType); lock.unlock()
        }
    }

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-drain-\(suffix)")
        errorsDir = tmpDir.appendingPathComponent("errors")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        spool = try IngestSpool(path: tmpDir.appendingPathComponent("ingest.db").path)
    }

    override func tearDownWithError() throws {
        spool = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Fixtures

    private func event(_ type: String = "PreToolUse", session: String = "s-1") -> ParsedEvent {
        ParsedEvent(
            eventType: type, timestamp: "2026-01-01T00:00:00Z",
            hookData: session.isEmpty ? [:] : ["session_id": session],
            context: nil, accountEmail: ""
        )
    }

    private func makeDrainer(
        recorder: Recorder = Recorder(),
        batchSize: Int = 50,
        idlePoll: TimeInterval = 5,
        transientBackoff: TimeInterval = 0.5,
        batchFails: (@Sendable ([ParsedEvent]) throws -> Void)? = nil,
        singleFails: (@Sendable (ParsedEvent) throws -> Void)? = nil
    ) -> IngestDrainer {
        IngestDrainer(
            spool: spool,
            quarantine: QuarantineService(errorsDirectory: errorsDir),
            errorsDirectory: errorsDir,
            ingestBatch: { events in
                recorder.batch(events)
                try batchFails?(events)
            },
            ingestOne: { event in
                recorder.single(event)
                try singleFails?(event)
            },
            batchSize: batchSize,
            idlePoll: idlePoll,
            transientBackoff: transientBackoff
        )
    }

    private func errorFiles() -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: errorsDir.path)) ?? [])
            .filter { !$0.hasSuffix(".meta.json") }
    }

    /// SQLITE_BUSY — the daemon is contended, the event is fine.
    private static let transient = DaemonDatabaseError.stepFailed(message: "database is locked", code: 5)
    /// SQLITE_CONSTRAINT — this event will never land, however often it is tried.
    private static let permanent = DaemonDatabaseError.stepFailed(message: "constraint failed", code: 19)

    // MARK: - The happy path

    func testOnePassMovesTheWholeBatchAndEmptiesTheSpool() throws {
        let recorder = Recorder()
        try spool.enqueue(event("SessionStart"))
        try spool.enqueue(event("PreToolUse"))
        try spool.enqueue(event("PostToolUse"))

        let progress = makeDrainer(recorder: recorder).drainOnce()

        XCTAssertEqual(progress, .drained(3))
        XCTAssertEqual(recorder.batches, [["SessionStart", "PreToolUse", "PostToolUse"]],
                       "one transaction, not three")
        XCTAssertTrue(recorder.singles.isEmpty, "isolation must not run when the batch lands")
        XCTAssertEqual(spool.pendingCount(), 0)
    }

    func testAnEmptySpoolDrainsNothingAndIngestsNothing() throws {
        let recorder = Recorder()

        XCTAssertEqual(makeDrainer(recorder: recorder).drainOnce(), .drained(0))
        XCTAssertTrue(recorder.batches.isEmpty)
    }

    func testAPassNeverTakesMoreThanTheBatchSize() throws {
        let recorder = Recorder()
        for index in 0..<5 { try spool.enqueue(event("E\(index)")) }

        XCTAssertEqual(makeDrainer(recorder: recorder, batchSize: 2).drainOnce(), .drained(2))
        XCTAssertEqual(recorder.batches, [["E0", "E1"]])
        XCTAssertEqual(spool.pendingCount(), 3)
    }

    // MARK: - Transient contention

    /// Contention is the daemon's problem, not the event's: nothing leaves the
    /// spool and no attempt is charged, or a busy hour would exhaust a healthy
    /// event's retry budget and quarantine it.
    func testATransientFailureLeavesTheBatchAndChargesNoAttempts() throws {
        let recorder = Recorder()
        try spool.enqueue(event("A"))
        try spool.enqueue(event("B"))
        let drainer = makeDrainer(recorder: recorder, batchFails: { _ in throw Self.transient })

        XCTAssertEqual(drainer.drainOnce(), .backoff)

        let remaining = try spool.pendingBatch(limit: 10)
        XCTAssertEqual(remaining.map(\.eventType), ["A", "B"])
        XCTAssertEqual(remaining.map(\.attempts), [0, 0])
        XCTAssertTrue(recorder.singles.isEmpty, "a transient error must not trigger isolation")
    }

    func testATransientFailureDuringIsolationHaltsThePassWithoutLosingTheRest() throws {
        let recorder = Recorder()
        try spool.enqueue(event("bad"))
        try spool.enqueue(event("good"))
        let drainer = makeDrainer(
            recorder: recorder,
            batchFails: { _ in throw Self.permanent },
            singleFails: { event in
                // The first event is permanently broken; the database goes busy
                // immediately after, which must stop the pass where it stands.
                throw event.eventType == "bad" ? Self.permanent : Self.transient
            }
        )

        XCTAssertEqual(drainer.drainOnce(), .backoff)
        XCTAssertEqual(recorder.singles, ["bad", "good"])
        XCTAssertEqual(try spool.pendingBatch(limit: 10).map(\.eventType), ["bad", "good"],
                       "the halted event stays queued and so does the one it failed on")
    }

    // MARK: - Permanent failure

    func testAPoisonedEventFallsBackToIsolationAndTheGoodOnesStillLand() throws {
        let recorder = Recorder()
        try spool.enqueue(event("good1"))
        try spool.enqueue(event("poison"))
        try spool.enqueue(event("good2"))
        let drainer = makeDrainer(
            recorder: recorder,
            batchFails: { _ in throw Self.permanent },
            singleFails: { event in
                if event.eventType == "poison" { throw Self.permanent }
            }
        )

        XCTAssertEqual(drainer.drainOnce(), .drained(2))
        XCTAssertEqual(recorder.singles, ["good1", "poison", "good2"],
                       "one bad event must not hold up the sessions behind it")

        let remaining = try spool.pendingBatch(limit: 10)
        XCTAssertEqual(remaining.map(\.eventType), ["poison"])
        XCTAssertEqual(remaining.map(\.attempts), [1])
        XCTAssertTrue(errorFiles().isEmpty, "one failure is not exhaustion")
    }

    /// A doomed event ends up in `errors/`, the same directory the drop-file
    /// path quarantines into — which is what lets `/ingestion/errors`, its badge
    /// and "Retry All" keep working without a new surface for spooled events.
    func testAnExhaustedEventIsQuarantinedIntoTheErrorsDirectory() throws {
        try spool.enqueue(event("doomed"))
        let drainer = makeDrainer(
            batchFails: { _ in throw Self.permanent },
            singleFails: { _ in throw Self.permanent }
        )

        for attempt in 1..<IngestSpool.maxAttempts {
            XCTAssertEqual(drainer.drainOnce(), .drained(0), "pass \(attempt) retries, not quarantines")
            XCTAssertEqual(spool.pendingCount(), 1)
        }
        XCTAssertEqual(drainer.drainOnce(), .drained(1))

        XCTAssertEqual(spool.pendingCount(), 0)
        let quarantined = errorFiles()
        XCTAssertEqual(quarantined.count, 1)
        XCTAssertTrue(try XCTUnwrap(quarantined.first).hasPrefix("error-spool-"))
    }

    /// Quarantine has to write the drop-file envelope, because `QuarantineService`
    /// retries a file by re-parsing it.
    func testAQuarantinedFileIsReadableByTheDropFileParser() throws {
        try spool.enqueue(event("doomed", session: "s-q"))
        let drainer = makeDrainer(
            batchFails: { _ in throw Self.permanent },
            singleFails: { _ in throw Self.permanent }
        )
        for _ in 0..<IngestSpool.maxAttempts { drainer.drainOnce() }

        let name = try XCTUnwrap(errorFiles().first)
        let json = try String(contentsOf: errorsDir.appendingPathComponent(name), encoding: .utf8)
        guard case .event(let parsed) = ParseResult.parse(envelopeJSON: json) else {
            return XCTFail("quarantined file is not a re-feedable envelope")
        }
        XCTAssertEqual(parsed.sessionId, "s-q")
    }

    // MARK: - Events that never reach the database

    /// Well-formed but untrackable (no session_id). The drop-file path discards
    /// these silently; quarantining one would light the error badge forever,
    /// because every retry re-parses to the same skip.
    func testAnUntrackableEventIsDiscardedQuietlyAndNeverQuarantined() throws {
        let recorder = Recorder()
        try spool.enqueue(event("StatusLine", session: ""))
        try spool.enqueue(event("PreToolUse"))

        XCTAssertEqual(makeDrainer(recorder: recorder).drainOnce(), .drained(2))
        XCTAssertEqual(recorder.batches, [["PreToolUse"]], "the skip never reaches the database")
        XCTAssertEqual(spool.pendingCount(), 0)
        XCTAssertTrue(errorFiles().isEmpty)
    }

    /// An envelope the parser rejects outright can never drain, so it goes
    /// straight to quarantine rather than spending five attempts first.
    func testAnUnparseableEnvelopeIsQuarantinedWithoutReachingTheDatabase() throws {
        let recorder = Recorder()
        try spool.enqueue(event("", session: "s-u"))  // empty event type → unparseable

        XCTAssertEqual(makeDrainer(recorder: recorder).drainOnce(), .drained(1))
        XCTAssertTrue(recorder.batches.isEmpty)
        XCTAssertEqual(spool.pendingCount(), 0)
        XCTAssertEqual(errorFiles().count, 1)
    }

    // MARK: - A quarantine that could not be written

    /// The spooled row is the only copy of the event, so a quarantine that
    /// failed to write is a reason to keep the row, never to delete it.
    func testAnUnparseableEnvelopeStaysQueuedWhenTheQuarantineCannotBeWritten() throws {
        try spool.enqueue(event("", session: "s-u"))  // empty event type → unparseable
        try blockErrorsDirectory()

        XCTAssertEqual(makeDrainer().drainOnce(), .drained(0))
        XCTAssertEqual(spool.pendingCount(), 1, "nothing may leave the spool uncopied")
    }

    /// Same rule at the other end of the budget: an event that spent all five
    /// attempts is still the only copy while the quarantine write keeps failing.
    func testAnExhaustedEventStaysQueuedWhenTheQuarantineCannotBeWritten() throws {
        try spool.enqueue(event("doomed"))
        try blockErrorsDirectory()
        let drainer = makeDrainer(
            batchFails: { _ in throw Self.permanent },
            singleFails: { _ in throw Self.permanent }
        )

        for _ in 0...IngestSpool.maxAttempts {
            XCTAssertEqual(drainer.drainOnce(), .drained(0))
        }
        XCTAssertEqual(spool.pendingCount(), 1)
    }

    // MARK: - A receipt that could not be written

    /// The events reached the main database but the spool's DELETE failed, so
    /// the same rows are read again next pass. That is the at-least-once
    /// contract, and it must be reported as `.backoff`: calling it `.drained`
    /// sends the loop straight back into the same batch with no delay, turning
    /// a failing receipt into a duplicate factory.
    func testAFailingCompleteReportsBackoffAndTheRowsReplay() throws {
        let recorder = Recorder()
        try spool.enqueue(event("A"))
        try spool.enqueue(event("B"))
        let drainer = makeDrainer(recorder: recorder)

        try refuseSpoolDeletes()
        XCTAssertEqual(drainer.drainOnce(), .backoff)
        XCTAssertEqual(recorder.batches, [["A", "B"]])
        XCTAssertEqual(spool.pendingCount(), 2, "an undeleted row is still queued")

        try allowSpoolDeletes()
        XCTAssertEqual(drainer.drainOnce(), .drained(2))
        XCTAssertEqual(recorder.batches, [["A", "B"], ["A", "B"]], "at-least-once, so they replay")
        XCTAssertEqual(spool.pendingCount(), 0)
    }

    // MARK: - Backoff escalation

    /// A fixed delay is a spin against a database that stays unwritable, so the
    /// wait doubles; the cap keeps a broken daemon's latency bounded.
    func testTheBackoffDoublesPerConsecutiveFailureAndStopsAtTheCap() {
        let drainer = makeDrainer(transientBackoff: 0.5)

        XCTAssertEqual(drainer.backoffDelay(after: 1), 0.5, accuracy: 0.0001)
        XCTAssertEqual(drainer.backoffDelay(after: 2), 1, accuracy: 0.0001)
        XCTAssertEqual(drainer.backoffDelay(after: 3), 2, accuracy: 0.0001)
        XCTAssertEqual(drainer.backoffDelay(after: 6), 16, accuracy: 0.0001)
        XCTAssertEqual(drainer.backoffDelay(after: 7), 30, accuracy: 0.0001, "capped, not 32")
        XCTAssertEqual(drainer.backoffDelay(after: 500), 30, accuracy: 0.0001)
    }

    /// Zero and one failure both mean "the first wait", so the escalation never
    /// starts below the base delay.
    func testTheFirstWaitIsAlwaysTheBaseDelay() {
        let drainer = makeDrainer(transientBackoff: 0.25)

        XCTAssertEqual(drainer.backoffDelay(after: 0), 0.25, accuracy: 0.0001)
        XCTAssertEqual(drainer.backoffDelay(after: 1), 0.25, accuracy: 0.0001)
    }

    // MARK: - The loop

    /// An idle wait exists to be cut short: the whole reason the drain is
    /// signalled rather than scheduled is that a hook's event must not sit out
    /// a poll interval before the app sees it.
    func testAnArrivingEventCutsTheIdleWaitShort() throws {
        let recorder = Recorder()
        // Long enough that finishing inside the timeout can only mean the wake
        // was honoured, never that the poll came round.
        let drainer = makeDrainer(recorder: recorder, idlePoll: 60)
        drainer.start()
        defer { drainer.stop() }

        try spool.enqueue(event("late"))
        drainer.wake()

        XCTAssertTrue(waitUntil(2) { recorder.batches == [["late"]] },
                      "the wake must not wait out the idle poll")
    }

    /// A backoff exists precisely *not* to be cut short: every enqueue fires a
    /// wake, so honouring one here would let the traffic that is contending for
    /// the database cancel the wait for that contention.
    func testAWakeDoesNotCutABackoffShort() throws {
        let recorder = Recorder()
        try spool.enqueue(event("contended"))
        let drainer = makeDrainer(
            recorder: recorder, idlePoll: 60, transientBackoff: 60,
            batchFails: { _ in throw Self.transient }
        )
        drainer.start()
        defer { drainer.stop() }

        XCTAssertTrue(waitUntil(2) { recorder.batches.count == 1 }, "the first pass must run")
        for _ in 0..<10 {
            drainer.wake()
            Thread.sleep(forTimeInterval: 0.05)
        }
        XCTAssertEqual(recorder.batches.count, 1, "the backoff holds through every wake")
    }

    /// `stop()` waits for the pass in flight, so a drain that has already read a
    /// batch finishes writing it rather than being abandoned mid-delivery.
    func testStopReturnsOnlyOnceTheLoopHasFinished() throws {
        let recorder = Recorder()
        let started = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        try spool.enqueue(event("inflight"))
        let drainer = makeDrainer(recorder: recorder, idlePoll: 60, batchFails: { _ in
            started.signal()
            release.wait()
        })
        drainer.start()

        XCTAssertEqual(started.wait(timeout: .now() + 2), .success)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { release.signal() }
        drainer.stop()

        XCTAssertEqual(recorder.batches, [["inflight"]])
    }

    // MARK: - Test plumbing

    /// Replaces `errors/` with a regular file, so every `createDirectory` and
    /// every write into it fails the way a full or read-only volume would.
    private func blockErrorsDirectory() throws {
        try? FileManager.default.removeItem(at: errorsDir)
        try Data("not a directory".utf8).write(to: errorsDir)
    }

    /// Makes `DELETE FROM spooled_event` fail from outside the spool, which is
    /// the one failure `IngestSpool` has no API to provoke. A trigger is the
    /// narrowest lever: it leaves every other statement alone.
    private func refuseSpoolDeletes() throws {
        try executeOnSpoolFile("""
            CREATE TRIGGER refuse_delete BEFORE DELETE ON spooled_event
            BEGIN SELECT RAISE(ABORT, 'delete refused'); END
        """)
    }

    private func allowSpoolDeletes() throws {
        try executeOnSpoolFile("DROP TRIGGER refuse_delete")
    }

    private func executeOnSpoolFile(_ sql: String) throws {
        var handle: OpaquePointer?
        let path = tmpDir.appendingPathComponent("ingest.db").path
        guard sqlite3_open(path, &handle) == SQLITE_OK else {
            throw XCTSkip("could not open the spool file directly")
        }
        defer { sqlite3_close(handle) }
        XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, nil), SQLITE_OK,
                       String(cString: sqlite3_errmsg(handle)))
    }

    /// Polls a condition rather than sleeping a fixed span, so a passing test
    /// costs what the drain actually took.
    private func waitUntil(_ timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            Thread.sleep(forTimeInterval: 0.02)
        }
        return condition()
    }
}
