#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

@MainActor
private final class FakeAppLifecycleSource: AppLifecycleSource {
    var onChange: ((AppLifecycleChange, AppInfo) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func emit(_ change: AppLifecycleChange, _ app: AppInfo) { onChange?(change, app) }
}

@MainActor
final class AppLifecycleTriggerTests: XCTestCase {
    private final class Recorder { var details: [AppLifecycleDetail] = []; var dates: [Date] = [] }

    private let fixedNow = Date(timeIntervalSince1970: 9_000)

    private func makeTrigger() -> (AppLifecycleTrigger, FakeAppLifecycleSource, Recorder) {
        let source = FakeAppLifecycleSource()
        let trigger = AppLifecycleTrigger(source: source, now: { self.fixedNow })
        let recorder = Recorder()
        trigger.onEvent = { detail, at in
            if case .appLifecycle(let d) = detail { recorder.details.append(d) }
            recorder.dates.append(at)
        }
        return (trigger, source, recorder)
    }

    private let xcode = AppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", pid: 501)

    func testDeclaresItsKindAndNeedsNoPermission() {
        let (trigger, _, _) = makeTrigger()
        XCTAssertEqual(trigger.kind, ContextEventKind.appLifecycle)
        XCTAssertEqual(trigger.requiredPermission, ContextPermission.none,
                       "NSWorkspace application notifications are not TCC-gated")
    }

    func testReportsLaunchAndTerminateWithTheAppIdentity() throws {
        let (trigger, source, recorder) = makeTrigger()
        try trigger.start()

        source.emit(.launched, xcode)
        source.emit(.terminated, xcode)

        XCTAssertEqual(recorder.details, [
            AppLifecycleDetail(change: .launched, bundleID: "com.apple.dt.Xcode",
                               appName: "Xcode", pid: 501),
            AppLifecycleDetail(change: .terminated, bundleID: "com.apple.dt.Xcode",
                               appName: "Xcode", pid: 501)
        ])
        XCTAssertEqual(recorder.dates, [fixedNow, fixedNow])
    }

    func testStartIsIdempotent() throws {
        let (trigger, source, _) = makeTrigger()
        try trigger.start()
        try trigger.start()
        XCTAssertEqual(source.startCount, 1, "a doubled registration doubles every event")
    }

    func testStopDetachesAndEndsEmission() throws {
        let (trigger, source, recorder) = makeTrigger()
        try trigger.start()
        source.emit(.launched, xcode)

        trigger.stop()
        XCTAssertEqual(source.stopCount, 1)
        XCTAssertNil(source.onChange, "stop() must detach, not merely stop")

        source.emit(.terminated, xcode)
        XCTAssertEqual(recorder.details.count, 1, "nothing may be emitted after stop()")
    }

    // MARK: - Identity

    // `report(_:_:)` cannot be exercised directly — there is no way to build an
    // `NSRunningApplication` with a missing bundle id — so these run against
    // the rule it applies.

    func testAnApplicationWithNoBundleIDIsDroppedRatherThanNamedEmpty() {
        XCTAssertNil(SystemAppLifecycleSource.identity(bundleID: nil, name: "helper", pid: 7),
                     "a row that cannot say which app it is about is worse than no row")
        XCTAssertNil(SystemAppLifecycleSource.identity(bundleID: "", name: "helper", pid: 7),
                     "an empty bundle id is not a weaker identity, it is no identity")
    }

    func testAMissingNameFallsBackToTheBundleIDRatherThanASentinel() {
        let app = SystemAppLifecycleSource.identity(bundleID: "com.example.tool", name: nil, pid: 7)
        XCTAssertEqual(app, AppInfo(bundleID: "com.example.tool", name: "com.example.tool", pid: 7),
                       "the app is still identified, so the event is kept — and \"\" and "
                       + "\"unknown\" are both values a later GROUP BY would treat as an app")
        XCTAssertEqual(SystemAppLifecycleSource.identity(bundleID: "com.example.tool",
                                                        name: "", pid: 7),
                       app, "an empty name is a missing name")
    }

    func testAFullyIdentifiedApplicationIsPassedThrough() {
        XCTAssertEqual(SystemAppLifecycleSource.identity(bundleID: "com.apple.dt.Xcode",
                                                         name: "Xcode", pid: 501),
                       xcode)
    }

    func testStopIsIdempotent() throws {
        let (trigger, source, _) = makeTrigger()
        try trigger.start()
        trigger.stop()
        trigger.stop()
        XCTAssertEqual(source.stopCount, 1)
    }
}
#endif
