@testable import AgenticToolkitCore
import XCTest

final class HookInstallerTests: XCTestCase {

    var tmpDir: URL!
    var settingsURL: URL!
    var installer: ClaudeHookInstaller!
    /// The version-1 dispatcher every installer here carries, made once in
    /// setUp so a fixture that cannot be written fails there, at the cause.
    var bundledDispatcher: URL!

    /// The `steno` every rendered command names in these tests. Fixed, so the
    /// expected text does not depend on where this test runner lives.
    static let steno = "/Applications/Stenographer.app/Contents/Helpers/steno"

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hook-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        settingsURL = tmpDir.appendingPathComponent("settings.json")
        bundledDispatcher = try StatusLineTestSupport.makeBundledDispatcher(in: tmpDir)
        installer = makeInstaller(settingsURL: settingsURL)
    }

    /// An installer rendering `Self.steno`, never whatever bundle is running,
    /// carrying a version-1 dispatcher of its own.
    private func makeInstaller(settingsURL: URL, lockTimeout: TimeInterval = 5) -> ClaudeHookInstaller {
        ClaudeHookInstaller(settingsURL: settingsURL, dropDirectory: "/tmp/test-events",
                      stenoPath: Self.steno, bundledDispatcher: bundledDispatcher,
                      lockTimeout: lockTimeout, stenoIsExecutable: { _ in true })
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    func testInstallIntoEmptySettings() throws {
        let result = installer.installHooks()
        XCTAssertEqual(result, .installed)

        let settings = try installer.loadSettings()
        XCTAssertTrue(installer.isInstalled(in: settings))
    }

    func testInstallIdempotent() throws {
        XCTAssertEqual(installer.installHooks(), .installed)
        XCTAssertEqual(installer.installHooks(), .alreadyInstalled)
    }

    func testUninstall() throws {
        installer.installHooks()
        let removed = installer.uninstallHooks()
        XCTAssertTrue(removed)

        let settings = try installer.loadSettings()
        XCTAssertFalse(installer.isInstalled(in: settings))
    }

    // MARK: - statusLine ownership

    private func writeSettings(_ dict: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: dict)
        try data.write(to: settingsURL)
    }

    private func statusLineCommand(in settings: [String: Any]) -> String? {
        (settings["statusLine"] as? [String: Any])?["command"] as? String
    }

    private var slot: String? { statusLineCommand(in: (try? installer.loadSettings()) ?? [:]) }

    /// What install should leave: the slot runs the dispatcher, and
    /// Stenographer's own command is its renderer.
    private func assertDispatching(_ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(slot, installer.statusLine.dispatcherCommand, message, file: file, line: line)
        XCTAssertEqual(installer.statusLine.entry(named: "stenographer"),
                       .init(kind: .renderers, name: "stenographer", command: installer.statusLineCommand),
                       message, file: file, line: line)
        XCTAssertTrue(FileManager.default.fileExists(atPath: installer.statusLine.dispatcherURL.path),
                      message, file: file, line: line)
    }

    private var adopted: [ClaudeStatusLine.Entry] {
        installer.statusLine.entries().filter { ClaudeStatusLine.isAdoptedName($0.name) }
    }

    func testInstallRegistersWithTheDispatcher() throws {
        installer.installHooks()
        assertDispatching()
        XCTAssertTrue(adopted.isEmpty, "an empty slot adopts nothing")
    }

    func testInstallReplacesLegacyCSLStatusLine() throws {
        try writeSettings(["statusLine": [
            "type": "command",
            "command": "PYTHONPATH=$HOME/.claude-status-line python3 -m statusline.dispatcher"
        ]])
        installer.installHooks()
        assertDispatching("the legacy stenographer-status-line renderer is ours, replaced not adopted")
        XCTAssertTrue(adopted.isEmpty)
    }

    func testInstallMigratesBareStatusLineCommand() throws {
        // A prior install wrote the path-free `stenographer statusline`, which
        // renders blank under a GUI session's minimal PATH. It is ours: replaced,
        // never kept as an adopted renderer.
        try writeSettings(["statusLine": ["type": "command", "command": "stenographer statusline"]])
        let result = installer.installHooks()
        guard case .installed = result else {
            return XCTFail("expected .installed after migrating the bare statusLine, got \(result)")
        }
        assertDispatching()
        XCTAssertTrue(adopted.isEmpty)
    }

    func testInstallMigratesTheSnogStatusLineCommand() throws {
        // 2.161.0–2.163.0 named the CLI `snog`; 2.164.0 renamed it `steno` and
        // `install` removes the `snog` symlink, which would leave this dangling.
        // The absolute `stenographer` form dangles the same way once setup removes
        // that link.
        for legacy in ["snog statusline", "/usr/local/bin/snog statusline",
                       "/usr/local/bin/stenographer statusline"] {
            try writeSettings(["statusLine": ["type": "command", "command": legacy]])
            let result = installer.installHooks()
            guard case .installed = result else {
                return XCTFail("expected .installed after migrating \(legacy), got \(result)")
            }
            assertDispatching("`\(legacy)` must be replaced by the dispatcher")
            XCTAssertTrue(adopted.isEmpty, legacy)
        }
    }

    func testUninstallRemovesALegacyStatusLineCommand() throws {
        try writeSettings(["statusLine": ["type": "command",
                                          "command": "/usr/local/bin/stenographer statusline"]])
        installer.uninstallHooks()
        XCTAssertNil(try installer.loadSettings()["statusLine"])
    }

    /// The `statusLine` slot as `install` leaves it for the length of a macOS
    /// install: pointed at the bundle-independent capture script, carrying a
    /// hook marker so this installer can tell it is ours.
    private var swappedStatusLine: String {
        "# stenographer-hook-v8\n'/usr/bin/python3' '/Users/x/.claude/stenographer-capture.py' StatusLine\nexit 0"
    }

    func testInstallTakesBackTheStatusLineTheInstallSwapped() throws {
        // The capture script renders nothing: kept as a renderer it would only
        // ever fail, so it is replaced, not adopted.
        try writeSettings(["statusLine": ["type": "command", "command": swappedStatusLine]])
        installer.installHooks()
        assertDispatching("the install's own swapped statusLine must be taken back")
        XCTAssertTrue(adopted.isEmpty)
    }

    func testUninstallRemovesTheStatusLineTheInstallSwapped() throws {
        // An uninstall running while an install is mid-flight would otherwise
        // leave the slot pointing at a capture script the uninstall then deletes,
        // and every render would exec a missing file.
        try writeSettings(["statusLine": ["type": "command", "command": swappedStatusLine]])
        XCTAssertTrue(installer.uninstallHooks())
        XCTAssertNil(statusLineCommand(in: try installer.loadSettings()))
    }

    func testUninstallLeavesAForeignStatusLineAlone() throws {
        try writeSettings(["statusLine": ["type": "command", "command": "my-own-status-line"]])
        installer.uninstallHooks()
        XCTAssertEqual(statusLineCommand(in: try installer.loadSettings()), "my-own-status-line")
    }

    func testInstallAdoptsAForeignStatusLine() throws {
        try writeSettings(["statusLine": ["type": "command", "command": "my-own-status-line", "padding": 2]])
        installer.installHooks()
        assertDispatching()
        XCTAssertEqual(adopted, [.init(kind: .renderers, name: "adopted", command: "my-own-status-line")],
                       "an unrelated custom statusLine keeps showing through the dispatcher")
        XCTAssertEqual((try installer.loadSettings()["statusLine"] as? [String: Any])?["padding"] as? Int, 2,
                       "the slot's other keys are kept")
    }

    func testInstallAdoptsAForeignDispatcherSubstring() throws {
        // A foreign command that merely embeds "statusline.dispatcher" as a
        // substring (not the trailing module) is another tool's: hasSuffix, not
        // contains, so it is adopted rather than dropped as ours.
        let foreign = "/opt/tools/statusline.dispatcher-v2 --wrap"
        try writeSettings(["statusLine": ["type": "command", "command": foreign]])
        installer.installHooks()
        assertDispatching()
        XCTAssertEqual(adopted.map(\.command), [foreign])
    }

    func testInstallReplacesCommandEndingInDispatcherModule() throws {
        try writeSettings(["statusLine": [
            "type": "command",
            "command": "env PYTHONPATH=/x python3 -m statusline.dispatcher"
        ]])
        installer.installHooks()
        assertDispatching()
        XCTAssertTrue(adopted.isEmpty)
    }

    func testReinstallIsIdempotentAndAdoptsOnlyOnce() throws {
        try writeSettings(["statusLine": ["type": "command", "command": "my-own-status-line"]])
        XCTAssertEqual(installer.installHooks(), .installed)
        XCTAssertEqual(installer.installHooks(), .alreadyInstalled)
        XCTAssertEqual(adopted.count, 1)
    }

    func testRetakingTheSlotReportsInstalledNotAlreadyInstalled() throws {
        installer.installHooks()
        // A foreign tool overwrites just the statusLine; the hooks remain ours,
        // so no new hook event types are added on re-install.
        var settings = try installer.loadSettings()
        settings["statusLine"] = ["type": "command", "command": "npx ccstatusline"]
        try writeSettings(settings)
        let result = installer.installHooks()
        guard case .installed = result else {
            return XCTFail("expected .installed after retaking the statusLine, got \(result)")
        }
        assertDispatching()
        XCTAssertEqual(adopted.map(\.command), ["npx ccstatusline"])
    }

    func testUninstallEmptiesTheSlotWhenNothingElseIsRegistered() throws {
        installer.installHooks()
        assertDispatching()
        installer.uninstallHooks()
        XCTAssertNil(try installer.loadSettings()["statusLine"],
                     "with no other entry, the slot is handed back empty")
        XCTAssertNil(installer.statusLine.entry(named: "stenographer"))
    }

    func testUninstallHandsTheAdoptedStatusLineBack() throws {
        try writeSettings(["statusLine": ["type": "command", "command": "my-own-status-line"]])
        installer.installHooks()
        installer.uninstallHooks()
        XCTAssertEqual(statusLineCommand(in: try installer.loadSettings()), "my-own-status-line",
                       "the command install adopted goes back into the slot")
        XCTAssertEqual(installer.statusLine.entries(),
                       [.init(kind: .renderers, name: "adopted", command: "my-own-status-line")],
                       "the adopted entry is not ours: it stays, inert, and a reinstall finds it")
    }

    func testStatusLineErrorIsTheDispatchersRecordOfOurRenderer() throws {
        installer.installHooks()
        XCTAssertNil(installer.statusLineError, "nothing recorded while the renderer works")
        let errors = installer.statusLine.directory.appendingPathComponent("errors")
        try FileManager.default.createDirectory(at: errors, withIntermediateDirectories: true)
        try "exit 1\n".write(to: errors.appendingPathComponent("adopted"), atomically: true, encoding: .utf8)
        XCTAssertNil(installer.statusLineError, "another entry's failure is not ours")
        try "timed out\n".write(to: errors.appendingPathComponent("stenographer"), atomically: true, encoding: .utf8)
        XCTAssertEqual(installer.statusLineError, "timed out")
        XCTAssertTrue(installer.isStatusLineDisplayed, "registered and failing are both true: hence the error")
    }

    func testUninstallKeepsTheDispatcherWhileAnotherToolIsRegistered() throws {
        installer.installHooks()
        try installer.statusLine.register(.taps, name: "myteams-quota", command: "sh /x/quota-tap.sh")
        installer.uninstallHooks()
        XCTAssertEqual(slot, installer.statusLine.dispatcherCommand, "another tool still uses the slot")
        XCTAssertEqual(installer.statusLine.entries().map(\.name), ["myteams-quota"])
    }

    func testInstallWithoutADispatcherStillInstallsTheHooks() throws {
        let bare = ClaudeHookInstaller(settingsURL: settingsURL, dropDirectory: "/tmp/test-events",
                                 stenoPath: Self.steno,
                                 bundledDispatcher: tmpDir.appendingPathComponent("missing.sh"),
                                 stenoIsExecutable: { _ in true })
        try writeSettings(["statusLine": ["type": "command", "command": "my-own-status-line"]])
        XCTAssertEqual(bare.installHooks(), .installed)
        XCTAssertTrue(bare.isInstalled(in: try bare.loadSettings()))
        XCTAssertEqual(slot, "my-own-status-line", "no dispatcher, so the slot is not taken")
        XCTAssertThrowsError(try bare.setStatusLineDisplay(true)) { error in
            XCTAssertTrue(error.localizedDescription.contains("missing.sh"), error.localizedDescription)
        }
    }

    func testSettingsFileModeIsPreserved() throws {
        try writeSettings([:])
        try FileManager.default.setAttributes([.posixPermissions: 0o640], ofItemAtPath: settingsURL.path)
        installer.installHooks()
        let mode = try FileManager.default.attributesOfItem(atPath: settingsURL.path)[.posixPermissions] as? Int
        XCTAssertEqual(mode, 0o640)
    }

    func testANewSettingsFileIsOwnerOnly() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: settingsURL.path))
        XCTAssertEqual(installer.installHooks(), .installed)
        let mode = try FileManager.default.attributesOfItem(atPath: settingsURL.path)[.posixPermissions] as? Int
        XCTAssertEqual(mode, 0o600, "settings.json can hold env tokens, so a new one is owner-only")
    }

    func testASymlinkedSettingsFileStaysALink() throws {
        let real = tmpDir.appendingPathComponent("dotfiles/settings.json")
        try FileManager.default.createDirectory(at: real.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"model":"opus"}"#.utf8).write(to: real)
        try FileManager.default.setAttributes([.posixPermissions: 0o640], ofItemAtPath: real.path)
        try FileManager.default.createSymbolicLink(at: settingsURL, withDestinationURL: real)
        XCTAssertEqual(installer.installHooks(), .installed)
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: settingsURL.path), real.path,
                       "a dotfiles-managed link survives the save")
        let saved = try JSONSerialization.jsonObject(with: Data(contentsOf: real)) as? [String: Any]
        XCTAssertEqual(saved?["model"] as? String, "opus")
        XCTAssertTrue(installer.isInstalled(in: saved ?? [:]))
        XCTAssertEqual(try FileManager.default.attributesOfItem(atPath: real.path)[.posixPermissions] as? Int, 0o640)
    }

    // MARK: - The shared settings lock

    /// Holds claudehelpers' lock beside settings.json through a descriptor of
    /// its own: `flock` locks belong to the open file, so the installer's own
    /// open of the same file is shut out exactly as another process's would be.
    private func holdSharedLock() throws -> Int32 {
        let descriptor = open(tmpDir.appendingPathComponent(ClaudeStatusLine.settingsLockName).path,
                              O_RDONLY | O_CREAT | O_CLOEXEC, 0o644)
        guard descriptor >= 0, flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return descriptor
    }

    func testAHeldSettingsLockDelaysTheInstallUntilItIsReleased() throws {
        let descriptor = try holdSharedLock()
        let installer = installer!
        let finished = expectation(description: "install finished")
        let started = Date()
        DispatchQueue.global().async {
            XCTAssertEqual(installer.installHooks(), .installed)
            finished.fulfill()
        }
        Thread.sleep(forTimeInterval: 0.4)
        XCTAssertFalse(FileManager.default.fileExists(atPath: settingsURL.path),
                       "nothing is written while another tool holds the lock")
        close(descriptor)
        wait(for: [finished], timeout: 10)
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(started), 0.4)
        XCTAssertTrue(installer.isInstalled(in: try installer.loadSettings()))
    }

    func testASettingsLockHeldPastTheTimeoutFailsInsteadOfHanging() throws {
        let descriptor = try holdSharedLock()
        defer { close(descriptor) }
        let impatient = makeInstaller(settingsURL: settingsURL, lockTimeout: 0.2)
        guard case .failed(let message) = impatient.installHooks() else {
            return XCTFail("a lock held past the timeout must fail the install")
        }
        XCTAssertTrue(message.contains(ClaudeStatusLine.settingsLockName), message)
        XCTAssertFalse(impatient.uninstallHooks())
        XCTAssertThrowsError(try impatient.setStatusLineDisplay(false))
    }

    func testTheSharedLockIsTheOneClaudeHelpersTakes() throws {
        let source = try String(contentsOf: StatusLineTestSupport.dispatcherSource
            .appendingPathComponent("settings.py"), encoding: .utf8)
        let declared = source.split(separator: "\n").first { $0.hasPrefix("LOCK_NAME = ") }
        XCTAssertEqual(declared.map(String.init), "LOCK_NAME = \"\(ClaudeStatusLine.settingsLockName)\"",
                       "a different name would let the two edit settings.json at once")
    }

    // MARK: - Status-line failures never cost the hooks

    func testAnUnwritableStatusLineDirectoryStillInstallsTheHooks() throws {
        // `claudehelpers` as a plain file: nothing can be created under it.
        try Data().write(to: tmpDir.appendingPathComponent("claudehelpers"))
        try writeSettings(["statusLine": ["type": "command", "command": "my-own-status-line"]])
        XCTAssertEqual(installer.installHooks(), .installed)
        XCTAssertTrue(installer.isInstalled(in: try installer.loadSettings()))
        XCTAssertEqual(slot, "my-own-status-line", "the slot is left as it was")
        XCTAssertThrowsError(try installer.setStatusLineDisplay(true), "turning the line on reports why")
    }

    func testUninstallDeletesNoEntryWhenTheSaveFails() throws {
        installer.installHooks()
        assertDispatching()
        // A read-only settings directory: the lock files exist, but no
        // temporary file can be created beside settings.json, so the save fails.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: tmpDir.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmpDir.path) }
        XCTAssertFalse(installer.uninstallHooks())
        XCTAssertNotNil(installer.statusLine.entry(named: "stenographer"),
                        "the slot still runs the dispatcher, so our entry must still be there")
        XCTAssertEqual(slot, installer.statusLine.dispatcherCommand)
    }

    func testOurOwnCommandAdoptedByAnotherInstallerIsRemoved() throws {
        // Another installer took the slot from an earlier build and kept our
        // command as `adopted`: left there, our line would draw twice.
        _ = try installer.statusLine.adopt("\(Self.steno) statusline")
        try writeSettings(["statusLine": ["type": "command", "command": installer.statusLine.dispatcherCommand]])
        XCTAssertEqual(installer.installHooks(), .installed)
        assertDispatching()
        XCTAssertTrue(adopted.isEmpty, "\(adopted)")
    }

    func testUninstallRemovesOurOwnAdoptedCommandToo() throws {
        installer.installHooks()
        _ = try installer.statusLine.adopt("'/Users/x/Old Apps/Stenographer.app/Contents/Helpers/steno' statusline")
        installer.uninstallHooks()
        XCTAssertTrue(installer.statusLine.entries().isEmpty)
        XCTAssertNil(slot)
    }

    func testAMarkerInAForeignCommandIsAdoptedNotTakenForTheDispatcher() throws {
        let foreign = "my-line.sh # claudehelpers-statusline"
        try writeSettings(["statusLine": ["type": "command", "command": foreign]])
        XCTAssertFalse(installer.isStatusLineDisplayed, "a marker alone is not our line")
        installer.installHooks()
        assertDispatching()
        XCTAssertEqual(adopted.map(\.command), [foreign])
    }

    // MARK: - Conformance with claudehelpers

    func testUninstallFollowsTheSharedHandBackRule() throws {
        let cases = try StatusLineConformance.load().release
        XCTAssertFalse(cases.isEmpty)
        for testCase in cases {
            try? FileManager.default.removeItem(at: installer.statusLine.directory)
            try? FileManager.default.removeItem(at: settingsURL)
            installer.installHooks()
            for entry in testCase.remaining {
                try StatusLineConformance.write(entry, under: installer.statusLine.directory)
            }
            installer.uninstallHooks()
            let expected: String? = switch testCase.slot {
            case "removed": nil
            case "dispatcher": installer.statusLine.dispatcherCommand
            default: testCase.slot
            }
            XCTAssertEqual(slot, expected, testCase.about)
            XCTAssertEqual(installer.statusLine.entries().map { [$0.kind.rawValue, $0.name, $0.command] },
                           testCase.remaining, testCase.about)
        }
    }

    func testInstallsAllNonDelegationEventTypes() throws {
        installer.installHooks()
        let settings = try installer.loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any] else {
            XCTFail("No hooks in settings")
            return
        }
        for eventType in installer.hookedEventTypes {
            XCTAssertNotNil(hooks[eventType], "Missing hook for \(eventType)")
        }
    }

    func testDoesNotRegisterDelegationHooks() throws {
        // Registering hooks under delegation event types (WorktreeCreate, WorktreeRemove)
        // causes the corresponding Claude Code tool to fail because it hands the action
        // off to the hook and our hook produces no output. These slots must stay empty.
        installer.installHooks()
        let settings = try installer.loadSettings()
        let hooks = settings["hooks"] as? [String: Any] ?? [:]
        for delegation in ClaudeHookInstaller.delegationEventTypes {
            XCTAssertNil(hooks[delegation],
                         "Must not register a hook under delegation event type \(delegation)")
        }
    }

    func testScrubsStaleDelegationHooksOnInstall() throws {
        // A previously-installed stenographer WorktreeCreate/WorktreeRemove hook must
        // be cleaned up on the next install, even when the rest of the install is
        // already current (isInstalled == true).
        let stale: [String: Any] = [
            "hooks": [
                "WorktreeCreate": [
                    ["hooks": [["type": "command", "command": installer.makeCommand(eventType: "WorktreeCreate")]]]
                ],
                "WorktreeRemove": [
                    ["hooks": [["type": "command", "command": "# stenographer-hook-v2\necho hi\nexit 0"]]]
                ]
            ]
        ]
        try installer.saveSettings(stale)

        XCTAssertEqual(installer.installHooks(), .installed)

        let settings = try installer.loadSettings()
        let hooks = settings["hooks"] as? [String: Any] ?? [:]
        XCTAssertNil(hooks["WorktreeCreate"], "Stale WorktreeCreate hook must be scrubbed")
        XCTAssertNil(hooks["WorktreeRemove"], "Stale WorktreeRemove (legacy v2) hook must be scrubbed")
    }

    func testScrubsDelegationHooksEvenWhenAlreadyInstalled() throws {
        // If stenographer is already installed on all non-delegation event types but
        // a stale WorktreeCreate hook survives from a prior version, the second
        // install must still remove the stale hook (and persist). Because that scrub
        // mutates settings, the result is .installed (not .alreadyInstalled) even
        // though no new event types were added.
        installer.installHooks()
        var settings = try installer.loadSettings()
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        hooks["WorktreeCreate"] = [
            ["hooks": [["type": "command", "command": installer.makeCommand(eventType: "WorktreeCreate")]]]
        ]
        settings["hooks"] = hooks
        try installer.saveSettings(settings)

        XCTAssertEqual(installer.installHooks(), .installed)

        let updated = try installer.loadSettings()
        let updatedHooks = updated["hooks"] as? [String: Any] ?? [:]
        XCTAssertNil(updatedHooks["WorktreeCreate"],
                     "Stale delegation hook must be scrubbed even when no new hooks are added")
    }

    func testDoesNotRegisterNonHookEventTypes() throws {
        // StatusLine is not a Claude Code hook event — it's synthesized by the
        // stenographer-status-line dispatcher. Registering a hook for it triggers
        // an "Unknown hook event" warning at every session start.
        installer.installHooks()
        let settings = try installer.loadSettings()
        let hooks = settings["hooks"] as? [String: Any] ?? [:]
        for nonHook in ClaudeHookInstaller.nonHookEventTypes {
            XCTAssertNil(hooks[nonHook],
                         "Must not register a hook under non-hook event type \(nonHook)")
        }
    }

    func testScrubsStaleNonHookEventHooksOnInstall() throws {
        // A prior version that registered StatusLine must be cleaned up on next install.
        let stale: [String: Any] = [
            "hooks": [
                "StatusLine": [
                    ["hooks": [["type": "command", "command": installer.makeCommand(eventType: "StatusLine")]]]
                ]
            ]
        ]
        try installer.saveSettings(stale)

        XCTAssertEqual(installer.installHooks(), .installed)

        let settings = try installer.loadSettings()
        let hooks = settings["hooks"] as? [String: Any] ?? [:]
        XCTAssertNil(hooks["StatusLine"], "Stale StatusLine hook must be scrubbed")
    }

    func testScrubPreservesThirdPartyDelegationHooks() throws {
        // If another tool (e.g. whippet) has a hook registered for WorktreeCreate,
        // we must only remove our own entry and leave theirs alone.
        let existing: [String: Any] = [
            "hooks": [
                "WorktreeCreate": [
                    ["hooks": [["type": "command", "command": installer.makeCommand(eventType: "WorktreeCreate")]]],
                    ["hooks": [["type": "command", "command": "# whippet-hook\necho ok"]]]
                ]
            ]
        ]
        try installer.saveSettings(existing)

        installer.installHooks()

        let settings = try installer.loadSettings()
        let hooks = settings["hooks"] as? [String: Any] ?? [:]
        let wcGroups = hooks["WorktreeCreate"] as? [[String: Any]] ?? []
        XCTAssertEqual(wcGroups.count, 1, "Only our WorktreeCreate hook should be removed")
        let cmd = (wcGroups.first?["hooks"] as? [[String: Any]])?.first?["command"] as? String ?? ""
        XCTAssertTrue(cmd.contains("whippet-hook"), "Surviving WorktreeCreate hook must be the third-party one")
    }

    func testPreservesExistingHooks() throws {
        let existing: [String: Any] = [
            "hooks": [
                "SessionStart": [
                    [
                        "hooks": [
                            ["type": "command", "command": "# whippet-hook\necho hi"]
                        ]
                    ]
                ]
            ]
        ]
        try installer.saveSettings(existing)
        installer.installHooks()

        let settings = try installer.loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any],
              let sessionStartGroups = hooks["SessionStart"] as? [[String: Any]] else {
            XCTFail("Missing hooks")
            return
        }
        // Should have both the whippet group and the stenographer group
        XCTAssertEqual(sessionStartGroups.count, 2)
    }

    func testCommandContainsCurrentMarker() {
        let cmd = installer.makeCommand(eventType: "PreToolUse")
        XCTAssertTrue(cmd.contains(installer.configuration.marker), "Command must contain current marker")
    }

    func testAllHooksAreAsyncWithTimeout() throws {
        installer.installHooks()
        let settings = try installer.loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any] else {
            XCTFail("No hooks in settings")
            return
        }
        for eventType in installer.hookedEventTypes {
            guard let groups = hooks[eventType] as? [[String: Any]] else {
                XCTFail("Missing hook group for \(eventType)")
                continue
            }
            let hookDefs = groups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }
            guard let hookDef = hookDefs.first(where: { installer.isCurrentHook($0, eventType: eventType) }) else {
                XCTFail("Could not find the stenographer capture hook for \(eventType)")
                continue
            }
            XCTAssertEqual(hookDef["type"] as? String, "command")
            XCTAssertEqual(hookDef["command"] as? String, installer.makeCommand(eventType: eventType))
            XCTAssertEqual(hookDef["async"] as? Bool, true,
                           "\(eventType) hook must be async to avoid blocking Claude Code")
            XCTAssertEqual(hookDef["timeout"] as? Int, 10,
                           "\(eventType) hook must have a short timeout")
        }
    }

    // MARK: - capture-script hook registration

    func testInstallRegistersCaptureHooksNeverHTTP() throws {
        // An `http` hook that cannot connect is an ECONNREFUSED error in every
        // Claude session and a destroyed event, so nothing stenographer
        // registers may depend on the daemon being up.
        installer.installHooks()
        let settings = try installer.loadSettings()
        let hooks = try XCTUnwrap(settings["hooks"] as? [String: Any])
        for eventType in installer.hookedEventTypes {
            let groups = try XCTUnwrap(hooks[eventType] as? [[String: Any]])
            let hookDefs = groups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }
            let ours = hookDefs.filter(installer.isOwnHook)
            XCTAssertEqual(ours.count, 1, "\(eventType) must have exactly one stenographer hook")
            XCTAssertTrue(ours.allSatisfy { installer.isCurrentHook($0, eventType: eventType) },
                          "\(eventType) must be the capture-script command")
            XCTAssertFalse(hookDefs.contains(where: installer.isHTTPHook),
                           "\(eventType) must not carry an http hook")
        }
    }

    func testLegacyHTTPBaseIsLoopbackOnly() {
        let base = installer.configuration.legacy.httpHookURLBase
        XCTAssertEqual(base, "http://127.0.0.1:22847/hook")
        XCTAssertTrue(base?.hasPrefix("http://127.0.0.1:") == true, "the hook url must be loopback-only")
    }

    /// Installs once over `legacy`, registered alone under PreToolUse, and
    /// returns that event's hook entries afterwards.
    private func installOver(_ legacy: [String: Any]) throws -> [[String: Any]] {
        try installer.saveSettings(["hooks": ["PreToolUse": [["hooks": [legacy]]]]])
        XCTAssertEqual(installer.installHooks(), .installed)
        let settings = try installer.loadSettings()
        let groups = try XCTUnwrap((settings["hooks"] as? [String: Any])?["PreToolUse"] as? [[String: Any]])
        return groups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }
    }

    func testLegacyHTTPHookIsReplacedByTheCaptureHook() throws {
        // The migration this change turns on: a machine on the http hook must have
        // it replaced on the next daemon start — removed, not left alongside
        // (which would double-ingest every event and keep the refused-connection
        // errors coming).
        let hookDefs = try installOver(["type": "http", "url": "http://127.0.0.1:22847/hook/PreToolUse",
                                        "async": true, "timeout": 10])
        XCTAssertFalse(hookDefs.contains(where: installer.isHTTPHook), "the http hook must be gone")
        XCTAssertEqual(hookDefs.count, 1, "exactly one capture hook must replace it")
        XCTAssertTrue(installer.isCurrentHook(hookDefs[0], eventType: "PreToolUse"))
    }

    func testLegacyV7BashHookIsReplacedByTheCaptureHook() throws {
        let hookDefs = try installOver(["type": "command", "command":
            "# stenographer-hook-v7\n/usr/local/bin/stenographer-hook.sh PreToolUse\nexit 0"])
        XCTAssertFalse(hookDefs.contains { installer.isOwnHook($0)
                                            && !installer.isCurrentHook($0, eventType: "PreToolUse") },
                       "the v7 bash hook must be gone")
        XCTAssertEqual(hookDefs.count, 1, "exactly one capture hook must replace it")
        XCTAssertTrue(installer.isCurrentHook(hookDefs[0], eventType: "PreToolUse"))
    }

    func testAHookRenderedDifferentlyIsReRendered() throws {
        // An entry naming the retired python capture script is ours but no
        // longer runs what this build would: re-rendered, never duplicated.
        let hookDefs = try installOver(["type": "command", "command":
            "# stenographer-hook-v8\n'/usr/bin/python3' '/Users/x/.claude/stenographer-capture.py' PreToolUse\nexit 0"])
        XCTAssertEqual(hookDefs.count, 1)
        XCTAssertTrue(installer.isCurrentHook(hookDefs[0], eventType: "PreToolUse"))
    }

    func testCommandInvokesTheBundledSteno() {
        let cmd = installer.makeCommand(eventType: "PreToolUse")
        XCTAssertTrue(cmd.contains("\(Self.steno) hook --event PreToolUse"),
                      "Command must run the bundle's steno with the event")
        XCTAssertFalse(cmd.contains("stenographer-hook.sh"), "Command must not invoke the shell hook")
        XCTAssertFalse(cmd.contains("python"), "Command must not need an interpreter")
        XCTAssertFalse(cmd.contains("jq"), "Command must not use jq")
    }

    func testCommandNamesNothingInsideUsrLocalBin() {
        // /usr/local/bin entries are symlinks into the bundle; a hook going
        // through one captures nothing while the link is being replaced.
        let cmd = installer.makeCommand(eventType: "PreToolUse")
        XCTAssertFalse(cmd.contains("/tmp/test-events"),
                       "Command must not contain the drop directory")
        XCTAssertFalse(cmd.contains("/usr/local/bin" + "/"),
                       "Command must not go through a /usr/local/bin symlink")
    }

    func testShellQuoteLeavesSafeWordsBareAndQuotesTheRest() {
        XCTAssertEqual(ShellQuoting.quoteIfNeeded("/usr/bin/python3"), "/usr/bin/python3")
        XCTAssertEqual(ShellQuoting.quoteIfNeeded("a b"), "'a b'")
        XCTAssertEqual(ShellQuoting.quoteIfNeeded("it's"), #"'it'"'"'s'"#)
        XCTAssertEqual(ShellQuoting.quoteIfNeeded(""), "''")
    }

    func testStatusLineCommandIsAbsolute() {
        // Same PATH hazard as the hooks: a bare `stenographer statusline` renders
        // blank in GUI-launched sessions. The registered command must be absolute.
        XCTAssertEqual(installer.statusLineCommand, "\(Self.steno) statusline")
        XCTAssertTrue(installer.statusLineCommand.hasPrefix("/"),
                      "statusLine command must be an absolute path")
    }

    func testCommandIsThreeLines() {
        // Each settings.json entry collapses to marker + invocation + exit.
        // The steno path is absolute, so the hook resolves under a GUI
        // session's minimal PATH.
        let cmd = installer.makeCommand(eventType: "Stop")
        let lines = cmd.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        XCTAssertEqual(lines.count, 3, "Expected 3-line command, got: \(cmd)")
        XCTAssertEqual(lines[0], installer.configuration.marker)
        XCTAssertEqual(lines[1], "\(Self.steno) hook --event Stop")
        XCTAssertEqual(lines[2], "exit 0")
    }

    func testCommandContainsEventType() {
        let cmd = installer.makeCommand(eventType: "UserPromptSubmit")
        XCTAssertTrue(cmd.contains("UserPromptSubmit"), "Command must embed the event type")
    }

    func testCommandAlwaysExitsZero() {
        // exit 0 is the safety net that prevents hooks from ever failing Claude Code operations.
        // Applies to makeCommand output for every event type, including delegation types
        // (where the command is useful for ad-hoc CLI scripting even though we no longer
        // register it in settings.json).
        for eventType in HookEventType.allCases {
            let cmd = installer.makeCommand(eventType: eventType.rawValue)
            XCTAssertTrue(cmd.contains("exit 0"),
                          "\(eventType.rawValue) command must unconditionally exit 0")
        }
    }

    // MARK: - Uninstall edge cases

    func testUninstallWhenNothingInstalled() {
        // uninstallHooks must return false rather than throwing when no hooks exist
        let removed = installer.uninstallHooks()
        XCTAssertFalse(removed)
    }

    func testUninstallPreservesThirdPartyHooks() throws {
        // Only stenographer hooks should be removed; whippet/other hooks must survive
        let existing: [String: Any] = [
            "hooks": [
                "PreToolUse": [
                    [
                        "hooks": [
                            ["type": "command", "command": "# whippet-hook\necho hi"]
                        ]
                    ]
                ]
            ]
        ]
        try installer.saveSettings(existing)
        installer.installHooks()
        installer.uninstallHooks()

        let settings = try installer.loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any],
              let groups = hooks["PreToolUse"] as? [[String: Any]] else {
            XCTFail("PreToolUse hooks missing after uninstall")
            return
        }
        XCTAssertEqual(groups.count, 1, "Whippet hook group should survive uninstall")
        let cmd = (groups[0]["hooks"] as? [[String: Any]])?.first?["command"] as? String ?? ""
        XCTAssertTrue(cmd.contains("whippet-hook"), "Surviving hook should be the whippet one")
    }

    func testUninstallRemovesHookFromEventTypeNotInCurrentList() throws {
        // Backward compat: if a future version removes an event type from hookedEventTypes,
        // uninstall must still clean up hooks for that type found in settings.
        let obsoleteEventType = "ObsoleteEventThatWasRemovedInV4"
        let ourCmd = installer.makeCommand(eventType: obsoleteEventType)
        let settings: [String: Any] = [
            "hooks": [
                obsoleteEventType: [
                    ["hooks": [["type": "command", "command": ourCmd]]]
                ]
            ]
        ]
        try installer.saveSettings(settings)

        let removed = installer.uninstallHooks()
        XCTAssertTrue(removed)

        let updated = try installer.loadSettings()
        let hooks = updated["hooks"] as? [String: Any]
        XCTAssertNil(hooks?[obsoleteEventType], "Obsolete event type key should be removed")
    }

    func testInstallUninstallReinstall() throws {
        // Round-trip: install → uninstall → install should work cleanly
        XCTAssertEqual(installer.installHooks(), .installed)
        XCTAssertTrue(installer.uninstallHooks())
        XCTAssertEqual(installer.installHooks(), .installed)

        let settings = try installer.loadSettings()
        XCTAssertTrue(installer.isInstalled(in: settings))
    }

    // MARK: - loadSettings edge cases

    func testLoadSettingsReturnsEmptyForMissingFile() throws {
        // File does not exist yet — should return empty dict, not throw
        let result = try installer.loadSettings()
        XCTAssertTrue(result.isEmpty)
    }

    func testLoadSettingsReturnsEmptyForEmptyFile() throws {
        try Data().write(to: settingsURL)
        let result = try installer.loadSettings()
        XCTAssertTrue(result.isEmpty)
    }

    func testLoadSettingsThrowsForInvalidJSON() throws {
        try Data("not json {{{{".utf8).write(to: settingsURL)
        XCTAssertThrowsError(try installer.loadSettings())
    }

    func testInstallReturnsFailedForCorruptSettings() throws {
        try Data("not json {{{{".utf8).write(to: settingsURL)
        let result = installer.installHooks()
        guard case .failed = result else {
            XCTFail("Expected .failed, got \(result)")
            return
        }
    }

    // MARK: - isInstalled edge cases

    func testIsInstalledReturnsFalseOnEmptySettings() {
        XCTAssertFalse(installer.isInstalled(in: [:]))
    }

    func testIsInstalledReturnsFalseWhenOnlyOtherHooksPresent() {
        let settings: [String: Any] = [
            "hooks": [
                "PreToolUse": [
                    ["hooks": [["type": "command", "command": "# whippet-hook\necho hi"]]]
                ]
            ]
        ]
        XCTAssertFalse(installer.isInstalled(in: settings))
    }

    // MARK: - Marker safety

    func testCurrentCaptureHookNotMisidentifiedAsLegacy() throws {
        // "# stenographer-hook" — the v1 marker — is also the current one, so
        // every form of ours is a stenographer hook and only `isCurrentHook`
        // tells current from stale. If it ever rejected the current rendering,
        // install would loop: remove → detect not installed → re-add → repeat.
        installer.installHooks()

        // A second install must report alreadyInstalled, not installed (which would
        // indicate the current hooks were falsely stripped as legacy).
        XCTAssertEqual(installer.installHooks(), .alreadyInstalled,
                       "Current capture hook must not be mistaken for a legacy one")
        let current = ["type": "command", "command": installer.makeCommand(eventType: "Stop")]
        XCTAssertTrue(installer.isOwnHook(current))
        XCTAssertTrue(installer.isCurrentHook(current, eventType: "Stop"))
    }

    func testLegacyV1HooksAreUpgradedOnInstall() throws {
        let legacyCmd = """
        # stenographer-hook
        INPUT=$(cat)
        echo "$INPUT" | jq -c '.data' > /tmp/test.json
        exit 0
        """
        let legacy: [String: Any] = [
            "hooks": [
                "SessionStart": [
                    [
                        "hooks": [
                            ["type": "command", "command": legacyCmd]
                        ]
                    ]
                ]
            ]
        ]
        try installer.saveSettings(legacy)

        let result = installer.installHooks()
        XCTAssertEqual(result, .installed)

        let settings = try installer.loadSettings()
        XCTAssertTrue(installer.isInstalled(in: settings), "v3 hooks should be installed")

        guard let hooks = settings["hooks"] as? [String: Any],
              let sessionStartGroups = hooks["SessionStart"] as? [[String: Any]] else {
            XCTFail("Missing hooks")
            return
        }
        // Legacy v1 hook must be gone; the current capture hook must be present.
        let hasLegacy = sessionStartGroups.contains { group in
            (group["hooks"] as? [[String: Any]])?.contains {
                ($0["command"] as? String)?.contains("INPUT=$(cat)") == true
            } == true
        }
        XCTAssertFalse(hasLegacy, "Legacy v1 hooks should be removed after upgrade")

        let currentGroup = sessionStartGroups.first { installer.isCurrentGroup($0, eventType: "SessionStart") }
        XCTAssertNotNil(currentGroup, "current capture hook group must exist after upgrade")

        let hook = (currentGroup?["hooks"] as? [[String: Any]])?.first
        XCTAssertEqual(hook?["command"] as? String, installer.makeCommand(eventType: "SessionStart"))
        XCTAssertEqual(hook?["async"] as? Bool, true, "Upgraded hook must be async")
        XCTAssertEqual(hook?["timeout"] as? Int, 10, "Upgraded hook must have timeout=10")
    }

    func testLegacyV5HooksAreUpgradedOnInstall() throws {
        // v5 hooks (the CLI-dispatch form: `stenographer hook --event …`)
        // must be scrubbed and replaced when the daemon installs v6.
        let v5Cmd = """
        # stenographer-hook-v5
        stenographer hook --event PreToolUse --ppid "$PPID"
        exit 0
        """
        let legacy: [String: Any] = [
            "hooks": [
                "PreToolUse": [
                    ["hooks": [["type": "command", "command": v5Cmd]]]
                ]
            ]
        ]
        try installer.saveSettings(legacy)

        XCTAssertEqual(installer.installHooks(), .installed)

        let settings = try installer.loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any],
              let preToolGroups = hooks["PreToolUse"] as? [[String: Any]] else {
            XCTFail("Missing hooks")
            return
        }
        for group in preToolGroups {
            guard let hookList = group["hooks"] as? [[String: Any]] else { continue }
            for hook in hookList {
                let cmd = hook["command"] as? String ?? ""
                XCTAssertFalse(cmd.contains("# stenographer-hook-v5"),
                               "Legacy v5 hooks should be removed")
            }
        }
    }

    func testLegacyV6HooksAreUpgradedToTheCaptureHook() throws {
        // v6 hooks (the path-free bash form: bare `stenographer-hook.sh …`) must be
        // scrubbed and replaced with the current capture hook.
        let v6Cmd = """
        # stenographer-hook-v6
        stenographer-hook.sh PreToolUse
        exit 0
        """
        let legacy: [String: Any] = [
            "hooks": [
                "PreToolUse": [
                    ["hooks": [["type": "command", "command": v6Cmd]]]
                ]
            ]
        ]
        try installer.saveSettings(legacy)

        XCTAssertEqual(installer.installHooks(), .installed)

        let settings = try installer.loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any],
              let preToolGroups = hooks["PreToolUse"] as? [[String: Any]] else {
            XCTFail("Missing hooks")
            return
        }
        let hookDefs = preToolGroups.flatMap { ($0["hooks"] as? [[String: Any]]) ?? [] }
        // Exactly one stenographer entry, and it must be the capture hook.
        XCTAssertFalse(hookDefs.contains { installer.isOwnHook($0)
                                            && !installer.isCurrentHook($0, eventType: "PreToolUse") },
                       "legacy v6 bash hook must be gone")
        XCTAssertEqual(hookDefs.count, 1, "the old v6 group must be replaced by one hook, not duplicated")
        XCTAssertTrue(installer.isCurrentHook(hookDefs[0], eventType: "PreToolUse"))
    }

    func testLegacyV4HooksAreUpgradedOnInstall() throws {
        // v4 hooks (the inlined-Python form that shipped before the CLI
        // dispatch) must be scrubbed and replaced when the daemon installs
        // v5. This is the in-place upgrade path: existing settings.json
        // already has 25 v4 entries from the prior install.
        let v4Cmd = """
        # stenographer-hook-v4
        _CW_DATA=$(cat)
        echo "$_CW_DATA" | python3 -c "pass"
        exit 0
        """
        let legacy: [String: Any] = [
            "hooks": [
                "PreToolUse": [
                    ["hooks": [["type": "command", "command": v4Cmd]]]
                ]
            ]
        ]
        try installer.saveSettings(legacy)

        XCTAssertEqual(installer.installHooks(), .installed)

        let settings = try installer.loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any],
              let preToolGroups = hooks["PreToolUse"] as? [[String: Any]] else {
            XCTFail("Missing hooks")
            return
        }
        for group in preToolGroups {
            guard let hookList = group["hooks"] as? [[String: Any]] else { continue }
            for hook in hookList {
                let cmd = hook["command"] as? String ?? ""
                XCTAssertFalse(cmd.contains("# stenographer-hook-v4"),
                               "Legacy v4 hooks should be removed")
            }
        }
    }

    func testLegacyV2HooksAreUpgradedOnInstall() throws {
        let v2Cmd = """
        # stenographer-hook-v2
        _CW_DATA=$(cat)
        echo "$_CW_DATA" | python3 -c "pass"
        exit 0
        """
        let legacy: [String: Any] = [
            "hooks": [
                "PreToolUse": [
                    [
                        "hooks": [
                            ["type": "command", "command": v2Cmd]
                        ]
                    ]
                ]
            ]
        ]
        try installer.saveSettings(legacy)

        let result = installer.installHooks()
        XCTAssertEqual(result, .installed)

        let settings = try installer.loadSettings()
        XCTAssertTrue(installer.isInstalled(in: settings), "v3 hooks should be installed")

        guard let hooks = settings["hooks"] as? [String: Any],
              let preToolGroups = hooks["PreToolUse"] as? [[String: Any]] else {
            XCTFail("Missing hooks")
            return
        }
        for group in preToolGroups {
            guard let hookList = group["hooks"] as? [[String: Any]] else { continue }
            for hook in hookList {
                let cmd = hook["command"] as? String ?? ""
                XCTAssertFalse(cmd.contains("# stenographer-hook-v2"), "Legacy v2 hooks should be removed")
            }
        }
    }
}
