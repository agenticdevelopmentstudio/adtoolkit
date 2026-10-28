import AppKit
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// The host registers every window the same way; whether one reopens at launch
/// is decided by its own `WindowSpec`, chosen where the window is built. These
/// tests pin that the host's `register(id:make:)` carries no restore decision,
/// that only windows saved as visible are built, and that the restore is
/// unconditional: no policy or system preference keeps a window shut.
@MainActor
final class WindowManagerRegisterTests: XCTestCase {

    private final class FakeVC: NSViewController {
        override func loadView() {
            view = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        }
    }

    private final class TestWC: SingleWindowController {
        init(windowID: String, behavior: WindowSpec.Behavior) {
            super.init(windowID: windowID, contentViewController: FakeVC())
            self.windowSpec = WindowSpec(
                defaultSize: NSSize(width: 300, height: 200),
                minSize: NSSize(width: 100, height: 100),
                defaultPosition: .center,
                behavior: behavior
            )
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
    }

    private let manager = WindowManager.shared
    private var ids: [String] = []

    override func tearDown() async throws {
        for id in ids {
            manager.registry.controller(forID: id)?.close()
            manager.frames.clearVisibility(for: id)
        }
        UserSettings.shared.remove(UserSettings.reopenOnLaunchPolicy)
        try await super.tearDown()
    }

    private func usePolicy(_ policy: ReopenOnLaunchPolicy) {
        UserSettings.shared.set(policy, for: UserSettings.reopenOnLaunchPolicy)
    }

    private func newID(_ name: String) -> String {
        let id = "test.register.\(name).\(UUID().uuidString)"
        ids.append(id)
        return id
    }

    /// Records `visible` as last session's state for `id`, the way a default
    /// window does when it is shown or closed.
    private func seedVisibility(_ visible: Bool, for id: String) {
        autoreleasepool {
            let last = TestWC(windowID: id, behavior: .default)
            manager.frames.saveVisibility(visible, for: id)
            _ = last
        }
    }

    func testRegisteredWindowsReopenByTheirOwnSpec() {
        let defaultID = newID("default")
        let optedOutID = newID("optout")
        seedVisibility(true, for: defaultID)
        seedVisibility(true, for: optedOutID)

        var reopens: TestWC?
        var staysShut: TestWC?
        manager.register(id: defaultID) { reopens = TestWC(windowID: defaultID, behavior: .default) }
        manager.register(id: optedOutID) {
            staysShut = TestWC(
                windowID: optedOutID, behavior: WindowSpec.Behavior.default.subtracting(.persistsVisibility)
            )
        }
        manager.restoreOnLaunch()

        XCTAssertEqual(reopens?.isVisible, true, "a default window left open reopens")
        XCTAssertNotNil(staysShut, "a window saved as visible is built so its spec can decide")
        XCTAssertEqual(staysShut?.isVisible, false, "a window built without .persistsVisibility stays shut")
    }

    func testWindowWithoutCanReopenOnLaunchStaysShut() {
        let id = newID("nocanreopen")
        seedVisibility(true, for: id)

        var window: TestWC?
        manager.register(id: id) {
            window = TestWC(windowID: id, behavior: WindowSpec.Behavior.default.subtracting(.canReopenOnLaunch))
        }
        manager.restoreOnLaunch()

        XCTAssertNotNil(window)
        XCTAssertEqual(window?.isVisible, false)
    }

    func testWindowSavedClosedIsNeverBuilt() {
        let closedID = newID("closed")
        let neverShownID = newID("nevershown")
        seedVisibility(false, for: closedID)

        var built: [String] = []
        manager.register(id: closedID) { built.append(closedID) }
        manager.register(id: neverShownID) { built.append(neverShownID) }
        manager.restoreOnLaunch()

        XCTAssertEqual(built, [], "only a window saved as visible is worth building")
    }

    /// The reopen policy governs documents only; "Never" does not keep the
    /// app's own windows shut.
    func testPolicyNeverStillRestoresWindows() {
        let id = newID("policynever")
        seedVisibility(true, for: id)
        usePolicy(.never)

        var window: TestWC?
        manager.register(id: id) { window = TestWC(windowID: id, behavior: .default) }
        manager.restoreOnLaunch()

        XCTAssertEqual(window?.isVisible, true)
    }

    /// Whatever macOS's "Close windows when quitting" says, a window left
    /// open comes back, with no update or build bookkeeping deciding it.
    func testRestoreIsUnconditionalUnderTheSystemPolicy() {
        let id = newID("unconditional")
        seedVisibility(true, for: id)
        usePolicy(.useSystem)

        var window: TestWC?
        manager.register(id: id) { window = TestWC(windowID: id, behavior: .default) }
        manager.restoreOnLaunch()

        XCTAssertEqual(window?.isVisible, true)
    }

    func testUnclaimedVisibleFlagIsReportedAndCleared() {
        let orphanID = newID("orphan")
        seedVisibility(true, for: orphanID)
        XCTAssertTrue(manager.frames.visibleWindowIDs().contains(orphanID), "the default storage lists visible ids")

        manager.restoreOnLaunch()

        XCTAssertNil(manager.frames.savedVisibility(for: orphanID))
        XCTAssertFalse(manager.frames.visibleWindowIDs().contains(orphanID))
    }
}
