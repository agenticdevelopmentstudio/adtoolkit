import AppKit
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// The host registers every window the same way; whether one reopens at launch
/// is decided by its own `WindowSpec`, chosen where the window is built. These
/// tests pin that the host's `register(id:make:)` carries no restore decision,
/// that only windows saved as visible are built, and that the user's
/// reopen-on-launch policy is honored.
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
    private var savedCurrentBuild: (() -> String)?
    private var savedSystemKeepsWindows: (() -> Bool)?

    override func setUp() async throws {
        try await super.setUp()
        savedCurrentBuild = manager.currentBuild
        savedSystemKeepsWindows = manager.systemKeepsWindows
        manager.hasRestoredThisProcess = false
        usePolicy(.always)
    }

    override func tearDown() async throws {
        for id in ids {
            manager.registry.controller(forID: id)?.close()
            manager.frames.clearVisibility(for: id)
        }
        UserSettings.shared.remove(UserSettings.reopenOnLaunchPolicy)
        UserSettings.shared.remove(UserSettings.lastLaunchedBuilds)
        UserSettings.shared.remove(UserSettings.updateInstallsOnQuit)
        WindowStateNamespace.reset()
        manager.hasRestoredThisProcess = false
        if let savedCurrentBuild { manager.currentBuild = savedCurrentBuild }
        if let savedSystemKeepsWindows { manager.systemKeepsWindows = savedSystemKeepsWindows }
        try await super.tearDown()
    }

    /// A launch of `build` on a machine whose system preference closes windows
    /// on quit — the macOS default — with the policy left at `useSystem`.
    private func launch(build: String) {
        usePolicy(.useSystem)
        manager.systemKeepsWindows = { false }
        manager.currentBuild = { build }
    }

    /// Records `build` as the one this copy of the app last launched.
    private func recordBuild(_ build: String) {
        var builds = UserSettings.lastLaunchedBuilds.currentValue
        builds[WindowStateNamespace.current] = build
        UserSettings.shared.set(builds, for: UserSettings.lastLaunchedBuilds)
    }

    private var recordedBuild: String? {
        UserSettings.lastLaunchedBuilds.currentValue[WindowStateNamespace.current]
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

    func testPolicyNeverRestoresNothing() {
        let id = newID("policynever")
        seedVisibility(true, for: id)
        usePolicy(.never)

        var built = false
        manager.register(id: id) { built = true }
        manager.restoreOnLaunch()

        XCTAssertFalse(built, "\"Restore windows on launch: Never\" applies to every window")
        XCTAssertEqual(manager.frames.savedVisibility(for: id), true, "the policy leaves the saved state alone")
    }

    /// An update relaunch puts the windows back even where macOS is set to
    /// close windows on quit — and even when the build that quit never
    /// recorded itself (no `lastLaunchedBuilds` entry).
    func testAnUpdateRelaunchReopensWhateverTheSystemPreference() {
        let id = newID("update")
        seedVisibility(true, for: id)
        recordBuild("100")
        launch(build: "101")

        var window: TestWC?
        manager.register(id: id) { window = TestWC(windowID: id, behavior: .default) }
        manager.restoreOnLaunch()

        XCTAssertEqual(window?.isVisible, true, "the window left open before the update is back")
        XCTAssertEqual(recordedBuild, "101")
    }

    func testABuildThatNeverRecordedItselfCountsAsAnUpdate() {
        let id = newID("unrecorded")
        seedVisibility(true, for: id)
        UserSettings.shared.remove(UserSettings.lastLaunchedBuilds)
        launch(build: "7")

        var window: TestWC?
        manager.register(id: id) { window = TestWC(windowID: id, behavior: .default) }
        manager.restoreOnLaunch()

        XCTAssertEqual(window?.isVisible, true)
    }

    func testAnOrdinaryRelaunchStillFollowsTheSystemPreference() {
        let id = newID("samebuild")
        seedVisibility(true, for: id)
        recordBuild("101")
        launch(build: "101")

        var built = false
        manager.register(id: id) { built = true }
        manager.restoreOnLaunch()

        XCTAssertFalse(built, "the same build relaunching is a quit the person chose")
    }

    func testAnUpdateRelaunchStillHonorsNever() {
        let id = newID("updatenever")
        seedVisibility(true, for: id)
        recordBuild("100")
        launch(build: "101")
        usePolicy(.never)

        var built = false
        manager.register(id: id) { built = true }
        manager.restoreOnLaunch()

        XCTAssertFalse(built, "\"Never\" is the reader's own word, update or not")
    }

    func testUnclaimedVisibleFlagIsReportedAndCleared() {
        let orphanID = newID("orphan")
        seedVisibility(true, for: orphanID)
        XCTAssertTrue(manager.frames.visibleWindowIDs().contains(orphanID), "the default storage lists visible ids")

        manager.restoreOnLaunch()

        XCTAssertNil(manager.frames.savedVisibility(for: orphanID))
        XCTAssertFalse(manager.frames.visibleWindowIDs().contains(orphanID))
    }

    /// A window the system preference closed at an earlier quit is not "left
    /// open": the launch that kept it shut forgets it, so the next update
    /// relaunch does not bring it back.
    func testAWindowKeptShutByThePreferenceIsNotReopenedByALaterUpdate() {
        let id = newID("stale")
        seedVisibility(true, for: id)
        recordBuild("100")
        launch(build: "100")
        var built = false
        manager.register(id: id) { built = true }
        manager.restoreOnLaunch()
        XCTAssertFalse(built)
        XCTAssertNotEqual(manager.frames.loadVisibility(for: id), true, "shut by the preference, so forgotten")

        manager.hasRestoredThisProcess = false
        launch(build: "101")
        manager.restoreOnLaunch()
        XCTAssertFalse(built, "an update reopens what was open at the last quit, nothing older")
    }

    /// Only the launch's own call forgets: a reactivation may find a window
    /// saved as visible while hidden.
    func testAReactivationForgetsNothing() {
        let id = newID("reactivation")
        seedVisibility(true, for: id)
        recordBuild("100")
        launch(build: "100")
        manager.hasRestoredThisProcess = true

        manager.register(id: id) {}
        manager.restoreOnLaunch()

        XCTAssertEqual(manager.frames.loadVisibility(for: id), true)
    }

    /// A quit the person chose, which the updater used to install, follows
    /// the policy like any other quit; the marker is spent by that launch.
    func testAQuitThatInstalledAnUpdateFollowsTheSystemPreference() {
        let id = newID("installonquit")
        seedVisibility(true, for: id)
        recordBuild("100")
        manager.noteUpdateWillInstallOnQuit()
        launch(build: "101")

        var built = false
        manager.register(id: id) { built = true }
        manager.restoreOnLaunch()

        XCTAssertFalse(built, "the person quit; the update only rode along")
        XCTAssertNil(UserSettings.updateInstallsOnQuit.currentValue[WindowStateNamespace.current])
        XCTAssertEqual(recordedBuild, "101")
    }

    /// The updater's own relaunch reopens, even after it had first scheduled
    /// an install on quit.
    func testTheUpdatersRelaunchReopensEvenAfterAnInstallOnQuitWasScheduled() {
        let id = newID("relaunch")
        seedVisibility(true, for: id)
        recordBuild("100")
        manager.noteUpdateWillInstallOnQuit()
        manager.noteUpdateWillRelaunch()
        launch(build: "101")

        var window: TestWC?
        manager.register(id: id) { window = TestWC(windowID: id, behavior: .default) }
        manager.restoreOnLaunch()

        XCTAssertEqual(window?.isVisible, true)
    }

    /// Two copies of the app on disk share preferences; each keeps its own
    /// build, so alternating between them is not an update.
    func testEachCopyOfTheAppKeepsItsOwnBuild() {
        WindowStateNamespace.isolate(toPath: "/Applications/Example.app")
        recordBuild("100")
        WindowStateNamespace.isolate(toPath: "/tmp/worktree/Build/Example.app")
        recordBuild("205")

        WindowStateNamespace.isolate(toPath: "/Applications/Example.app")
        let id = newID("copies")
        seedVisibility(true, for: id)
        launch(build: "100")
        var built = false
        manager.register(id: id) { built = true }
        manager.restoreOnLaunch()

        XCTAssertFalse(built, "the installed copy relaunching its own build is no update")
        XCTAssertEqual(recordedBuild, "100")
    }
}
