#if os(macOS)
import XCTest
import GRDB
import AgenticToolkitDatabase
@testable import AgenticToolkitActivity

/// Reading the event log back: paging, the sequence cursor, kind filtering,
/// and that every one of the eight detail shapes survives the round trip.
final class ContextStoreReadTests: XCTestCase {
    private var dir: URL!
    private var db: BoundedDatabase!
    private var store: ContextStore!
    private let machineID = UUID()

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-ctxread-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        db = try BoundedDatabase(path: dir.appendingPathComponent("test.sqlite").path)
        store = ContextStore(database: db)
        try store.runMigrations()
        try store.upsertMachine(
            MachineDescriptor(id: machineID, platform: .macOS, nativeID: "NATIVE",
                              nativeIDKind: .ioPlatformUUID, hostname: "h", model: "m",
                              osVersion: "26.0"),
            seenAt: Date(timeIntervalSince1970: 1_000))
    }

    override func tearDownWithError() throws {
        store = nil; db = nil
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Fixtures

    private func focus(_ name: String) -> ContextEventDetail {
        .appFocus(AppFocusDetail(bundleID: "com.example.\(name)", appName: name, pid: 42,
                                 executablePath: "/Applications/\(name).app", windowID: 7,
                                 windowTitle: "\(name) window", documentPath: nil,
                                 documentSize: nil, documentModifiedAt: nil, documentType: nil))
    }

    @discardableResult
    private func insert(_ detail: ContextEventDetail, at t: TimeInterval) throws -> ContextEvent {
        let event = ContextEvent(machineID: machineID,
                                 occurredAt: Date(timeIntervalSince1970: t),
                                 detail: detail)
        try store.insert(event)
        return event
    }

    // MARK: - Empty log

    func testEmptyLogReadsAsNoRowsAndNoCursor() throws {
        XCTAssertEqual(try store.events(ContextEventQuery()), .empty)
        XCTAssertNil(try store.latestEventSequence())
    }

    // MARK: - Backfill

    func testBackfillReturnsTheNewestPageOldestFirst() throws {
        for i in 0..<5 {
            try insert(focus("app\(i)"), at: 1_000 + TimeInterval(i))
        }

        let page = try store.events(ContextEventQuery(limit: 3))

        XCTAssertEqual(page.records.count, 3)
        XCTAssertEqual(page.records.map(\.event.summary.subject), ["app2", "app3", "app4"],
                       "newest three, handed back oldest-first")
        XCTAssertEqual(page.records.map(\.sequence), page.records.map(\.sequence).sorted(),
                       "sequences ascend within the page")
    }

    func testBackfillReturnsEverythingWhenTheLimitExceedsTheLog() throws {
        try insert(focus("only"), at: 1_000)
        XCTAssertEqual(try store.events(ContextEventQuery(limit: 100)).records.count, 1)
    }

    // MARK: - The sequence cursor

    func testCursorReturnsOnlyRowsWrittenAfterIt() throws {
        try insert(focus("before"), at: 1_000)
        let cursor = try XCTUnwrap(try store.latestEventSequence())
        try insert(focus("after1"), at: 1_001)
        try insert(focus("after2"), at: 1_002)

        let tail = try store.events(ContextEventQuery(afterSequence: cursor, limit: 100))

        XCTAssertEqual(tail.records.map(\.event.summary.subject), ["after1", "after2"])
    }

    func testCursorAtTheHeadOfTheLogReturnsNothing() throws {
        try insert(focus("a"), at: 1_000)
        let cursor = try XCTUnwrap(try store.latestEventSequence())
        XCTAssertEqual(try store.events(ContextEventQuery(afterSequence: cursor)), .empty)
    }

    /// Tailing takes the *oldest* unseen rows — a reader that falls behind
    /// must not skip the gap it hasn't read yet.
    func testCursorPagingTakesTheOldestUnseenRowsFirst() throws {
        for i in 0..<5 {
            try insert(focus("app\(i)"), at: 1_000 + TimeInterval(i))
        }
        let first = try store.events(ContextEventQuery(afterSequence: 0, limit: 2))
        XCTAssertEqual(first.records.map(\.event.summary.subject), ["app0", "app1"])

        let next = try store.events(
            ContextEventQuery(afterSequence: first.nextSequence, limit: 2))
        XCTAssertEqual(next.records.map(\.event.summary.subject), ["app2", "app3"])
    }

    // MARK: - Filtering

    func testKindFilterSelectsOnlyTheRequestedKinds() throws {
        try insert(focus("app"), at: 1_000)
        try insert(.session(SessionDetail(change: .lock)), at: 1_001)
        try insert(.power(PowerDetail(source: .ac, percent: 80, isCharging: true)), at: 1_002)

        let page = try store.events(ContextEventQuery(kinds: [.session, .power], limit: 100))

        XCTAssertEqual(page.records.map(\.event.kind), [.session, .power])
    }

    func testAnEmptyKindFilterSelectsNothing() throws {
        try insert(focus("app"), at: 1_000)
        XCTAssertEqual(try store.events(ContextEventQuery(kinds: [], limit: 100)), .empty)
    }

    func testZeroLimitReturnsNothing() throws {
        try insert(focus("app"), at: 1_000)
        XCTAssertEqual(try store.events(ContextEventQuery(limit: 0)), .empty)
    }

    func testAskingPastTheCeilingStillAnswers() throws {
        try insert(focus("app"), at: 1_000)
        // The clamp is a bound on work, not a rejection: an over-large limit
        // is served, not thrown at or answered empty.
        XCTAssertEqual(
            try store.events(ContextEventQuery(limit: ContextEventQuery.maximumLimit * 10)).records.count,
            1)
    }

    /// The clamp only bites above ``ContextEventQuery/maximumLimit``, so this
    /// is the only shape of test that can see it at all: a log holding fewer
    /// rows than the ceiling answers identically whether the store passes
    /// `effectiveLimit` or the caller's raw `limit` to SQLite. Filling the
    /// log past the ceiling costs a few thousand inserts, which is the price
    /// of the assertion being able to fail.
    func testLimitIsClampedToTheMaximum() throws {
        let over = ContextEventQuery.maximumLimit + 1
        for index in 0..<over {
            try insert(focus("app"), at: 1_000 + TimeInterval(index))
        }

        let query = ContextEventQuery(limit: over)
        let page = try store.events(query)

        XCTAssertEqual(page.records.count, ContextEventQuery.maximumLimit,
                       "a caller asking for more than the ceiling gets the ceiling")
        XCTAssertTrue(page.mayHaveMore(after: query),
                      "and is told there is more, so it can page rather than assume it saw everything")
    }

    // MARK: - Detail round-trips

    func testEveryDetailShapeRoundTripsThroughTheStore() throws {
        let details: [ContextEventDetail] = [
            focus("Editor"),
            .window(WindowDetail(change: .created, bundleID: "com.apple.TextEdit",
                                 appName: "TextEdit", pid: 9, windowID: 184_036,
                                 windowTitle: "Untitled")),
            .network(NetworkDetail(interfaceType: .ethernet, isSatisfied: true, ssid: "net",
                                   bssid: "aa:bb", isExpensive: false, isConstrained: nil)),
            .location(LocationDetail(latitude: 1.5, longitude: -2.5, horizontalAccuracy: 35,
                                     altitude: nil, verticalAccuracy: nil, speed: nil, course: nil)),
            .input(InputDetail(change: .active, idleSeconds: 930,
                               secondsSinceKey: 0.5, secondsSinceMouseMove: 1.5,
                               secondsSinceClick: nil, secondsSinceScroll: nil,
                               keyCountDelta: 12, mouseCountDelta: 1_056, intervalMs: 30_000)),
            .session(SessionDetail(change: .unlock)),
            .power(PowerDetail(source: .battery, percent: 62, isCharging: false)),
            .appLifecycle(AppLifecycleDetail(change: .terminated, bundleID: "com.apple.dt.Xcode",
                                             appName: "Xcode", pid: 501))
        ]
        XCTAssertEqual(details.count, ContextEventKind.allCases.count,
                       "one fixture per kind — a new kind must fail here until covered")

        var written: [ContextEvent] = []
        for (i, detail) in details.enumerated() {
            written.append(try insert(detail, at: 1_000 + TimeInterval(i)))
        }

        let page = try store.events(ContextEventQuery(limit: 100))

        XCTAssertEqual(page.records.map(\.event), written,
                       "id, machine, timestamp and every detail field survive the round trip")
    }

    /// A header with no detail row is a torn write that the insert
    /// transaction makes impossible — but a hand-edited database can produce
    /// one, and the reader must drop it rather than invent a payload.
    func testAHeaderWithNoDetailRowIsDropped() throws {
        try insert(focus("kept"), at: 1_000)
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO context_event (id, machine_id, occurred_at, kind, capture_span_id)
                VALUES (?,?,?,?,NULL)
                """, arguments: [UUID().uuidString, self.machineID.uuidString,
                                 "1970-01-01T00:33:20.000Z", ContextEventKind.appFocus.rawValue])
        }

        let page = try store.events(ContextEventQuery(limit: 100))

        XCTAssertEqual(page.records.map(\.event.summary.subject), ["kept"])
    }

    // MARK: - The page's own fields

    /// The cursor advances past rows that were examined and dropped. A tailing
    /// reader that carried `records.last?.sequence` forward would get `nil`
    /// from a page whose every row was malformed, re-issue the same query, and
    /// spin on those rows forever without ever reaching the live tail.
    func testTheCursorAdvancesPastAPageWhoseRowsWereAllDropped() throws {
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO context_event (id, machine_id, occurred_at, kind, capture_span_id)
                VALUES (?,?,?,?,NULL)
                """, arguments: [UUID().uuidString, self.machineID.uuidString,
                                 "1970-01-01T00:16:40.000Z", ContextEventKind.appFocus.rawValue])
        }
        let written = try XCTUnwrap(try store.latestEventSequence())

        let page = try store.events(ContextEventQuery(afterSequence: 0, limit: 10))

        XCTAssertTrue(page.records.isEmpty, "the header has no detail row")
        XCTAssertEqual(page.examined, 1, "it was still examined")
        XCTAssertEqual(page.nextSequence, written, "and the cursor moves past it")
    }

    /// `examined` is what tells a tailing reader whether to ask again
    /// immediately: it equals the effective limit exactly when the page may
    /// not have reached the end of the log.
    func testExaminedEqualsTheLimitOnlyWhileMoreRowsMayFollow() throws {
        for i in 0..<5 {
            try insert(focus("app\(i)"), at: 1_000 + TimeInterval(i))
        }

        let full = try store.events(ContextEventQuery(afterSequence: 0, limit: 3))
        XCTAssertEqual(full.examined, 3, "a full page: more may follow")

        let rest = try store.events(ContextEventQuery(afterSequence: full.nextSequence, limit: 3))
        XCTAssertEqual(rest.examined, 2, "a short page: the log is caught up")
        XCTAssertEqual(rest.records.map(\.event.summary.subject), ["app3", "app4"])

        XCTAssertTrue(full.mayHaveMore(after: ContextEventQuery(afterSequence: 0, limit: 3)))
        XCTAssertFalse(rest.mayHaveMore(after: ContextEventQuery(afterSequence: full.nextSequence,
                                                                 limit: 3)))
    }

    /// The drain rule is keyed to the limit the store *applies*, not the one
    /// the caller asked for.
    ///
    /// A reader asking past `maximumLimit` is answered with pages of exactly
    /// `maximumLimit`, which never equals its request. Keyed on the request,
    /// "is there more?" is then `false` on every single full page: a window
    /// left open while the daemon writes faster than one page per tick stops
    /// draining after the first page each time and falls permanently behind.
    func testAFullPageSaysMoreMayFollowEvenWhenTheCallerAskedPastTheCeiling() {
        let query = ContextEventQuery(afterSequence: 10,
                                      limit: ContextEventQuery.maximumLimit * 3)
        XCTAssertEqual(query.effectiveLimit, ContextEventQuery.maximumLimit,
                       "the request is capped, so the page can never reach it")

        let full = ContextEventPage(records: [], examined: query.effectiveLimit,
                                    nextSequence: 4_000)
        XCTAssertTrue(full.mayHaveMore(after: query),
                      "a page filled to the applied ceiling has more behind it")

        let short = ContextEventPage(records: [], examined: 7, nextSequence: 4_000)
        XCTAssertFalse(short.mayHaveMore(after: query),
                       "a short page means the reader is caught up")

        let ended = ContextEventPage(records: [], examined: query.effectiveLimit,
                                     nextSequence: nil)
        XCTAssertFalse(ended.mayHaveMore(after: query),
                       "no cursor to carry forward, so nowhere to go")
    }

    // MARK: - App lifecycle

    func testAppLifecycleDetailSurvivesTheRoundTrip() throws {
        try insert(.appLifecycle(AppLifecycleDetail(
            change: .terminated, bundleID: "com.apple.dt.Xcode",
            appName: "Xcode", pid: 501)), at: 2_000)

        let page = try store.events(ContextEventQuery(limit: 10))

        XCTAssertEqual(page.records.count, 1)
        guard case .appLifecycle(let d) = page.records[0].event.detail else {
            return XCTFail("expected an app_lifecycle detail, got \(page.records[0].event.detail)")
        }
        XCTAssertEqual(d.change, .terminated)
        XCTAssertEqual(d.bundleID, "com.apple.dt.Xcode")
        XCTAssertEqual(d.appName, "Xcode")
        XCTAssertEqual(d.pid, 501)
    }

    func testAppLifecycleIsFilterableAndSummarised() throws {
        try insert(focus("Safari"), at: 2_000)
        try insert(.appLifecycle(AppLifecycleDetail(
            change: .launched, bundleID: "com.apple.Safari",
            appName: "Safari", pid: 77)), at: 2_001)

        let page = try store.events(ContextEventQuery(kinds: [.appLifecycle], limit: 10))

        XCTAssertEqual(page.records.count, 1, "the kind filter must know the new kind")
        XCTAssertEqual(page.records[0].event.summary.subject, "Safari")
        XCTAssertTrue(page.records[0].event.summary.detail.contains("launched"),
                      "the summary must say which way the app went")
    }

    func testAppLifecycleDetailRoundTripsThroughJSON() throws {
        let detail = ContextEventDetail.appLifecycle(AppLifecycleDetail(
            change: .terminated, bundleID: "com.example.app", appName: "App", pid: 9))

        let data = try JSONEncoder().encode(detail)
        XCTAssertEqual(try JSONDecoder().decode(ContextEventDetail.self, from: data), detail)

        // The wire tag is the schema's own kind name, not a compiler-chosen
        // spelling — this is what crosses the XPC boundary.
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"app_lifecycle\""), "wire tag must be the schema kind, got \(json)")
    }
}
#endif
