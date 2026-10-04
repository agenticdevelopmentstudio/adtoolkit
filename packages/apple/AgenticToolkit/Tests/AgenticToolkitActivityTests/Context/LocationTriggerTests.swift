#if os(macOS)
import CoreLocation
import XCTest
@testable import AgenticToolkitActivity

@MainActor
private final class FakeLocationSource: LocationSource {
    var onLocation: ((LocationDetail, Date) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func emit(_ d: LocationDetail, at date: Date = Date(timeIntervalSince1970: 1_500)) {
        onLocation?(d, date)
    }
}

@MainActor
final class LocationTriggerTests: XCTestCase {
    private func makeTrigger() -> (LocationTrigger, FakeLocationSource, () -> [LocationDetail]) {
        let source = FakeLocationSource()
        let t = LocationTrigger(source: source)
        let rec = Recorder()
        t.onEvent = { d, _ in if case .location(let l) = d { rec.details.append(l) } }
        return (t, source, { rec.details })
    }

    private final class Recorder { var details: [LocationDetail] = [] }

    func testDeclaresItsKindAndRequiresLocation() {
        let (t, _, _) = makeTrigger()
        XCTAssertEqual(t.kind, ContextEventKind.location)
        XCTAssertEqual(t.requiredPermission, ContextPermission.location)
    }

    func testForwardsEveryFixWithFullResolution() throws {
        let (t, source, details) = makeTrigger()
        try t.start()
        source.emit(LocationDetail(latitude: 47.6062, longitude: -122.3321,
                                   horizontalAccuracy: 5, altitude: 40,
                                   verticalAccuracy: 3, speed: 1.2, course: 90))
        XCTAssertEqual(details().count, 1)
        XCTAssertEqual(details()[0].latitude, 47.6062, accuracy: 0.000001)
        XCTAssertEqual(details()[0].longitude, -122.3321, accuracy: 0.000001)
        XCTAssertEqual(details()[0].horizontalAccuracy, 5)
        XCTAssertEqual(details()[0].speed, 1.2)
    }

    func testDoesNotDeduplicateSuccessiveFixes() throws {
        // Every fix is data — a repeated coordinate still tells us the user
        // stayed put across that interval, which is exactly the dwell signal.
        let (t, source, details) = makeTrigger()
        try t.start()
        let fix = LocationDetail(latitude: 1, longitude: 2, horizontalAccuracy: 10,
                                 altitude: nil, verticalAccuracy: nil, speed: nil, course: nil)
        source.emit(fix); source.emit(fix)
        XCTAssertEqual(details().count, 2)
    }

    func testStartsAndStopsTheUnderlyingSource() throws {
        let (t, source, details) = makeTrigger()
        try t.start()
        XCTAssertEqual(source.startCount, 1)
        t.stop()
        XCTAssertEqual(source.stopCount, 1)
        source.emit(LocationDetail(latitude: 1, longitude: 2, horizontalAccuracy: nil,
                                   altitude: nil, verticalAccuracy: nil, speed: nil, course: nil))
        XCTAssertEqual(details().count, 0)
    }

    // `startUpdatingLocation()` characteristically delivers a cached fix
    // immediately, which can be minutes or hours old. A bug that stamped
    // events with the arrival time (e.g. a reinstated `now()`) would record
    // "the user is here now" for a place they were at yesterday — this test
    // fails if that regresses, because `Date()` at test-run time will never
    // equal this 1970 timestamp.
    func testEmitsEventUsingTheFixesOwnTimestampNotArrivalTime() throws {
        let source = FakeLocationSource()
        let t = LocationTrigger(source: source)
        var capturedDates: [Date] = []
        t.onEvent = { d, date in if case .location = d { capturedDates.append(date) } }
        try t.start()
        let staleTimestamp = Date(timeIntervalSince1970: 1_000)
        source.emit(LocationDetail(latitude: 1, longitude: 2, horizontalAccuracy: 5,
                                   altitude: nil, verticalAccuracy: nil, speed: nil, course: nil),
                    at: staleTimestamp)
        XCTAssertEqual(capturedDates, [staleTimestamp])
    }

    // Deferred/batched delivery carries several fixes with distinct times. A
    // bug that captured a single date once (e.g. at batch-start) and reused
    // it for every fix in the batch, or that reordered events, would fail
    // this.
    func testEachFixInASequenceCarriesItsOwnDateInOrder() throws {
        let source = FakeLocationSource()
        let t = LocationTrigger(source: source)
        var capturedDates: [Date] = []
        t.onEvent = { d, date in if case .location = d { capturedDates.append(date) } }
        try t.start()
        let fix = LocationDetail(latitude: 1, longitude: 2, horizontalAccuracy: 5,
                                 altitude: nil, verticalAccuracy: nil, speed: nil, course: nil)
        let first = Date(timeIntervalSince1970: 100)
        let second = Date(timeIntervalSince1970: 200)
        source.emit(fix, at: first)
        source.emit(fix, at: second)
        XCTAssertEqual(capturedDates, [first, second])
    }
}

/// `LocationTrigger` (above) only ever sees whatever `LocationDetail`/`Date`
/// pair its `LocationSource` hands it — the fakes forward values unchanged,
/// so none of them exercise the negative-sentinel-to-nil mapping or the
/// batch-processing behaviour that live in
/// `SystemLocationSource.locationManager(_:didUpdateLocations:)`. These tests
/// drive that mapping directly by calling the delegate method with
/// hand-built `CLLocation`s — never `start()`, so no TCC prompt and no
/// dependency on real location services.
@MainActor
final class SystemLocationSourceSentinelTests: XCTestCase {
    private func makeLocation(altitude: Double = 10, horizontalAccuracy: Double,
                              verticalAccuracy: Double, course: Double, speed: Double,
                              timestamp: Date = Date()) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2),
                  altitude: altitude, horizontalAccuracy: horizontalAccuracy,
                  verticalAccuracy: verticalAccuracy, course: course, speed: speed,
                  timestamp: timestamp)
    }

    private func captureDetails(from locations: [CLLocation]) -> [(LocationDetail, Date)] {
        let source = SystemLocationSource()
        var captured: [(LocationDetail, Date)] = []
        source.onLocation = { detail, date in captured.append((detail, date)) }
        source.locationManager(CLLocationManager(), didUpdateLocations: locations)
        return captured
    }

    private func captureDetail(from location: CLLocation) -> LocationDetail? {
        captureDetails(from: [location]).first?.0
    }

    // A negative horizontalAccuracy means CoreLocation considers the
    // COORDINATE itself invalid, not just the accuracy figure.
    // `LocationDetail.latitude`/`.longitude` are non-optional, so there is no
    // way to record "position unknown" in a row — the only correct move is
    // to drop the fix entirely. A bug that emitted a detail anyway (garbage
    // coordinate, nil accuracy) would fail the count assertion here; a bug
    // that let the invalid fix abort the rest of the batch would fail the
    // second assertion.
    func testNegativeHorizontalAccuracyDropsTheFixButNotTheRestOfTheBatch() {
        let invalid = makeLocation(horizontalAccuracy: -1, verticalAccuracy: 3, course: 90, speed: 1)
        let valid = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 1)
        let details = captureDetails(from: [invalid, valid])
        XCTAssertEqual(details.count, 1)
        XCTAssertEqual(details[0].0.horizontalAccuracy, 5)
    }

    // A bug that always mapped the field to nil regardless of the reading
    // would also make the test above pass vacuously; this pins the opposite
    // case.
    func testNonNegativeHorizontalAccuracyPassesThrough() {
        let loc = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 1)
        XCTAssertEqual(captureDetail(from: loc)?.horizontalAccuracy, 5)
    }

    // A bug that gated `altitude` on its own value (CLLocation has no
    // "invalid altitude" sentinel of its own) instead of on
    // `verticalAccuracy` — the field CoreLocation actually uses to signal an
    // invalid altitude — would let a stale/garbage altitude through whenever
    // verticalAccuracy is negative.
    func testNegativeVerticalAccuracyMapsBothAltitudeAndVerticalAccuracyToNil() {
        let loc = makeLocation(altitude: 40, horizontalAccuracy: 5, verticalAccuracy: -1, course: 90, speed: 1)
        let detail = captureDetail(from: loc)
        XCTAssertNil(detail?.altitude)
        XCTAssertNil(detail?.verticalAccuracy)
    }

    func testNonNegativeVerticalAccuracyPassesThroughAltitudeAndVerticalAccuracy() {
        let loc = makeLocation(altitude: 40, horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 1)
        let detail = captureDetail(from: loc)
        XCTAssertEqual(detail?.altitude, 40)
        XCTAssertEqual(detail?.verticalAccuracy, 3)
    }

    func testNegativeSpeedMapsToNil() {
        let loc = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: -1)
        XCTAssertNil(captureDetail(from: loc)?.speed)
    }

    func testNonNegativeSpeedPassesThrough() {
        let loc = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 1.2)
        XCTAssertEqual(captureDetail(from: loc)?.speed, 1.2)
    }

    func testNegativeCourseMapsToNil() {
        let loc = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: -1, speed: 1)
        XCTAssertNil(captureDetail(from: loc)?.course)
    }

    func testNonNegativeCoursePassesThrough() {
        let loc = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 1)
        XCTAssertEqual(captureDetail(from: loc)?.course, 90)
    }

    // The real batch-delivery mechanism: `didUpdateLocations` hands over an
    // array. A bug that computed one date for the whole call (e.g. `Date()`
    // read once outside the loop) instead of using each location's own
    // `timestamp`, or that dropped/reordered entries, would fail this.
    func testBatchOfLocationsEachEmitWithItsOwnTimestampInOrder() {
        let first = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 1,
                                 timestamp: Date(timeIntervalSince1970: 100))
        let second = makeLocation(horizontalAccuracy: 5, verticalAccuracy: 3, course: 90, speed: 1,
                                  timestamp: Date(timeIntervalSince1970: 200))
        let results = captureDetails(from: [first, second])
        XCTAssertEqual(results.map { $0.1 }, [Date(timeIntervalSince1970: 100), Date(timeIntervalSince1970: 200)])
    }
}
#endif
