import XCTest
@testable import AgenticToolkitActivity

/// M-2/M-3: one format for every store, and a reader that still understands
/// the whole-second strings already sitting in existing databases.
final class ISO8601TimestampTests: XCTestCase {
    func testWritesUTCWithFractionalSeconds() {
        XCTAssertEqual(ISO8601Timestamp.string(from: Date(timeIntervalSince1970: 1_700_000_000.25)),
                       "2023-11-14T22:13:20.250Z")
    }

    func testReadsTheFractionalFormItWrites() {
        let reader = ISO8601Timestamp.makeReader()
        XCTAssertEqual(reader.date(from: "2023-11-14T22:13:20.250Z"),
                       Date(timeIntervalSince1970: 1_700_000_000.25))
    }

    /// A strict fractional-only `ISO8601DateFormatter` returns `nil` here, and
    /// `UsageStore.segments` drops a row whose timestamp will not parse — so
    /// without the fallback this change would silently discard every row
    /// written before it.
    func testReadsTheWholeSecondFormWrittenBeforeFractionalSeconds() {
        let reader = ISO8601Timestamp.makeReader()
        XCTAssertEqual(reader.date(from: "2023-11-14T22:13:20Z"),
                       Date(timeIntervalSince1970: 1_700_000_000))
    }

    func testRejectsSomethingThatIsNotATimestamp() {
        XCTAssertNil(ISO8601Timestamp.makeReader().date(from: "not a timestamp"))
    }
}
