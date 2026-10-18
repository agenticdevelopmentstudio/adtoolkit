@testable import AgenticToolkitCore
import XCTest

/// Hooks and the status line run the bundle's own `steno` by absolute path; the
/// display marker switches the status line to `--capture-only`.
final class HookInstallerBundleCommandTests: XCTestCase {

    private static let steno = "/Applications/Stenographer.app/Contents/Helpers/steno"
    private var claudeDir: URL!
    /// Made once in setUp, so a fixture that cannot be written fails there.
    private var bundledDispatcher: URL!

    override func setUpWithError() throws {
        claudeDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hook-bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        bundledDispatcher = try StatusLineTestSupport.makeBundledDispatcher(in: claudeDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: claudeDir)
    }

    private var settings: URL { claudeDir.appendingPathComponent("settings.json") }

    private func installer(steno: String = steno) -> ClaudeHookInstaller {
        ClaudeHookInstaller(settingsURL: settings, dropDirectory: "/tmp/test-events", stenoPath: steno,
                      bundledDispatcher: bundledDispatcher,
                      stenoIsExecutable: { _ in true })
    }

    /// The `statusLine` slot's command.
    private func statusLine() -> String? {
        let json = try? JSONSerialization.jsonObject(with: Data(contentsOf: settings)) as? [String: Any]
        return (json?["statusLine"] as? [String: Any])?["command"] as? String
    }

    private var lines: ClaudeStatusLine {
        ClaudeStatusLine(claudeDirectory: claudeDir, bundledDispatcher: bundledDispatcher)
    }

    /// Stenographer's dispatcher entry.
    private func ourEntry() -> ClaudeStatusLine.Entry? { lines.entry(named: "stenographer") }

    private func adopted() -> [String] {
        lines.entries().filter { ClaudeStatusLine.isAdoptedName($0.name) }.map(\.command)
    }

    private func write(_ object: [String: Any]) throws {
        try JSONSerialization.data(withJSONObject: object).write(to: settings)
    }

    func testHookCommandQuotesBundlePathWithSpaces() {
        let spaced = installer(steno: "/Users/Jane Smith/Apps/Stenographer.app/Contents/Helpers/steno")
        XCTAssertEqual(
            spaced.makeCommand(eventType: "PreToolUse"),
            "# stenographer-hook\n'/Users/Jane Smith/Apps/Stenographer.app/Contents/Helpers/steno'"
                + " hook --event PreToolUse\nexit 0")
    }

    func testTheInstalledSessionStartHookIsTheCurrentOneAndForwardsNoPid() throws {
        // `steno hook` finds claude's pid itself (ProcessEnv.claudePid). What
        // install writes must be exactly what isCurrentHook accepts, or every
        // daemon start would rewrite the hooks.
        let installer = installer()
        installer.installHooks()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: settings)) as? [String: Any])
        let groups = try XCTUnwrap((json["hooks"] as? [String: Any])?["SessionStart"] as? [[String: Any]])
        let ours = groups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }.filter(installer.isOwnHook)
        let hook = try XCTUnwrap(ours.first)
        XCTAssertTrue(installer.isCurrentHook(hook, eventType: "SessionStart"))
        XCTAssertEqual(hook["command"] as? String,
                       "# stenographer-hook\n\(Self.steno) hook --event SessionStart\nexit 0")
    }

    func testBundledStenoPathFromDaemonExecutable() {
        XCTAssertEqual(
            // swiftlint:disable:next line_length
            ClaudeHookConfiguration.bundledHelperPath(named: "steno", executable: URL(fileURLWithPath: "/Applications/Stenographer.app/Contents/MacOS/stenographerd")),
            "/Applications/Stenographer.app/Contents/Helpers/steno")
    }

    func testBundledStenoPathFromTheCLIItself() {
        XCTAssertEqual(
            // swiftlint:disable:next line_length
            ClaudeHookConfiguration.bundledHelperPath(named: "steno", executable: URL(fileURLWithPath: "/Applications/Stenographer.app/Contents/Helpers/steno")),
            "/Applications/Stenographer.app/Contents/Helpers/steno")
    }

    func testStatusLineDisplayToggleSwitchesToCaptureOnly() throws {
        let installer = installer()
        installer.installHooks()
        XCTAssertEqual(statusLine(), lines.dispatcherCommand)
        XCTAssertEqual(ourEntry(), .init(kind: .renderers, name: "stenographer", command: "\(Self.steno) statusline"))
        try installer.setStatusLineDisplay(false)
        XCTAssertEqual(statusLine(), lines.dispatcherCommand)
        XCTAssertEqual(ourEntry(), .init(kind: .taps, name: "stenographer",
                                     command: "\(Self.steno) statusline --capture-only"))
        XCTAssertFalse(installer.isStatusLineDisplayed)
        XCTAssertEqual(installer.statusLineDisplayOffMarkerURL,
                       claudeDir.appendingPathComponent(".stenographer-status-line-off"))
        try installer.setStatusLineDisplay(true)
        XCTAssertEqual(ourEntry(), .init(kind: .renderers, name: "stenographer", command: "\(Self.steno) statusline"))
        XCTAssertTrue(installer.isStatusLineDisplayed)
        XCTAssertFalse(FileManager.default.fileExists(atPath: installer.statusLineDisplayOffMarkerURL.path))
    }

    func testDisplayOffSurvivesAReinstall() throws {
        let installer = installer()
        installer.installHooks()
        try installer.setStatusLineDisplay(false)
        installer.installHooks()
        XCTAssertEqual(ourEntry(), .init(kind: .taps, name: "stenographer",
                                     command: "\(Self.steno) statusline --capture-only"))
    }

    func testTogglingTheDisplayKeepsAForeignStatusLineShowing() throws {
        try write(["statusLine": ["type": "command", "command": "my-own-status-line"]])
        try installer().setStatusLineDisplay(false)
        XCTAssertEqual(statusLine(), lines.dispatcherCommand)
        XCTAssertEqual(adopted(), ["my-own-status-line"], "the foreign line keeps showing")
        XCTAssertEqual(ourEntry()?.kind, .taps)
    }

    func testTogglingTheDisplayRegistersNothingWhenTrackingIsOff() throws {
        let installer = installer()
        try installer.setTrackingDisabled(true)
        try installer.setStatusLineDisplay(false)
        XCTAssertNil(statusLine(), "toggling must not register a status line when tracking is off")
        XCTAssertNil(ourEntry())
    }

    /// With no display-off marker, a foreign statusLine is still not "displayed":
    /// Manage Tools must not show the box checked while Claude Code runs it.
    func testForeignStatusLineReadsAsNotDisplayed() throws {
        try write(["statusLine": ["type": "command", "command": "npx ccstatusline"]])
        let installer = installer()
        XCTAssertFalse(FileManager.default.fileExists(atPath: installer.statusLineDisplayOffMarkerURL.path))
        XCTAssertFalse(installer.isStatusLineDisplayed)
    }

    func testOnlyARegisteredRendererReadsAsDisplayed() throws {
        let installer = installer()
        XCTAssertFalse(installer.isStatusLineDisplayed, "nothing registered")
        try write(["statusLine": ["type": "command", "command": "\(Self.steno) statusline"]])
        XCTAssertFalse(installer.isStatusLineDisplayed, "our old direct command is not the dispatcher")
        installer.installHooks()
        XCTAssertTrue(installer.isStatusLineDisplayed)
        try lines.register(.renderers, name: "stenographer", command: "\(Self.steno) statusline --capture-only")
        XCTAssertFalse(installer.isStatusLineDisplayed, "ours, but drawing nothing")
        try lines.register(.renderers, name: "stenographer", command: "\(Self.steno) statusline")
        try FileManager.default.removeItem(at: lines.dispatcherURL)
        XCTAssertFalse(installer.isStatusLineDisplayed, "the slot runs a dispatcher that is gone")
    }

    func testTurningTheDisplayOnOverAForeignStatusLineKeepsIt() throws {
        try write(["statusLine": ["type": "command", "command": "npx ccstatusline"]])
        let installer = installer()
        try installer.setStatusLineDisplay(true)
        XCTAssertTrue(installer.isStatusLineDisplayed)
        XCTAssertEqual(adopted(), ["npx ccstatusline"], "the foreign line is never clobbered")
    }

    /// First-run setup turns the display on before anything registered the
    /// line; with tracking on that must register it, not refuse.
    func testTurningTheDisplayOnFillsAnEmptySlotWhenTracking() throws {
        let installer = installer()
        try installer.setStatusLineDisplay(true)
        XCTAssertEqual(statusLine(), lines.dispatcherCommand)
        XCTAssertTrue(installer.isStatusLineDisplayed)
    }

    func testTurningTheDisplayOnWithNothingRegisteredThrows() throws {
        let installer = installer()
        try installer.setTrackingDisabled(true)
        XCTAssertThrowsError(try installer.setStatusLineDisplay(true)) { error in
            XCTAssertTrue(error.localizedDescription.contains("tracking is off"), error.localizedDescription)
        }
        XCTAssertNil(statusLine())
    }

    func testOldUsrLocalBinCommandIsReplaced() throws {
        for old in ["/usr/local/bin/steno statusline", "/usr/local/bin/steno statusline --capture-only"] {
            try write(["statusLine": ["type": "command", "command": old]])
            installer().installHooks()
            XCTAssertEqual(statusLine(), lines.dispatcherCommand, "\(old) must migrate")
            XCTAssertEqual(ourEntry()?.command, "\(Self.steno) statusline")
            XCTAssertEqual(adopted(), [], "\(old) is ours, never adopted")
        }
    }

    func testOldPythonCaptureHooksAreReplaced() throws {
        // The shipped v8 rendering, and a bare-marker variant.
        let shippedV8 = "# stenographer-hook-v8\n'/usr/bin/python3' '/Users/x/.claude/stenographer-capture.py'"
            + " PreToolUse\nexit 0"
        let bare = "# stenographer-hook\n/usr/bin/python3 /Users/x/.claude/stenographer-capture.py PreToolUse\nexit 0"
        for old in [shippedV8, bare] {
            try write(["hooks": ["PreToolUse": [["hooks": [["type": "command", "command": old]]]]]])
            installer().installHooks()
            let text = try String(contentsOf: settings, encoding: .utf8)
            XCTAssertFalse(text.contains("stenographer-capture.py"), old)
            XCTAssertTrue(text.contains("hook --event PreToolUse"))
        }
    }

    func testMovedBundleHookCommandIsRewritten() throws {
        let moved = "# stenographer-hook\n'/Users/x/Downloads/Stenographer.app/Contents/Helpers/steno'"
            + " hook --event PreToolUse\nexit 0"
        try write(["hooks": ["PreToolUse": [["hooks": [["type": "command", "command": moved]]]]],
                   "statusLine": ["type": "command",
                                  "command": "/Users/x/Downloads/Stenographer.app/Contents/Helpers/steno statusline"]])
        let installer = installer()
        installer.installHooks()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: settings)) as? [String: Any])
        let groups = try XCTUnwrap((json["hooks"] as? [String: Any])?["PreToolUse"] as? [[String: Any]])
        let ours = groups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }.filter(installer.isOwnHook)
        XCTAssertEqual(ours.count, 1, "exactly one stenographer hook for the event")
        let command = try XCTUnwrap(ours.first?["command"] as? String)
        XCTAssertTrue(command.contains(Self.steno), command)
        XCTAssertFalse(command.contains("Downloads"), command)
        XCTAssertEqual(ourEntry()?.command, "\(Self.steno) statusline", "a moved bundle's status line follows it")
        XCTAssertEqual(adopted(), [], "the moved bundle's old command is ours, not adopted")
    }

    // MARK: - The retired python capture script

    func testInstallRemovesTheRetiredCaptureScriptWhenItCarriesOurMarker() throws {
        let script = claudeDir.appendingPathComponent("stenographer-capture.py")
        try "# stenographer-hook\nprint('x')\n".write(to: script, atomically: true, encoding: .utf8)
        installer().installHooks()
        XCTAssertFalse(FileManager.default.fileExists(atPath: script.path))
    }

    func testInstallRemovesTheShippedCaptureScript() throws {
        // The script this build used to ship opens with a shebang, then a docstring naming itself.
        let script = claudeDir.appendingPathComponent("stenographer-capture.py")
        try "#!/usr/bin/python3\n\"\"\"stenographer-capture.py — the hook entry point stenographer registers.\n"
            .write(to: script, atomically: true, encoding: .utf8)
        installer().installHooks()
        XCTAssertFalse(FileManager.default.fileExists(atPath: script.path))
    }

    func testInstallRemovesTheReleasedCaptureScript() throws {
        // The exact header of the copy main's ./install, the Sparkle post-update
        // and the pkg preinstall wrote (2.136.21–2.171.0) — the one real machines have.
        let script = claudeDir.appendingPathComponent("stenographer-capture.py")
        try "#!/usr/bin/python3\n\"\"\"stenographer-capture.py — the hook entry point that survives an install.\n\n"
            .write(to: script, atomically: true, encoding: .utf8)
        installer().installHooks()
        XCTAssertFalse(FileManager.default.fileExists(atPath: script.path))
    }

    func testInstallKeepsASymlinkByThatName() throws {
        let target = claudeDir.appendingPathComponent("real-script")
        try "# stenographer-hook\nprint('x')\n".write(to: target, atomically: true, encoding: .utf8)
        let link = claudeDir.appendingPathComponent("stenographer-capture.py")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        installer().installHooks()
        XCTAssertNotNil(try? FileManager.default.destinationOfSymbolicLink(atPath: link.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.path))
    }

    func testInstallKeepsAWrapperThatOnlyMentionsTheNameOnLineTwo() throws {
        let script = claudeDir.appendingPathComponent("stenographer-capture.py")
        let wrapper = "#!/bin/sh\n# calls stenographer-capture.py somewhere\n"
        try wrapper.write(to: script, atomically: true, encoding: .utf8)
        installer().installHooks()
        XCTAssertTrue(FileManager.default.fileExists(atPath: script.path))
    }

    func testAFailedInstallKeepsTheCaptureScript() throws {
        let script = claudeDir.appendingPathComponent("stenographer-capture.py")
        try "# stenographer-hook\nprint('x')\n".write(to: script, atomically: true, encoding: .utf8)
        try Data("[]".utf8).write(to: settings)   // not a JSON object: install throws
        guard case .failed = installer().installHooks() else { return XCTFail("install should fail") }
        XCTAssertTrue(FileManager.default.fileExists(atPath: script.path),
                      "the script must outlive an install that could not rewrite settings.json")
    }

    func testInstallKeepsAForeignFileByThatName() throws {
        let script = claudeDir.appendingPathComponent("stenographer-capture.py")
        try "#!/bin/sh\necho somebody else's\n".write(to: script, atomically: true, encoding: .utf8)
        installer().installHooks()
        XCTAssertTrue(FileManager.default.fileExists(atPath: script.path))
    }

    // MARK: - Quoting, missing binaries, symlinks, exact matches, foreign hooks

    func testQuotingSurvivesACombiningMarkAfterAnApostrophe() throws {
        for mark in ["\u{301}", "\u{308}"] {
            let steno = "/Users/O'\(mark)Brien Apps/Stenographer.app/Contents/Helpers/steno"
            let command = installer(steno: steno).makeCommand(eventType: "PreToolUse")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-n", "-c", command]
            let errors = Pipe()
            process.standardError = errors
            try process.run()
            process.waitUntilExit()
            XCTAssertEqual(process.terminationStatus, 0,
                           "sh -n rejected the hook for U+\(mark.unicodeScalars.last!.value)")
            XCTAssertEqual(ShellQuote.word("a'\(mark)b"), "'a'\"'\"'\(mark)b'")
        }
    }

    func testAMissingStenoLeavesTheHooksAlone() throws {
        let old = "# stenographer-hook\n'/old/Stenographer.app/Contents/Helpers/steno' hook --event PreToolUse\nexit 0"
        try write(["hooks": ["PreToolUse": [["hooks": [["type": "command", "command": old]]]]]])
        let before = try Data(contentsOf: settings)
        let missing = ClaudeHookInstaller(settingsURL: settings, dropDirectory: "/tmp/test-events",
                                    stenoPath: Self.steno, stenoIsExecutable: { _ in false })
        guard case .failed = missing.installHooks() else { return XCTFail("install should refuse") }
        XCTAssertEqual(try Data(contentsOf: settings), before)
        XCTAssertFalse(ClaudeHookInstaller.defaultHelperIsExecutable(claudeDir.path), "a directory is not a steno")
        XCTAssertFalse(ClaudeHookInstaller.defaultHelperIsExecutable(claudeDir.appendingPathComponent("nope").path))
    }

    func testASymlinkedExecutableResolvesToTheRealBundle() throws {
        let macOS = claudeDir.appendingPathComponent("real/Stenographer.app/Contents/MacOS")
        try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)
        let real = macOS.appendingPathComponent("stenographerd")
        try Data().write(to: real)
        let link = claudeDir.appendingPathComponent("stenographerd")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        XCTAssertEqual(ClaudeHookConfiguration.bundledHelperPath(named: "steno", executable: link),
                       real.resolvingSymlinksInPath().deletingLastPathComponent()
                        .deletingLastPathComponent().appendingPathComponent("Helpers/steno").path)
    }

    func testAWrapperAroundOurStatusLineIsForeign() throws {
        let wrapper = "mine.sh && /Applications/Stenographer.app/Contents/Helpers/steno statusline"
        XCTAssertFalse(installer().isBundleStatusLineCommand(wrapper))
        XCTAssertFalse(installer().isBundleStatusLineCommand(
            "/Applications/Stenographer.app/Contents/Helpers/steno statusline; rm -rf x"))
        XCTAssertTrue(installer().isBundleStatusLineCommand(
            "'/Users/Jane Smith/Stenographer.app/Contents/Helpers/steno' statusline --capture-only"))
        // A quoted wrapper must not pass for one quoted path (N1).
        XCTAssertFalse(installer().isBundleStatusLineCommand(
            "'/opt/my tool' && '/Applications/Stenographer.app/Contents/Helpers/steno' statusline"))
        XCTAssertFalse(installer().isBundleStatusLineCommand(
            "'/x'; rm -rf ~/foo; '/A.app/Contents/Helpers/steno' statusline"))
        // A path with a space and an apostrophe round-trips through shellQuote.
        let odd = "/Users/O'Brien Apps/Stenographer.app/Contents/Helpers/steno"
        XCTAssertTrue(installer().isBundleStatusLineCommand("\(ShellQuote.word(odd)) statusline"))
        XCTAssertTrue(installer().isBundleStatusLineCommand(
            "\(ShellQuote.word(odd)) statusline --capture-only"))
        try write(["statusLine": ["type": "command", "command": wrapper]])
        installer().installHooks()
        XCTAssertEqual(adopted(), [wrapper], "a wrapper is another tool's: kept showing, not replaced")
    }

    func testAForeignHookSharingTheGroupSurvivesABundleMove() throws {
        let moved = "# stenographer-hook\n'/Users/x/Downloads/Stenographer.app/Contents/Helpers/steno'"
            + " hook --event PreToolUse\nexit 0"
        let foreign: [String: Any] = ["type": "command", "command": "echo mine"]
        try write(["hooks": ["PreToolUse": [["hooks": [["type": "command", "command": moved], foreign]]]]])
        installer().installHooks()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: settings)) as? [String: Any])
        let groups = try XCTUnwrap((json["hooks"] as? [String: Any])?["PreToolUse"] as? [[String: Any]])
        let commands = groups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }
            .compactMap { $0["command"] as? String }
        XCTAssertTrue(commands.contains("echo mine"), "the foreign hook was dropped with our entry")
        XCTAssertFalse(commands.contains(moved))
        XCTAssertEqual(commands.filter { $0.contains(Self.steno) }.count, 1)
    }
}
