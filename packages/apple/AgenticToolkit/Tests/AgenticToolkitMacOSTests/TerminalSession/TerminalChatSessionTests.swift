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

    func testOutputAfterARunGaveUpGoesToWaitNotToTheNextRun() async throws {
        let (chat, terminal) = try await connectedShell()
        defer { withExtendedLifetime(terminal) {} }
        _ = await chat.run("sleep 1; echo late-one", settle: .milliseconds(300), timeout: .milliseconds(600))
        try await Task.sleep(for: .seconds(2))
        let waited = await chat.waitForOutput(settle: .milliseconds(300), timeout: .seconds(2))
        XCTAssertTrue(waited.contains("late-one"), waited)

        _ = await chat.run("sleep 1; echo late-two", settle: .milliseconds(300), timeout: .milliseconds(600))
        try await Task.sleep(for: .seconds(2))
        let next = await chat.run("echo next", settle: .milliseconds(300), timeout: .seconds(3))
        XCTAssertTrue(next.contains("next"), next)
        XCTAssertFalse(next.contains("late-two"), "a new command's reply is its own output only: \(next)")
    }

    func testAShellThatExitsLetsGoAtOnce() async throws {
        let (chat, terminal) = try await connectedShell()
        defer { withExtendedLifetime(terminal) {} }
        let start = ContinuousClock.now
        let reply = await chat.run("exit", settle: .seconds(2), timeout: .seconds(30))
        XCTAssertLessThan(ContinuousClock.now - start, .seconds(10), "an exited shell must not wait out the timeout")
        XCTAssertTrue(reply.hasSuffix(TerminalChatSession.exited), reply)
        XCTAssertNil(chat.terminal)
        XCTAssertFalse(terminal.isRunning)
    }

    /// Claude Code reads a long line arriving in one write as a paste and keeps
    /// a Return inside it as pasted text, so the message never sends. Return
    /// has to reach the program as a read of its own.
    func testReturnArrivesAsAWriteOfItsOwn() async throws {
        let (chat, terminal) = try await connectedShell()
        defer { withExtendedLifetime(terminal) {} }
        // Reads two raw chunks and prints them, putting the tty back first.
        let reader = #"/usr/bin/python3 -c 'import os,termios,tty; o=termios.tcgetattr(0); tty.setraw(0); "#
            + #"a=os.read(0,99); b=os.read(0,99); termios.tcsetattr(0,termios.TCSADRAIN,o); print("CHUNKS",a,b)'"#
        _ = await chat.run(reader, settle: .seconds(1), timeout: .seconds(3))
        let reply = await chat.run("hello", settle: .milliseconds(800), timeout: .seconds(5))
        XCTAssertTrue(reply.contains(#"CHUNKS b'hello' b'\r'"#), reply)
    }

    // MARK: - Helpers

    /// A chat connected to a freshly started shell, once its first prompt is up.
    private func connectedShell() async throws -> (TerminalChatSession, TerminalSession) {
        // temp-leak-check: ok path only, nothing written
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
