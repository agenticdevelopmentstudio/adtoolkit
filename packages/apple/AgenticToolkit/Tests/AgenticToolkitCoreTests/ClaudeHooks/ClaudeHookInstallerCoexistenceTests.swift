@testable import AgenticToolkitCore
import XCTest

/// Two configurations installed into one `settings.json`: each owner's hooks,
/// status-line entry and legacy cleanup stay its own. Every test uses a
/// temporary settings URL, never the real `~/.claude/settings.json`.
final class ClaudeHookInstallerCoexistenceTests: XCTestCase {

    private var tmpDir: URL!
    private var settingsURL: URL!
    private var dispatcher: URL!

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hook-coexist-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        settingsURL = tmpDir.appendingPathComponent("settings.json")
        dispatcher = try StatusLineTestSupport.makeBundledDispatcher(in: tmpDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func firstInstaller() -> ClaudeHookInstaller {
        ClaudeHookInstaller(
            configuration: .stenographerFixture(settingsURL: settingsURL, bundledDispatcher: dispatcher),
            helperIsExecutable: { _ in true })
    }

    private func secondInstaller() -> ClaudeHookInstaller {
        ClaudeHookInstaller(
            configuration: .adkdFixture(settingsURL: settingsURL, bundledDispatcher: dispatcher),
            helperIsExecutable: { _ in true })
    }

    func testBothMarkerSetsCoexistAndEachUninstallRemovesOnlyItsOwn() throws {
        let first = firstInstaller()
        let second = secondInstaller()
        XCTAssertEqual(first.installHooks(), .installed)
        XCTAssertEqual(second.installHooks(), .installed)

        var settings = try first.loadSettings()
        let hooks = try XCTUnwrap(settings["hooks"] as? [String: Any])
        for event in first.hookedEventTypes {
            let groups = try XCTUnwrap(hooks[event] as? [[String: Any]], event)
            XCTAssertEqual(groups.count, 2, "\(event) carries both owners' entries")
        }
        XCTAssertEqual(first.installedEventTypes(in: settings), Set(first.hookedEventTypes))
        XCTAssertEqual(second.installedEventTypes(in: settings), Set(second.hookedEventTypes))
        XCTAssertEqual(first.installHooks(), .alreadyInstalled, "the other owner's entries are not stale")

        XCTAssertTrue(first.uninstallHooks())
        settings = try first.loadSettings()
        XCTAssertTrue(first.installedEventTypes(in: settings).isEmpty)
        XCTAssertEqual(second.installedEventTypes(in: settings), Set(second.hookedEventTypes))

        XCTAssertEqual(first.installHooks(), .installed)
        XCTAssertTrue(second.uninstallHooks())
        settings = try first.loadSettings()
        XCTAssertTrue(second.installedEventTypes(in: settings).isEmpty)
        XCTAssertEqual(first.installedEventTypes(in: settings), Set(first.hookedEventTypes))
    }

    func testATapOnlyConfigurationRegistersATapAndNeverARenderer() throws {
        let second = secondInstaller()
        XCTAssertEqual(second.installHooks(), .installed)

        let entry = try XCTUnwrap(second.statusLine.entry(named: "adkd"))
        XCTAssertEqual(entry.kind, .taps)
        XCTAssertTrue(entry.command.hasSuffix(" statusline --capture-only"), entry.command)
        XCTAssertEqual(entry.command, second.statusLineCommand)
        XCTAssertEqual(
            entry.command,
            ShellQuoting.quoteIfNeeded("/Applications/Kitchen.app/Contents/Helpers/adk") + " statusline --capture-only",
            "the flag appears exactly once")
        XCTAssertTrue(second.statusLine.entries().filter { $0.kind == .renderers }.isEmpty)
        XCTAssertFalse(second.isStatusLineDisplayed)

        try second.setStatusLineDisplay(true)
        XCTAssertEqual(second.statusLine.entry(named: "adkd")?.kind, .taps, "tap-only ignores the display switch")
    }

    func testNoLegacyFormsLeavesForeignHttpHooksAndTheCaptureScriptAlone() throws {
        let httpHook: [String: Any] = ["type": "http", "url": "http://127.0.0.1:22847/hook/PreToolUse"]
        let settings: [String: Any] = ["hooks": ["PreToolUse": [["hooks": [httpHook]]]]]
        try JSONSerialization.data(withJSONObject: settings).write(to: settingsURL)
        let script = tmpDir.appendingPathComponent("stenographer-capture.py")
        try "# stenographer-hook\nprint('x')\n".write(to: script, atomically: true, encoding: .utf8)

        let second = secondInstaller()
        XCTAssertEqual(second.installHooks(), .installed)

        let loaded = try second.loadSettings()
        let groups = try XCTUnwrap((loaded["hooks"] as? [String: Any])?["PreToolUse"] as? [[String: Any]])
        let all = groups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }
        XCTAssertTrue(all.contains { ($0["type"] as? String) == "http" }, "the foreign http hook survives")
        XCTAssertTrue(FileManager.default.fileExists(atPath: script.path), "the foreign script survives")
        XCTAssertTrue(second.uninstallHooks())
        let afterUninstall = try second.loadSettings()
        let remaining = try XCTUnwrap((afterUninstall["hooks"] as? [String: Any])?["PreToolUse"] as? [[String: Any]])
        XCTAssertEqual(remaining.count, 1, "uninstall leaves the http hook group")
    }

    func testTheMarkerFilesAreNamedAfterTheConfiguration() {
        XCTAssertEqual(firstInstaller().trackingDisabledMarkerURL.lastPathComponent, ".stenographer-tracking-disabled")
        XCTAssertEqual(secondInstaller().trackingDisabledMarkerURL.lastPathComponent, ".adkd-tracking-disabled")
        XCTAssertEqual(secondInstaller().statusLineDisplayOffMarkerURL.lastPathComponent, ".adkd-status-line-off")
        XCTAssertEqual(secondInstaller().configuration.ownLockName, ".adkd-hooks.lock")
    }
}
