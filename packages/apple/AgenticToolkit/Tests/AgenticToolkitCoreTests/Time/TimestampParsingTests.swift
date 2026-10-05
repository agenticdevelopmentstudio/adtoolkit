import XCTest
@testable import AgenticToolkitCore

/// The one shared timestamp parser: every shape that appears across the daemon, app,
/// and CLI must parse — including the SQLite `datetime()` form (UTC, space-separated)
/// that the old per-site ISO-only parsers silently rejected.
final class TimestampParsingTests: XCTestCase {

    func testFractionalMatchesPlainPlusFraction() throws {
        let fractional = try XCTUnwrap(TimestampParsing.parse("2026-04-14T10:00:00.500Z"))
        let plain = try XCTUnwrap(TimestampParsing.parse("2026-04-14T10:00:00Z"))
        XCTAssertEqual(fractional.timeIntervalSince(plain), 0.5, accuracy: 0.001)
    }

    func testSQLiteDateTimeParsedAsUTC() throws {
        // Space-separated, no zone — what SQLite datetime() stores. It must parse, and
        // as UTC (matching how the DB writes it), i.e. the same instant as the Z form —
        // not reinterpreted in the device's local zone.
        let sqlite = try XCTUnwrap(TimestampParsing.parse("2026-04-14 10:00:00"))
        let iso = try XCTUnwrap(TimestampParsing.parse("2026-04-14T10:00:00Z"))
        XCTAssertEqual(sqlite, iso, "SQLite datetime() form is UTC, the same instant as the Z form")
    }

    func testEmptyAndGarbageAreNil() {
        XCTAssertNil(TimestampParsing.parse(""))
        XCTAssertNil(TimestampParsing.parse("not a date"))
        XCTAssertNil(TimestampParsing.parse("2026-13-99"))
    }

    // MARK: - parseISO8601 (review F54)

    func testISO8601AcceptsBothInternetForms() throws {
        let fractional = try XCTUnwrap(TimestampParsing.parseISO8601("2026-10-01T00:00:00.250Z"))
        let plain = try XCTUnwrap(TimestampParsing.parseISO8601("2026-10-01T00:00:00Z"))
        XCTAssertEqual(fractional.timeIntervalSince(plain), 0.25, accuracy: 0.001)
        XCTAssertNotNil(TimestampParsing.parseISO8601("2026-10-01T02:00:00+02:00"))
    }

    /// A bound a caller sends must carry its zone, so the SQLite shape that
    /// `parse` reads from storage is refused here.
    func testISO8601RefusesTheZonelessAndTheMalformed() {
        for text in ["", "2026-10-01 00:00:00", "2026-10-01", "yesterday", "2026-13-01T00:00:00Z"] {
            XCTAssertNil(TimestampParsing.parseISO8601(text), text)
        }
    }
}
