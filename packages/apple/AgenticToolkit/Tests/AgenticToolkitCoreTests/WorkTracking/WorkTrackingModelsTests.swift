import XCTest
@testable import AgenticToolkitCore

final class WorkTrackingModelsTests: XCTestCase {
    func testNormalizedSortsDedupsAndClamps() {
        let prefs = WorkTrackingPreferences(enabled: true, addedBundleIds: ["b", "a", "b"],
                                            removedBundleIds: ["z", "z"], retentionDays: 1).normalized()
        XCTAssertEqual(prefs.addedBundleIds, ["a", "b"])
        XCTAssertEqual(prefs.removedBundleIds, ["z"])
        XCTAssertEqual(prefs.retentionDays, 7)
        XCTAssertEqual(WorkTrackingPreferences(enabled: true, addedBundleIds: [], removedBundleIds: [],
                                               retentionDays: 99_999).normalized().retentionDays, 3650)
    }

    func testSpanSessionIdRoundTrips() {
        XCTAssertEqual(ActivitySpanSession.sessionId(spanId: "X"), "app:X")
        XCTAssertEqual(ActivitySpanSession.spanId(sessionId: "app:X"), "X")
        XCTAssertNil(ActivitySpanSession.spanId(sessionId: "claude-session"))
    }

    func testDegradedOnlyWhenEnabledWithoutGrant() {
        XCTAssertFalse(WorkTrackingStatus(enabled: false, accessibility: .denied).isDegraded)
        XCTAssertTrue(WorkTrackingStatus(enabled: true, accessibility: .denied).isDegraded)
        XCTAssertTrue(WorkTrackingStatus(enabled: true, accessibility: .unknown).isDegraded)
        XCTAssertFalse(WorkTrackingStatus(enabled: true, accessibility: .granted).isDegraded)
    }

    func testStatusRoundTripsSnakeCase() throws {
        let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let status = WorkTrackingStatus(enabled: true, accessibility: .granted, currentSpan: ActivitySpanDTO(
            id: "s", bundleId: "com.apple.dt.Xcode", appName: "Xcode", startedAt: "2026-10-01T09:00:00Z", tz: "UTC"),
            writeFailures: 2, lastError: "disk full")
        XCTAssertEqual(try decoder.decode(WorkTrackingStatus.self, from: encoder.encode(status)), status)
    }
}
