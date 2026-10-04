#if os(macOS)
import XCTest
import GRDB
import AgenticToolkitDatabase
@testable import AgenticToolkitActivity

/// Reading one local calendar day out of the log: the range predicate, the
/// ordering rule that comes with it, and how it composes with the cursor.
final class ContextStoreDayTests: XCTestCase {
    private var dir: URL!
    private var db: BoundedDatabase!
    private var store: ContextStore!
    private let machineID = UUID()

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-ctxday-\(UUID().uuidString)")
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

    private func focus(_ name: String) -> ContextEventDetail {
        .appFocus(AppFocusDetail(bundleID: "com.example.\(name)", appName: name, pid: 42,
                                 executablePath: nil, windowID: nil, windowTitle: nil,
                                 documentPath: nil, documentSize: nil,
                                 documentModifiedAt: nil, documentType: nil))
    }

    @discardableResult
    private func insert(_ name: String, at date: Date) throws -> ContextEvent {
        let event = ContextEvent(machineID: machineID, occurredAt: date, detail: focus(name))
        try store.insert(event)
        return event
    }

    /// Local noon on a given day, so the assertions never sit on a midnight
    /// that a timezone offset could move across.
    private func noon(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day; components.hour = 12
        return Calendar.current.date(from: components)!
    }

    // MARK: - Day keys

    func testDayKeyIsTheLocalCalendarDay() {
        XCTAssertEqual(ContextEventDayKey.key(for: noon(2026, 8, 20)), "2026-08-20")
    }

    func testDayKeyBoundsAreTheLocalDayHalfOpen() throws {
        let start = try XCTUnwrap(ContextEventDayKey.startOfDay("2026-08-20"))
        let end = try XCTUnwrap(ContextEventDayKey.endOfDay("2026-08-20"))
        XCTAssertEqual(start, Calendar.current.startOfDay(for: noon(2026, 8, 20)))
        XCTAssertEqual(end, Calendar.current.startOfDay(for: noon(2026, 8, 21)))
    }

    func testAnUnparseableDayKeyHasNoBounds() {
        XCTAssertNil(ContextEventDayKey.startOfDay("not-a-day"))
        XCTAssertNil(ContextEventDayKey.endOfDay("2026-13-45"))
    }

    // MARK: - Filtering

    func testDayFilterReturnsOnlyThatLocalDay() throws {
        try insert("before", at: noon(2026, 8, 19))
        try insert("during-early", at: noon(2026, 8, 20).addingTimeInterval(-3_600))
        try insert("during-late", at: noon(2026, 8, 20).addingTimeInterval(3_600))
        try insert("after", at: noon(2026, 8, 21))

        let page = try store.events(ContextEventQuery(day: "2026-08-20", limit: 100))

        XCTAssertEqual(page.records.map(\.event.summary.subject),
                       ["during-early", "during-late"])
    }

    func testDayFilterIncludesTheFirstAndLastInstantOfTheDay() throws {
        let start = try XCTUnwrap(ContextEventDayKey.startOfDay("2026-08-20"))
        let end = try XCTUnwrap(ContextEventDayKey.endOfDay("2026-08-20"))
        try insert("first", at: start)
        try insert("last", at: end.addingTimeInterval(-0.001))
        try insert("next-day", at: end)

        let page = try store.events(ContextEventQuery(day: "2026-08-20", limit: 100))

        XCTAssertEqual(page.records.map(\.event.summary.subject), ["first", "last"],
                       "the range is half-open: midnight starts the day, next midnight does not")
    }

    /// A day page ascends by *sequence* — recorded order — and these three
    /// rows are deliberately recorded out of timestamp order so the two
    /// answers differ. Recorded order wins because the cursor is a sequence:
    /// a page sorted by one column and paged by another steps over rows it
    /// never returned. `ContextEventQuery` carries the reasoning.
    func testADayPageAscendsByRecordedOrderNotByTimestamp() throws {
        for hour in [3, 1, 2] {
            try insert("h\(hour)", at: noon(2026, 8, 20).addingTimeInterval(TimeInterval(hour) * 3_600))
        }

        let page = try store.events(ContextEventQuery(day: "2026-08-20", limit: 2))

        XCTAssertEqual(page.records.map(\.event.summary.subject), ["h3", "h1"],
                       "a day is read from the first row recorded in it, not backwards from "
                       + "its end and not re-sorted by when each event happened")
        XCTAssertEqual(page.records.map(\.sequence).sorted(), page.records.map(\.sequence),
                       "and the sequences it hands back ascend, which is what makes "
                       + "nextSequence a safe cursor")
    }

    func testDayFilterComposesWithTheCursor() throws {
        try insert("one", at: noon(2026, 8, 20))
        try insert("two", at: noon(2026, 8, 20).addingTimeInterval(60))
        try insert("three", at: noon(2026, 8, 20).addingTimeInterval(120))

        let first = try store.events(ContextEventQuery(day: "2026-08-20", limit: 2))
        XCTAssertEqual(first.records.map(\.event.summary.subject), ["one", "two"])

        let second = try store.events(ContextEventQuery(
            afterSequence: first.nextSequence, day: "2026-08-20", limit: 2))
        XCTAssertEqual(second.records.map(\.event.summary.subject), ["three"])
        XCTAssertLessThan(second.examined, 2, "a short page is how the caller knows it is done")
    }

    func testDayFilterComposesWithTheKindFilter() throws {
        try insert("focused", at: noon(2026, 8, 20))
        try store.insert(ContextEvent(machineID: machineID,
                                      occurredAt: noon(2026, 8, 20).addingTimeInterval(60),
                                      detail: .session(SessionDetail(change: .lock))))

        let page = try store.events(ContextEventQuery(
            kinds: [.session], day: "2026-08-20", limit: 100))

        XCTAssertEqual(page.records.count, 1)
        XCTAssertEqual(page.records[0].event.kind, ContextEventKind.session)
    }

    func testAnUnparseableDayMatchesNothing() throws {
        try insert("one", at: noon(2026, 8, 20))
        XCTAssertEqual(try store.events(ContextEventQuery(day: "garbage", limit: 100)), .empty)
    }

    /// The store, and only the store, decides what local day a row belongs to.
    ///
    /// `eventDays()` has always grouped by `date(occurred_at, 'localtime')`,
    /// which reads the C library's timezone. The day *filter* used to compute
    /// its bounds in Swift, from `Calendar.current`, which reads Foundation's
    /// own separately cached copy. One process, two caches: they agree right
    /// up until the zone moves under a long-lived daemon, and then the filter
    /// goes looking for a day's rows hours away from where the list files
    /// them, and a day the owner can see in the sidebar opens empty.
    ///
    /// This moves the C library's zone and deliberately leaves Foundation's
    /// cache alone — exactly the state a running daemon reaches after a change
    /// it never restarts for — and asserts the two sides still name the same
    /// day for every row.
    func testTheDayFilterFollowsSQLiteWhenTheProcessTimezoneMovesUnderIt() throws {
        _ = Calendar.current.timeZone.identifier  // cache Foundation's zone first

        // Far enough from the machine's own zone that no hour of the day can
        // land on the same date on both sides.
        let moved = TimeZone.current.secondsFromGMT() > 12 * 3_600
            ? "Pacific/Midway" : "Pacific/Kiritimati"
        try withProcessTimeZone(moved) {
            // A full day of rows, one an hour, so however the two zones
            // disagree, some row falls in the gap.
            for hour in 0..<24 {
                try insert("h\(hour)",
                           at: Date(timeIntervalSince1970: 1_755_648_000 + Double(hour) * 3_600))
            }

            var filtered = 0
            for day in try store.eventDays() {
                let page = try store.events(ContextEventQuery(day: day.day, limit: 100))
                XCTAssertEqual(page.records.count, day.count,
                               "day \(day.day): the day list and the day filter must bucket a "
                               + "row the same way")
                filtered += page.records.count
            }
            XCTAssertEqual(filtered, 24,
                           "every row belongs to exactly one of the days the store lists")
        }
    }

    // MARK: - DST

    /// A local day is not always 86,400 seconds, and two separate pieces of
    /// day arithmetic have to know it: `ContextEventDayKey.endOfDay`, which
    /// uses `Calendar.date(byAdding:)` rather than `+86400` for the Timeline's
    /// display bound, and the store's day filter, which asks SQLite for
    /// `'+1 day'` — calendar arithmetic on the local wall clock, not 86,400
    /// seconds — rather than deciding the boundary itself.
    ///
    /// Every other test in this file sits in August, so none of them would
    /// notice if either were "simplified" back to arithmetic. These two pin
    /// exactly the failure that would cause, against the explicit
    /// `America/New_York` zone, so the result does not depend on where the
    /// suite happens to run. Its 2026 transitions (spring forward March 8,
    /// fall back November 1) were checked against `Calendar`, not assumed.
    private var newYork: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func newYorkTime(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        components.hour = hour; components.minute = minute
        return newYork.date(from: components)!
    }

    /// Runs `body` with the **C library's** idea of local time moved to
    /// `identifier`, restored afterwards whatever happens.
    ///
    /// `TZ` plus `tzset()`, not `NSTimeZone.default`, because SQLite's
    /// `'localtime'` and `'utc'` modifiers read the C library and nothing
    /// else — and the store's day bucketing is SQLite's alone. Setting
    /// Foundation's zone here would move a clock the store never looks at and
    /// prove nothing.
    ///
    /// Deliberately leaves Foundation's own cached zone where it is: that
    /// split is the state a long-lived daemon reaches after a zone change it
    /// never restarts for, and it is what
    /// ``testTheDayFilterFollowsSQLiteWhenTheProcessTimezoneMovesUnderIt``
    /// exists to reproduce.
    private func withProcessTimeZone(_ identifier: String, _ body: () throws -> Void) rethrows {
        let original = getenv("TZ").map { String(cString: $0) }
        defer {
            if let original { setenv("TZ", original, 1) } else { unsetenv("TZ") }
            tzset()
        }
        setenv("TZ", identifier, 1)
        tzset()
        try body()
    }

    func testSpringForwardDayIsTwentyThreeHoursAndTheFilterAgreesWithTheClockNotArithmetic() throws {
        let start = try XCTUnwrap(ContextEventDayKey.startOfDay("2026-03-08", calendar: newYork))
        let end = try XCTUnwrap(ContextEventDayKey.endOfDay("2026-03-08", calendar: newYork))
        XCTAssertEqual(end.timeIntervalSince(start), 23 * 3_600,
                       "clocks spring forward during this day, so it is 23 hours long")

        try withProcessTimeZone("America/New_York") {
            try insert("late-on-the-8th", at: newYorkTime(2026, 3, 8, 23, 30))
            try insert("early-on-the-9th", at: newYorkTime(2026, 3, 9, 0, 30))

            let page = try store.events(ContextEventQuery(day: "2026-03-08", limit: 100))

            XCTAssertEqual(page.records.map(\.event.summary.subject), ["late-on-the-8th"],
                           "+86400 would end this day an hour late and pull in the 9th's first hour")
        }
    }

    func testFallBackDayIsTwentyFiveHoursAndTheFilterAgreesWithTheClockNotArithmetic() throws {
        let start = try XCTUnwrap(ContextEventDayKey.startOfDay("2026-11-01", calendar: newYork))
        let end = try XCTUnwrap(ContextEventDayKey.endOfDay("2026-11-01", calendar: newYork))
        XCTAssertEqual(end.timeIntervalSince(start), 25 * 3_600,
                       "clocks fall back during this day, so it is 25 hours long")

        try withProcessTimeZone("America/New_York") {
            try insert("late-on-the-1st", at: newYorkTime(2026, 11, 1, 23, 30))

            let page = try store.events(ContextEventQuery(day: "2026-11-01", limit: 100))

            XCTAssertEqual(page.records.map(\.event.summary.subject), ["late-on-the-1st"],
                           "+86400 would end this day an hour early and drop it")
        }
    }

    // MARK: - Wire compatibility

    func testAQueryWithNoDayKeyStillDecodes() throws {
        let json = Data(#"{"limit":500}"#.utf8)
        let query = try JSONDecoder().decode(ContextEventQuery.self, from: json)
        XCTAssertNil(query.day)
        XCTAssertEqual(query.limit, 500)
    }

    // MARK: - Day index

    func testEventDaysIsEmptyForAnEmptyLog() throws {
        XCTAssertEqual(try store.eventDays(), [])
    }

    func testEventDaysCountsEachLocalDayNewestFirst() throws {
        try insert("a", at: noon(2026, 8, 18))
        try insert("b", at: noon(2026, 8, 20))
        try insert("c", at: noon(2026, 8, 20).addingTimeInterval(3_600))
        try insert("d", at: noon(2026, 8, 20).addingTimeInterval(7_200))

        XCTAssertEqual(try store.eventDays(), [
            ContextEventDay(day: "2026-08-20", count: 3),
            ContextEventDay(day: "2026-08-18", count: 1)
        ])
    }

    func testEventDaysAgreesWithTheDayFilter() throws {
        try insert("a", at: noon(2026, 8, 20))
        try insert("b", at: noon(2026, 8, 21))

        let days = try store.eventDays()
        XCTAssertEqual(days.count, 2,
                       "the loop below asserts nothing if the list it walks is empty")

        for day in days {
            let page = try store.events(ContextEventQuery(day: day.day, limit: 100))
            XCTAssertEqual(page.records.count, day.count,
                           "the index and the filter must bucket a row the same way")
        }
    }

    func testEventDaysRoundTripsThroughJSON() throws {
        let days = [ContextEventDay(day: "2026-08-20", count: 3)]
        let data = try JSONEncoder().encode(days)
        XCTAssertEqual(try JSONDecoder().decode([ContextEventDay].self, from: data), days)
    }
}
#endif
