#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity
import AgenticToolkitPermissions

/// What `TerminalWorkingDirectoryReader` decides without a terminal: which
/// apps it will ask at all, and how it spends the one Automation consent it is
/// allowed to raise. The Apple Event send itself belongs to `AppleScriptRunner`
/// and is exercised by the live daemon, not here — a test process that really
/// asked would acquire a TCC grant of its own as a side effect.
@MainActor
final class TerminalWorkingDirectoryReaderTests: XCTestCase {
    private typealias Reader = TerminalWorkingDirectoryReader

    // MARK: - Which apps get asked

    func testITermIsRecognisedAndOtherAppsAreNot() {
        XCTAssertEqual(Reader.Family.forBundleID("com.googlecode.iterm2"), .iTerm2)
        XCTAssertNil(Reader.Family.forBundleID("com.apple.Terminal"))
        XCTAssertNil(Reader.Family.forBundleID("dev.warp.Warp-Stable"))
        XCTAssertNil(Reader.Family.forBundleID("com.apple.Safari"))
    }

    func testTheGrantIsAskedForAgainstTheAppBeingRead() {
        // Automation is granted per target app, so this string is the identity
        // of the grant and not only of the process. A typo here would ask the
        // owner to authorize controlling nothing.
        XCTAssertEqual(Reader.Family.iTerm2.targetBundleID, "com.googlecode.iterm2")
    }

    func testEverySupportedTerminalsScriptIsBounded() {
        // An unbounded Apple Event send runs on the daemon's main run loop, so
        // a wedged terminal would take the whole capture pipeline with it.
        for family in Reader.Family.allCases {
            XCTAssertTrue(family.script.contains("with timeout of"),
                          "\(family) sends an Apple Event with no timeout")
            XCTAssertTrue(family.script.contains(family.targetBundleID),
                          "\(family) does not address the app it is a grant for")
        }
    }

    // MARK: - Spending the one consent

    func testAnUnknownAppIsNeverAskedAndNeverProbed() {
        let probe = CountingProbe(status: noErr)
        let runner = ScriptedRunner(result: "/tmp")
        let reader = Reader(probe: probe, runner: runner)

        XCTAssertNil(reader.workingDirectory(forBundleID: "com.apple.Safari"))
        XCTAssertEqual(probe.calls, 0)
        XCTAssertEqual(runner.calls, 0)
    }

    func testTheFirstReadAsksForConsentAndAnswersNothing() async {
        let probe = CountingProbe(status: noErr)
        let runner = ScriptedRunner(result: "/Users/me/project")
        let reader = Reader(probe: probe, runner: runner)

        // The consent probe blocks until the dialog is dismissed, so it runs
        // off the main actor and this read cannot wait for it.
        XCTAssertNil(reader.workingDirectory(forBundleID: "com.googlecode.iterm2"))
        XCTAssertEqual(runner.calls, 0, "asked the terminal before it was allowed to")

        await reader.consentTask?.value
        XCTAssertEqual(probe.calls, 1)
    }

    func testOnceGrantedTheTerminalIsAskedAndNeverProbedAgain() async {
        let probe = CountingProbe(status: noErr)
        let runner = ScriptedRunner(result: "/Users/me/project")
        let reader = Reader(probe: probe, runner: runner)

        _ = reader.workingDirectory(forBundleID: "com.googlecode.iterm2")
        await reader.consentTask?.value

        XCTAssertEqual(reader.workingDirectory(forBundleID: "com.googlecode.iterm2"),
                       "/Users/me/project")
        XCTAssertEqual(reader.workingDirectory(forBundleID: "com.googlecode.iterm2"),
                       "/Users/me/project")
        XCTAssertEqual(runner.calls, 2)
        XCTAssertEqual(probe.calls, 1, "re-probed a grant it had already been given")
    }

    func testADenialStopsTheReaderAskingForTheRestOfTheRun() async {
        let probe = CountingProbe(status: OSStatus(errAEEventNotPermitted))
        let runner = ScriptedRunner(result: "/Users/me/project")
        let reader = Reader(probe: probe, runner: runner)

        _ = reader.workingDirectory(forBundleID: "com.googlecode.iterm2")
        await reader.consentTask?.value

        XCTAssertNil(reader.workingDirectory(forBundleID: "com.googlecode.iterm2"))
        XCTAssertNil(reader.workingDirectory(forBundleID: "com.googlecode.iterm2"))
        XCTAssertEqual(runner.calls, 0)
        XCTAssertEqual(probe.calls, 1, "raised the consent dialog a second time")
    }

    func testAnEmptyAnswerIsNoAnswer() async {
        // iTerm2 reports an empty string for a session whose directory it has
        // not resolved. An empty path is not a place, and recording one would
        // put a blank document on the event.
        let probe = CountingProbe(status: noErr)
        let runner = ScriptedRunner(result: "")
        let reader = Reader(probe: probe, runner: runner)

        _ = reader.workingDirectory(forBundleID: "com.googlecode.iterm2")
        await reader.consentTask?.value

        XCTAssertNil(reader.workingDirectory(forBundleID: "com.googlecode.iterm2"))
    }

    func testOnlyAnOutrightPermitCountsAsGranted() {
        XCTAssertEqual(Reader.consent(for: noErr), .granted)
        XCTAssertEqual(Reader.consent(for: OSStatus(errAEEventNotPermitted)), .denied)
        // -1744 is "would require user consent", which after a prompt means the
        // owner dismissed it, and -600 is "no such process". Neither is an
        // answer this reader can act on, and both mean stop asking.
        XCTAssertEqual(Reader.consent(for: OSStatus(errAEEventWouldRequireUserConsent)), .denied)
        XCTAssertEqual(Reader.consent(for: OSStatus(procNotFound)), .denied)
    }

    // MARK: - Fakes

    /// Counts probes. `@unchecked Sendable` earned by a lock — the same idiom
    /// as `ContextFakes`' gates — because the reader calls this from a global
    /// queue, not from the actor the test runs on.
    private final class CountingProbe: AutomationProbing, @unchecked Sendable {
        private let status: OSStatus
        private let lock = NSLock()
        private var count = 0

        init(status: OSStatus) { self.status = status }

        var calls: Int { lock.withLock { count } }

        func permissionStatus(forBundleID bundleID: String, promptIfNeeded: Bool) -> OSStatus {
            lock.withLock { count += 1 }
            return status
        }
    }

    private final class ScriptedRunner: TerminalScriptRunning {
        private let result: String?
        private(set) var calls = 0

        init(result: String?) { self.result = result }

        func run(_ source: String) -> String? {
            calls += 1
            return result
        }
    }
}
#endif
