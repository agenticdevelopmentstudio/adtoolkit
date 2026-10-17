import XCTest
@testable import AgenticToolkitCore

/// Unit tests for `ProcessEnv`, the KERN_PROCARGS2-based recovery of
/// `CLAUDE_CODE_OAUTH_TOKEN` from a parent `claude` process (Claude Code
/// scrubs the token from the env it hands hook/status-line commands).
final class ProcessEnvTests: XCTestCase {

    func testEnvironmentForCurrentProcessContainsExecTimeVars() throws {
        // KERN_PROCARGS2 is the exec-time env snapshot, not live setenv changes,
        // so assert against a var that's essentially always set at process start
        // rather than something we setenv() ourselves.
        let env = try XCTUnwrap(ProcessEnv.environment(forPid: getpid()),
                                 "same-user KERN_PROCARGS2 should be readable, as `ps eww` proves")
        XCTAssertTrue(env["HOME"] != nil || env["PATH"] != nil,
                      "expected at least one of HOME/PATH in the exec-time env snapshot")
    }

    func testParentPidOfCurrentProcessIsValid() throws {
        let ppid = try XCTUnwrap(ProcessEnv.parentPid(of: getpid()))
        XCTAssertGreaterThan(ppid, 1)
    }

    func testOauthTokenWalkingUpDoesNotCrash() {
        // May be nil in the test environment (no CLAUDE_CODE_OAUTH_TOKEN
        // anywhere in the parent chain) — just assert it doesn't trap.
        let token = ProcessEnv.oauthTokenWalkingUp(from: getpid())
        _ = token
    }

    // MARK: - claudePid (the hook's `claude`, found without $PPID)

    /// A fake process table: pid → (parent, names).
    private func table(_ rows: [Int32: (Int32, Set<String>)])
        -> (parentOf: (Int32) -> Int32?, namesOf: (Int32) -> Set<String>) {
        ({ rows[$0]?.0 }, { rows[$0]?.1 ?? [] })
    }

    func testClaudePidSkipsTheShellThatRanTheHookLine() {
        // claude(500) → /bin/sh -c (600) → steno: steno's getppid() is 600.
        let procs = table([600: (500, ["sh"]), 500: (1, ["claude", "2.1.286"])])
        XCTAssertEqual(ProcessEnv.claudePid(aboveHookParent: 600,
                                            parentOf: procs.parentOf, namesOf: procs.namesOf), 500)
    }

    func testClaudePidAcceptsADirectClaudeParentAndNode() {
        let native = table([500: (1, ["claude"])])
        XCTAssertEqual(ProcessEnv.claudePid(aboveHookParent: 500,
                                            parentOf: native.parentOf, namesOf: native.namesOf), 500)
        let npm = table([600: (500, ["zsh"]), 500: (1, ["node"])])
        XCTAssertEqual(ProcessEnv.claudePid(aboveHookParent: 600,
                                            parentOf: npm.parentOf, namesOf: npm.namesOf), 500)
    }

    func testClaudePidIsNilWhenTheChainIsNotClaude() {
        // `steno hook` run by hand from a terminal: the shell's parent is login.
        let byHand = table([600: (400, ["zsh"]), 400: (1, ["login"])])
        XCTAssertNil(ProcessEnv.claudePid(aboveHookParent: 600,
                                          parentOf: byHand.parentOf, namesOf: byHand.namesOf))
        let unknown = table([:])
        XCTAssertNil(ProcessEnv.claudePid(aboveHookParent: 600,
                                          parentOf: unknown.parentOf, namesOf: unknown.namesOf))
    }

    func testProcessNamesOfThisProcessIncludeItsExecutable() {
        let names = ProcessEnv.processNames(of: getpid())
        let exe = (CommandLine.arguments[0] as NSString).lastPathComponent
        XCTAssertTrue(names.contains(exe), "\(names) should hold argv[0]'s basename \(exe)")
    }
}
