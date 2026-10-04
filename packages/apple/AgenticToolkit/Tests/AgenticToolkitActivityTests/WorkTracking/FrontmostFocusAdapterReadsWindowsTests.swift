#if os(macOS)
import AppKit
import XCTest
import AgenticToolkitMacOS
@testable import AgenticToolkitActivity

/// An `NSRunningApplication` cannot be constructed, so the fake's frontmost app
/// is the test process itself; assertions compare against its own identity.
private struct FakeRunningApps: RunningAppsProvider {
    var runningApplications: [NSRunningApplication] { [NSRunningApplication.current] }
    func runningApplications(withBundleIdentifier bundleID: String) -> [NSRunningApplication] { [] }
    var frontmostApplication: NSRunningApplication? { NSRunningApplication.current }
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
}
#endif
