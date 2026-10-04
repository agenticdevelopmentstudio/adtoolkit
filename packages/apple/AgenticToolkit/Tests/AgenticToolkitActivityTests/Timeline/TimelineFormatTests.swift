import XCTest
@testable import AgenticToolkitActivity

/// `TimelineFormat`'s two pure rules: `formatted(duration:)` — whole units
/// only, never more than two of them, minutes never zero-padded — and
/// `eventTime(_:calendar:)` — `HH:mm:ss` in a pinned time zone.
final class TimelineFormatTests: XCTestCase {

    // MARK: - formatted(duration:)

    func testZeroDurationFormatsAsZeroSeconds() {
        XCTAssertEqual(TimelineFormat.formatted(duration: 0), "0s")
    }

    func testSubMinuteDurationFormatsInSeconds() {
        XCTAssertEqual(TimelineFormat.formatted(duration: 45), "45s")
    }

    func testExactlyOneHourFormatsWithZeroMinutes() {
        XCTAssertEqual(TimelineFormat.formatted(duration: 3_600), "1h 0m",
                        "an exact hour still states its zero minutes rather than dropping them")
    }

    func testMinutesAreNotZeroPadded() {
        // 1h 5m: a single-digit minute count reads "5m", not "05m".
        XCTAssertEqual(TimelineFormat.formatted(duration: 3_900), "1h 5m")
    }

    func testMultiHourDurationDropsSeconds() {
        // 2h 30m 45s: the hours branch shows only hours and minutes.
        XCTAssertEqual(TimelineFormat.formatted(duration: 9_045), "2h 30m")
    }

    /// The branch most rows in a real day actually land in: no hours, but at
    /// least one minute. An implementation that dropped the seconds term here
    /// (`"\(minutes)m"`) would still pass every other test in this file.
    func testTwoUnitBranchIncludesBothMinutesAndSeconds() {
        XCTAssertEqual(TimelineFormat.formatted(duration: 90), "1m 30s")
    }

    /// A single-digit seconds term inside the two-unit branch, which is the
    /// one place a stray zero-pad could hide: every other test in this file
    /// happens to use a two-digit seconds value or none at all, so `"1m 05s"`
    /// would pass all of them.
    func testASingleDigitSecondsTermIsNotZeroPadded() {
        XCTAssertEqual(TimelineFormat.formatted(duration: 65), "1m 5s")
    }

    /// `duration.rounded()`, not truncation: 59.6s is a hair under a minute
    /// but rounds up to one, carrying the minutes/seconds split with it.
    func testFractionalSecondsRoundUpAcrossAMinuteBoundary() {
        XCTAssertEqual(TimelineFormat.formatted(duration: 59.6), "1m 0s")
    }

    func testFractionalSecondsBelowHalfRoundDownToZero() {
        XCTAssertEqual(TimelineFormat.formatted(duration: 0.4), "0s")
    }

    // MARK: - eventTime(_:calendar:)

    /// Pinned against an explicit `America/New_York` calendar, the same
    /// discipline `TimelineDayInputTests` uses, so the result does not depend
    /// on where the suite happens to run.
    private var newYork: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    func testEventTimeFormatsAsZeroPaddedHHMMSSInThePinnedZone() {
        var components = DateComponents()
        components.year = 2026; components.month = 8; components.day = 20
        components.hour = 9; components.minute = 5; components.second = 3
        components.timeZone = newYork.timeZone
        let date = newYork.date(from: components)!

        XCTAssertEqual(TimelineFormat.eventTime(date, calendar: newYork), "09:05:03")
    }

    func testEventTimeUsesTwentyFourHourClock() {
        var components = DateComponents()
        components.year = 2026; components.month = 8; components.day = 20
        components.hour = 22; components.minute = 30; components.second = 0
        components.timeZone = newYork.timeZone
        let date = newYork.date(from: components)!

        XCTAssertEqual(TimelineFormat.eventTime(date, calendar: newYork), "22:30:00")
    }
}
