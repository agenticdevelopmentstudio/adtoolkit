import AgenticToolkitCore
import XCTest
@testable import AgenticToolkitMacOS

/// Drives a real shell through a `TerminalChatSession`, the way `adterm` and
/// a persona's terminal tools do, and checks what each caller is handed back.
///
/// Each test starts `/bin/sh` rather than the user's shell, so the prompt and
/// the timing depend as little as possible on whoever runs the suite.
@MainActor
final class TerminalChatSessionTests: XCTestCase {

    private static let stillRunning = "[still running — wait for more output, or interrupt it]"

    func testOutputThatNeverPausesStillReachesTheRun() async throws {
        let (chat, terminal) = try await connectedShell()
        defer { withExtendedLifetime(terminal) {} }
        let reply = await chat.run("while true; do echo tick; sleep 0.1; done",
                                   settle: .milliseconds(1500), timeout: .seconds(3))
        _ = await chat.interruptAndWait()
        XCTAssertTrue(reply.contains("tick"), "a stream with no pause must still be reported: \(reply)")
        XCTAssertTrue(reply.hasSuffix(Self.stillRunning), reply)
    }

    func testASettleLongerThanTheTimeoutStillReportsAFinishedCommand() async throws {
        let (chat, terminal) = try await connectedShell()
        defer { withExtendedLifetime(terminal) {} }
        let reply = await chat.run("echo done", settle: .seconds(30), timeout: .seconds(4))
        XCTAssertTrue(reply.contains("done"), reply)
        XCTAssertFalse(reply.contains(Self.stillRunning),
                       "a command that finished at once is not still running: \(reply)")
    }

    func testInterruptWaitsAsLongAsItIsTold() async throws {
        let (chat, terminal) = try await connectedShell()
        defer { withExtendedLifetime(terminal) {} }
        // Ignores Control-C and keeps printing, so only the timeout ends the wait.
        _ = await chat.run(#"sh -c 'trap "" INT; while :; do echo tick; sleep 0.1; done'"#,
                           settle: .milliseconds(300), timeout: .seconds(1))
        let start = ContinuousClock.now
        let reply = await chat.interruptAndWait(settle: .milliseconds(500), timeout: .seconds(2))
        let waited = ContinuousClock.now - start
        terminal.sendInput("\u{1C}")  // Control-backslash: SIGQUIT, which it does not ignore
        XCTAssertTrue(reply.hasSuffix(Self.stillRunning), reply)
        XCTAssertLessThan(waited, .seconds(5), "the wait must end at the timeout given, not a fixed 10 s")
    }

    // MARK: - Helpers

    /// A chat connected to a freshly started shell, once its first prompt is up.
    private func connectedShell() async throws -> (TerminalChatSession, TerminalSession) {
        let terminal = TerminalSession(name: "test", workingDirectory: NSTemporaryDirectory(),
                                       shell: "/bin/sh")
        _ = terminal.terminalView
        let chat = TerminalChatSession(quietPeriod: .milliseconds(200))
        chat.connect(to: terminal)
        let deadline = ContinuousClock.now + .seconds(10)
        while chat.screen()?.isEmpty != false {
            guard ContinuousClock.now < deadline else { throw ShellNeverStarted() }
            try await Task.sleep(for: .milliseconds(100))
        }
        _ = await chat.waitForOutput(settle: .milliseconds(300), timeout: .seconds(2))
        return (chat, terminal)
    }

    private struct ShellNeverStarted: Error {}
}
