import XCTest
@testable import AgenticToolkitCore

final class UTCDayTests: XCTestCase {

    func testStringFromEpochIsUTC() {
        XCTAssertEqual(UTCDay.string(from: Date(timeIntervalSince1970: 0)), "1970-01-01")
        // 1700000000 = 2023-11-14T22:13:20Z → UTC day 2023-11-14 (not the local-time day).
        XCTAssertEqual(UTCDay.string(from: Date(timeIntervalSince1970: 1_700_000_000)), "2023-11-14")
    }

    func testDayAfterSimple() {
        XCTAssertEqual(UTCDay.dayAfter("2026-06-19"), "2026-06-20")
    }

    func testDayAfterMonthBoundary() {
        XCTAssertEqual(UTCDay.dayAfter("2026-01-31"), "2026-02-01")
    }

    func testDayAfterYearBoundary() {
        XCTAssertEqual(UTCDay.dayAfter("2026-12-31"), "2027-01-01")
    }

    func testDayAfterLeapDay() {
        XCTAssertEqual(UTCDay.dayAfter("2024-02-28"), "2024-02-29")   // 2024 is a leap year
        XCTAssertEqual(UTCDay.dayAfter("2024-02-29"), "2024-03-01")
        XCTAssertEqual(UTCDay.dayAfter("2026-02-28"), "2026-03-01")   // 2026 is not
    }

    func testDayAfterReturnsInputOnGarbage() {
        XCTAssertEqual(UTCDay.dayAfter("not-a-date"), "not-a-date")
    }
}
