#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

@MainActor
final class WindowLifecycleContextTriggerTests: XCTestCase {
    private func makeTrigger() -> (WindowLifecycleContextTrigger, FakeWindowSource) {
        let source = FakeWindowSource()
        return (WindowLifecycleContextTrigger(source: source,
                                              now: { Date(timeIntervalSince1970: 6_000) }),
                source)
    }

    func testDeclaresItsKindAndPermission() {
        let (t, _) = makeTrigger()
        XCTAssertEqual(t.kind, ContextEventKind.window)
        XCTAssertEqual(t.requiredPermission, ContextPermission.accessibility)
    }

    func testMapsEveryLifecycleKindOntoAWindowChange() throws {
        let (t, source) = makeTrigger()
        var captured: [WindowDetail] = []
        t.onEvent = { d, _ in
            if case .window(let w) = d { captured.append(w) }
        }
        try t.start()
        let app = AppInfo(bundleID: "b", name: "A", pid: 1)
        source.emit(.created, app, 11, "One")
        source.emit(.titleChanged, app, 11, "Two")
        source.emit(.destroyed, app, 11, "")

        XCTAssertEqual(captured.map(\.change), [.created, .titleChanged, .destroyed])
        XCTAssertEqual(captured.map(\.windowID), [11, 11, 11])
        XCTAssertEqual(captured[0].windowTitle, "One")
        XCTAssertNil(captured[2].windowTitle, "an empty title is an absence, not a title")
        XCTAssertEqual(captured[0].bundleID, "b")
        XCTAssertEqual(captured[0].pid, 1)
    }

    func testStopEndsEmission() throws {
        let (t, source) = makeTrigger()
        var count = 0
        t.onEvent = { _, _ in count += 1 }
        try t.start()
        source.emit(.created, AppInfo(bundleID: "b", name: "A", pid: 1), 1, "T")
        t.stop()
        source.emit(.created, AppInfo(bundleID: "b", name: "A", pid: 1), 2, "T")
        XCTAssertEqual(count, 1)
    }
}
#endif
