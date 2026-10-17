@testable import AgenticToolkitCore
import XCTest

// ClaudeStatusLine is compiled into this test target with the rest of
// stenographerd/Sources, so no @testable import.

/// The file side of claudehelpers' status-line contract
/// (`external/claudehelpers/scripts/statuslinedispatcher/docs/statusline.md`).
final class ClaudeStatusLineTests: XCTestCase {

    private var claudeDir: URL!

    override func setUpWithError() throws {
        claudeDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("claude-status-line-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: claudeDir)
    }

    private func makeStatusLine(version: Int = 1) throws -> ClaudeStatusLine {
        ClaudeStatusLine(claudeDirectory: claudeDir,
                         bundledDispatcher: try StatusLineTestSupport.makeBundledDispatcher(in: claudeDir,
                                                                                            version: version))
    }

    private func installedVersion(_ statusLine: ClaudeStatusLine) -> Int? {
        (try? String(contentsOf: statusLine.dispatcherURL, encoding: .utf8)).flatMap(ClaudeStatusLine.dispatcherVersion)
    }

    private func mode(_ url: URL) throws -> Int? {
        try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
    }

    // MARK: - The dispatcher

    func testTheBundledDispatcherCarriesAVersion() throws {
        let url = try StatusLineTestSupport.requireSubmodule(StatusLineTestSupport.realDispatcher)
        XCTAssertNotNil(ClaudeStatusLine.dispatcherVersion(try String(contentsOf: url, encoding: .utf8)),
                        "installDispatcher refuses a dispatcher without its version line")
    }

    func testInstallWritesAnExecutableDispatcher() throws {
        let statusLine = try makeStatusLine()
        XCTAssertTrue(try statusLine.installDispatcher().wrote)
        XCTAssertEqual(installedVersion(statusLine), 1)
        XCTAssertEqual(try mode(statusLine.dispatcherURL), 0o755)
        XCTAssertEqual(try mode(statusLine.directory), 0o700)
        XCTAssertFalse(try statusLine.installDispatcher().wrote, "the same version is not rewritten")
    }

    func testInstallUpgradesButNeverDowngrades() throws {
        XCTAssertEqual(try makeStatusLine(version: 2).installDispatcher(),
                       .init(installed: nil, offered: 2, wrote: true))
        XCTAssertEqual(try makeStatusLine(version: 1).installDispatcher(),
                       .init(installed: 2, offered: 1, wrote: false), "a newer tool's dispatcher stays")
        XCTAssertEqual(installedVersion(try makeStatusLine()), 2)
        XCTAssertEqual(try makeStatusLine(version: 3).installDispatcher(),
                       .init(installed: 2, offered: 3, wrote: true))
        XCTAssertEqual(installedVersion(try makeStatusLine()), 3)
    }

    func testAnUnversionedInstalledDispatcherIsReplaced() throws {
        let statusLine = try makeStatusLine(version: 2)
        try FileManager.default.createDirectory(at: statusLine.directory, withIntermediateDirectories: true)
        try "#!/bin/sh\necho hand-edited\n".write(to: statusLine.dispatcherURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(try statusLine.installDispatcher().wrote, "a copy no installer can order is replaced")
        XCTAssertEqual(installedVersion(statusLine), 2)
    }

    func testAMissingBundledDispatcherThrowsOnlyWhenNoneIsInstalled() throws {
        let missing = ClaudeStatusLine(claudeDirectory: claudeDir,
                                       bundledDispatcher: claudeDir.appendingPathComponent("nope.sh"))
        XCTAssertThrowsError(try missing.installDispatcher()) { error in
            XCTAssertEqual(error as? ClaudeStatusLine.Failure, .dispatcherMissing(missing.bundledDispatcher.path))
        }
        try makeStatusLine().installDispatcher()
        XCTAssertFalse(try missing.installDispatcher().wrote, "the installed one serves")
    }

    func testAnUnversionedBundledDispatcherThrowsOnlyWhenNoneIsInstalled() throws {
        let unversioned = claudeDir.appendingPathComponent("plain.sh")
        try "#!/bin/sh\n".write(to: unversioned, atomically: true, encoding: .utf8)
        let statusLine = ClaudeStatusLine(claudeDirectory: claudeDir, bundledDispatcher: unversioned)
        XCTAssertThrowsError(try statusLine.installDispatcher()) { error in
            XCTAssertTrue(error.localizedDescription.contains("plain.sh"), error.localizedDescription)
        }
        try makeStatusLine().installDispatcher()
        XCTAssertFalse(try statusLine.installDispatcher().wrote, "the installed one serves")
        XCTAssertEqual(installedVersion(statusLine), 1)
    }

    func testTheDispatcherCommandMatchesClaudeHelpers() throws {
        let statusLine = try makeStatusLine()
        let expected = claudeDir.appendingPathComponent("claudehelpers/statusline/dispatch.sh")
        XCTAssertEqual(statusLine.dispatcherURL.standardizedFileURL.path, expected.standardizedFileURL.path)
        XCTAssertEqual(statusLine.dispatcherCommand,
                       "sh \(ShellQuote.word(statusLine.dispatcherURL.path)) # claudehelpers-statusline")
        XCTAssertTrue(ClaudeStatusLine.isDispatcherCommand(statusLine.dispatcherCommand))
    }

    // MARK: - Entries

    func testRegisterSwitchesKindsAndUnregisterClearsTheError() throws {
        let statusLine = try makeStatusLine()
        try statusLine.register(.renderers, name: "stenographer", command: "steno statusline")
        XCTAssertEqual(statusLine.entries(),
                       [.init(kind: .renderers, name: "stenographer", command: "steno statusline")])
        XCTAssertEqual(try mode(statusLine.directory.appendingPathComponent("renderers/stenographer")), 0o600,
                       "an entry can hold a token, so it is owner-only")
        XCTAssertEqual(try mode(statusLine.directory.appendingPathComponent("renderers")), 0o700)
        try statusLine.register(.taps, name: "stenographer", command: "steno statusline --capture-only")
        XCTAssertEqual(statusLine.entries(),
                       [.init(kind: .taps, name: "stenographer", command: "steno statusline --capture-only")],
                       "a name lives in one kind at a time")
        let error = statusLine.directory.appendingPathComponent("errors/stenographer")
        try FileManager.default.createDirectory(at: error.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try "exit 1\n".write(to: error, atomically: true, encoding: .utf8)
        XCTAssertTrue(try statusLine.unregister("stenographer"))
        XCTAssertTrue(statusLine.entries().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: error.path))
        XCTAssertFalse(try statusLine.unregister("stenographer"))
    }

    func testEntriesSkipInvalidNames() throws {
        let statusLine = try makeStatusLine()
        let renderers = statusLine.directory.appendingPathComponent("renderers")
        try FileManager.default.createDirectory(at: renderers, withIntermediateDirectories: true)
        try "x\n".write(to: renderers.appendingPathComponent(".hidden"), atomically: true, encoding: .utf8)
        try "y\n".write(to: renderers.appendingPathComponent("ok-1.b"), atomically: true, encoding: .utf8)
        XCTAssertEqual(statusLine.entries().map(\.name), ["ok-1.b"])
        XCTAssertNil(statusLine.entry(named: "../renderers/ok-1.b"))
    }

    func testAnAdoptedEntryIsOwnerOnly() throws {
        let statusLine = try makeStatusLine()
        XCTAssertEqual(try statusLine.adopt("TOKEN=secret mine.sh"), "adopted")
        XCTAssertEqual(try mode(statusLine.directory.appendingPathComponent("renderers/adopted")), 0o600)
    }

    func testAdoptNeverRemovesATapOfTheSameName() throws {
        let statusLine = try makeStatusLine()
        try statusLine.register(.taps, name: "adopted", command: "tool tap")
        XCTAssertEqual(try statusLine.adopt("mine.sh"), "adopted-2")
        XCTAssertEqual(statusLine.entry(named: "adopted"), .init(kind: .taps, name: "adopted", command: "tool tap"))
    }

    // MARK: - Conformance with claudehelpers

    func testConformanceWithClaudeHelpers() throws {
        let cases = try StatusLineConformance.load()
        for quote in cases.shellQuote {
            XCTAssertEqual(ShellQuote.word(quote.word), quote.quoted, "shlex.quote(\(quote.word.debugDescription))")
        }
        for check in cases.isDispatcherCommand {
            XCTAssertEqual(ClaudeStatusLine.isDispatcherCommand(check.command), check.expected,
                           check.command.debugDescription)
        }
        for check in cases.isAdoptedName {
            XCTAssertEqual(ClaudeStatusLine.isAdoptedName(check.name), check.expected, check.name)
        }
        for check in cases.isValidName {
            XCTAssertEqual(ClaudeStatusLine.isValidName(check.name), check.expected, check.name)
        }
        for check in cases.dispatcherVersion {
            XCTAssertEqual(ClaudeStatusLine.dispatcherVersion(check.text), check.version, check.text.debugDescription)
        }
    }

    func testAdoptFollowsTheSharedCases() throws {
        for testCase in try StatusLineConformance.load().adopt {
            let statusLine = try makeStatusLine()
            try? FileManager.default.removeItem(at: statusLine.directory)
            for entry in testCase.entries {
                try StatusLineConformance.write(entry, under: statusLine.directory)
            }
            XCTAssertEqual(try statusLine.adopt(testCase.command), testCase.name, testCase.about)
            XCTAssertEqual(statusLine.entries().filter { $0.kind == .renderers }.map { [$0.name, $0.command] },
                           testCase.renderers, testCase.about)
        }
    }

    // MARK: - End to end with the real dispatcher

    func testTheDispatcherRunsAdoptedAndOwnRenderersInNameOrder() throws {
        let dispatcher = try StatusLineTestSupport.requireSubmodule(StatusLineTestSupport.realDispatcher)
        let statusLine = ClaudeStatusLine(claudeDirectory: claudeDir, bundledDispatcher: dispatcher)
        try statusLine.installDispatcher()
        try statusLine.adopt("echo foreign")
        try statusLine.register(.renderers, name: "stenographer", command: "cat")
        try statusLine.register(.renderers, name: "broken", command: "exit 3")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", statusLine.dispatcherCommand]
        // No CLAUDEHELPERS_STATUSLINE_DIR: the dispatcher must find the
        // entries beside the copy installed here, not under $HOME.
        process.environment = ["HOME": claudeDir.appendingPathComponent("elsewhere").path,
                               "PATH": "/usr/bin:/bin"]
        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        let exited = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in exited.signal() }
        try process.run()
        input.fileHandleForWriting.write(Data("{\"payload\":1}".utf8))
        try input.fileHandleForWriting.close()
        // Bounded, so a dispatcher that hangs fails this test instead of the run.
        guard exited.wait(timeout: .now() + 15) == .success else {
            process.terminate()
            return XCTFail("the dispatcher was still running after 15s")
        }
        let printed = String(bytes: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(printed, "foreign\n{\"payload\":1}\n", "the broken renderer is left out")
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: statusLine.directory.appendingPathComponent("errors/broken").path))
        XCTAssertNotNil(statusLine.lastError(of: "broken"), "the dispatcher's record is what lastError reads")
        XCTAssertNil(statusLine.lastError(of: "stenographer"), "a renderer that succeeded has no record")
    }

    // MARK: - Last error

    func testLastErrorReadsTheDispatchersRecord() throws {
        let statusLine = try makeStatusLine()
        XCTAssertNil(statusLine.lastError(of: "stenographer"))
        let errors = statusLine.directory.appendingPathComponent("errors")
        try FileManager.default.createDirectory(at: errors, withIntermediateDirectories: true)
        try "exit 3\nsomething broke\n".write(to: errors.appendingPathComponent("stenographer"),
                                               atomically: true, encoding: .utf8)
        XCTAssertEqual(statusLine.lastError(of: "stenographer"), "exit 3\nsomething broke")
        try "  \n".write(to: errors.appendingPathComponent("blank"), atomically: true, encoding: .utf8)
        XCTAssertNil(statusLine.lastError(of: "blank"), "an empty record says nothing")
        XCTAssertNil(statusLine.lastError(of: "../errors/stenographer"), "only an entry name is read")
    }

    func testRegisterSaysWhetherItChangedAnything() throws {
        let statusLine = try makeStatusLine()
        XCTAssertTrue(try statusLine.register(.renderers, name: "stenographer", command: "cat"))
        XCTAssertFalse(try statusLine.register(.renderers, name: "stenographer", command: "cat"))
        XCTAssertTrue(try statusLine.register(.taps, name: "stenographer", command: "cat"), "a kind switch")
        XCTAssertTrue(try statusLine.register(.taps, name: "stenographer", command: "tee"), "a new command")
    }
}
