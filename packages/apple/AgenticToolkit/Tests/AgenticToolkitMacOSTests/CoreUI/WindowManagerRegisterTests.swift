import AppKit
import XCTest
@testable import AgenticToolkitMacOS

/// The host registers every window the same way; whether one reopens at launch
/// is decided by its own `WindowSpec`, chosen where the window is built. These
/// tests pin that the host's `register(id:make:)` carries no restore decision.
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

    func testRegisteredWindowsReopenByTheirOwnSpec() {
        let manager = WindowManager.shared
        let defaultID = "test.register.default.\(UUID().uuidString)"
        let optedOutID = "test.register.optout.\(UUID().uuidString)"
        var reopens: TestWC?
        var staysShut: TestWC?
        defer {
            reopens?.close()
            staysShut?.close()
            manager.frames.clearVisibility(for: defaultID)
            manager.frames.clearVisibility(for: optedOutID)
        }

        // Last session: both windows were open when the app quit.
        let lastReopens = TestWC(windowID: defaultID, behavior: .default)
        let lastStaysShut = TestWC(
            windowID: optedOutID, behavior: WindowSpec.Behavior.default.subtracting(.persistsVisibility)
        )
        lastReopens.showWindow()
        lastStaysShut.showWindow()
        manager.isTerminating = true
        lastReopens.window?.orderOut(nil)
        lastStaysShut.window?.orderOut(nil)
        manager.isTerminating = false

        // This launch: the host registers both identically. Each factory's new
        // controller replaces last session's in the registry under the same id.
        manager.register(id: defaultID) { reopens = TestWC(windowID: defaultID, behavior: .default) }
        manager.register(id: optedOutID) {
            staysShut = TestWC(
                windowID: optedOutID, behavior: WindowSpec.Behavior.default.subtracting(.persistsVisibility)
            )
        }
        manager.restoreOnLaunch()

        XCTAssertEqual(reopens?.isVisible, true, "a default window left open reopens")
        XCTAssertEqual(staysShut?.isVisible, false, "a window built without .persistsVisibility stays shut")
    }
}
