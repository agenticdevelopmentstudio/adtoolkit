#if os(macOS)
import AppKit
import XCTest
import AgenticToolkitMacOS
import AgenticToolkitPermissions
@testable import AgenticToolkitActivity

/// An `NSRunningApplication` cannot be constructed, so the fake's frontmost app
/// is the test process itself; assertions compare against its own identity.
private struct FakeRunningApps: RunningAppsProvider {
    var runningApplications: [NSRunningApplication] { [NSRunningApplication.current] }
    func runningApplications(withBundleIdentifier bundleID: String) -> [NSRunningApplication] { [] }
    var frontmostApplication: NSRunningApplication? { NSRunningApplication.current }
}

/// A frontmost app that claims to be iTerm2, so the terminal path is the one
/// under test. `NSRunningApplication` is subclassable only for its overridable
/// properties, which is all `emit()` reads.
private final class FakeTerminalApp: NSRunningApplication, @unchecked Sendable {
    override var bundleIdentifier: String? { "com.googlecode.iterm2" }
    override var localizedName: String? { "iTerm2" }
    override var processIdentifier: pid_t { 4242 }
}

private struct FakeTerminalApps: RunningAppsProvider {
    var runningApplications: [NSRunningApplication] { [] }
    func runningApplications(withBundleIdentifier bundleID: String) -> [NSRunningApplication] { [] }
    var frontmostApplication: NSRunningApplication? { FakeTerminalApp() }
}

private final class RecordingProbe: AutomationProbing, @unchecked Sendable {
    private(set) var calls = 0
    func permissionStatus(forBundleID bundleID: String, promptIfNeeded: Bool) -> OSStatus {
        calls += 1
        return 0
    }
}

@MainActor
private final class RecordingRunner: TerminalScriptRunning {
    private(set) var calls = 0
    func run(_ source: String) -> String? { calls += 1; return "/tmp/proj" }
}

@MainActor
final class FrontmostFocusAdapterReadsWindowsTests: XCTestCase {
    private var expectedBundleID: String { NSRunningApplication.current.bundleIdentifier ?? "unknown" }

    func testReadsWindowsFalseNeverReadsAX() {
        var reads = 0
        let adapter = FrontmostFocusAdapter(
            readsWindows: false,
            windowReader: { _, _ in reads += 1; return .init(title: "T", documentPath: "/x", url: "u") },
            apps: FakeRunningApps())
        var seen: WindowFocus?
        adapter.onFocus = { seen = $0 }
        adapter.emit()
        XCTAssertEqual(reads, 0)
        XCTAssertEqual(seen?.app.bundleID, expectedBundleID)
        XCTAssertEqual(seen?.windowID, 0)
        XCTAssertEqual(seen?.title, "")
        XCTAssertNil(seen?.documentPath)
        XCTAssertNil(seen?.url)
        XCTAssertFalse(adapter.readsWindows)
    }

    func testReadsWindowsTrueUsesTheReader() {
        let adapter = FrontmostFocusAdapter(
            readsWindows: true,
            windowReader: { _, _ in .init(windowID: 7, title: "Proj — main.swift", documentPath: "/r/main.swift") },
            apps: FakeRunningApps())
        var seen: WindowFocus?
        adapter.onFocus = { seen = $0 }
        adapter.emit()
        XCTAssertEqual(seen?.documentPath, "/r/main.swift")
        XCTAssertEqual(seen?.title, "Proj — main.swift")
        XCTAssertEqual(seen?.windowID, 7)
    }

    func testDefaultInitReadsWindows() {
        XCTAssertTrue(FrontmostFocusAdapter().readsWindows)
    }

    func testAppOnlyStartEmitsAndStopsCleanly() {
        var reads = 0
        let adapter = FrontmostFocusAdapter(
            readsWindows: false,
            windowReader: { _, _ in reads += 1; return .init() },
            apps: FakeRunningApps())
        var count = 0
        adapter.onFocus = { _ in count += 1 }
        adapter.start()
        adapter.poll()
        adapter.stop()
        XCTAssertEqual(count, 2)
        XCTAssertEqual(reads, 0)
    }

    func testAppOnlyNeverTouchesTerminalReaderEvenForATerminal() {
        let probe = RecordingProbe()
        let runner = RecordingRunner()
        let adapter = FrontmostFocusAdapter(
            readsWindows: false,
            windowReader: { _, _ in .init(title: "T") },
            apps: FakeTerminalApps(),
            terminals: TerminalWorkingDirectoryReader(probe: probe, runner: runner))
        var seen: WindowFocus?
        adapter.onFocus = { seen = $0 }
        adapter.start()
        adapter.poll()
        adapter.stop()
        XCTAssertEqual(seen?.app.bundleID, "com.googlecode.iterm2")
        XCTAssertNil(seen?.documentPath)
        XCTAssertEqual(probe.calls, 0)
        XCTAssertEqual(runner.calls, 0)
    }
}
#endif
