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

    /// Review D1: a stored grant holds only under the signature it was
    /// recorded under; a denial holds under any.
    func testAStoredGrantIsTrustedOnlyUnderItsOwnSignature() throws {
        let store = SettingsDictionary()
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: "A", store)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(store, signer: "A"), .granted)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(store, signer: "B"), .unknown)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(store, signer: nil), .unknown)
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(store), .granted, "the raw answer is kept")

        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: nil, store)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(store, signer: ""), .unknown,
                       "no recorded signature matches nothing, an empty one included")

        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: "A", store)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(store, signer: "B"), .denied)
    }

    /// The signature the grant is checked against is readable from a signed
    /// test host, and asks nothing of TCC.
    func testOwnDesignatedRequirementIsReadable() {
        XCTAssertFalse(OwnCodeSignature.designatedRequirement()?.isEmpty ?? true)
    }
}

/// Work-tracking settings in a dictionary.
private final class SettingsDictionary: WorkTrackingSettingsStore {
    private var values: [String: String] = [:]
    func setting(for key: String) throws -> String? { values[key] }
    func setSetting(_ key: String, _ value: String) throws { values[key] = value }
    func transaction<T>(_ body: () throws -> T) throws -> T { try body() }
}
