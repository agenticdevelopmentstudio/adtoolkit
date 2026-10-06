import Testing
import Foundation
@testable import AgenticToolkitCore

@Suite("ProcessCommandRunner")
struct ProcessCommandRunnerTests {
    @Test("echo returns its output and status 0")
    func echoReturnsOutputAndZeroStatus() async {
        let result = await ProcessCommandRunner().run(["/bin/echo", "hi"])
        #expect(result.status == 0)
        #expect(result.output == "hi\n")
    }

    @Test("capture keeps stdout and stderr apart")
    func captureKeepsStdoutAndStderrApart() async {
        let result = await ProcessCommandRunner().capture(
            ["/bin/sh", "-c", "echo out; echo err 1>&2; exit 3"], environment: nil)
        #expect(result.status == 3)
        #expect(result.stdout == "out\n")
        #expect(result.stderr == "err\n")
    }

    @Test("capture replaces the environment")
    func captureReplacesTheEnvironment() async {
        let result = await ProcessCommandRunner().capture(["/usr/bin/env"], environment: ["ONLY_THIS": "1"])
        #expect(result.status == 0)
        #expect(result.stdout == "ONLY_THIS=1\n")
    }

    @Test("a name without a slash resolves through env")
    func bareNameResolvesThroughEnv() async {
        let result = await ProcessCommandRunner().run(["echo", "bare"])
        #expect(result.status == 0)
        #expect(result.output == "bare\n")
    }

    @Test("false returns a non-zero status")
    func falseReturnsNonZeroStatus() async {
        let result = await ProcessCommandRunner().run(["/usr/bin/false"])
        #expect(result.status != 0)
    }

    /// 200,000 bytes is well past the 64 KB pipe buffer: reading only after
    /// the child exits would deadlock.
    @Test("large output is returned in full")
    func largeOutputIsReturnedInFull() async {
        let result = await ProcessCommandRunner().run(["/usr/bin/head", "-c", "200000", "/dev/zero"])
        #expect(result.status == 0)
        #expect(result.output.utf8.count == 200_000)
    }

    @Test("a missing executable fails without crashing")
    func missingExecutableFailsWithoutCrashing() async {
        let result = await ProcessCommandRunner().run(["/nonexistent/definitely-not-here"])
        #expect(result.status != 0)
    }

    /// The backstop fires long before `sleep` would finish; the assertion is
    /// on the reported failure, never on elapsed time.
    @Test("a timed-out run reports failure")
    func timedOutRunReportsFailure() async {
        let result = await ProcessCommandRunner(backstop: 0.2).run(["/bin/sleep", "30"])
        #expect(result.status == -1)
        #expect(result.output.contains("timed out"))
    }

    /// A double that implements only `run` answers `capture` with the merged
    /// output as stdout.
    private struct RunOnly: CommandRunning {
        func run(_ argv: [String]) async -> (status: Int32, output: String) { (7, argv.joined(separator: " ")) }
    }

    @Test("the default capture is built on run")
    func defaultCaptureIsBuiltOnRun() async {
        let result = await RunOnly().capture(["a", "b"])
        #expect(result.status == 7)
        #expect(result.stdout == "a b")
        #expect(result.stderr == "")
    }
}
