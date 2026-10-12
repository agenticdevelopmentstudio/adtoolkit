@testable import AgenticToolkitMacOS
import Foundation
import XCTest

/// `ClaudeAuthCLI` spawns a script-installed `claude` (`#!/usr/bin/env node`)
/// from an app with a bare PATH; the child must find the `node` beside it.
final class ClaudeAuthCLITests: XCTestCase {
    func testChildPathLeadsWithTheExecutablesOwnDirectory() throws {
        let env = ClaudeAuthCLI.childEnvironment(executable: "/Users/jane/.nvm/versions/node/v22.3.0/bin/claude")
        let path = try XCTUnwrap(env["PATH"])
        XCTAssertTrue(path.hasPrefix("/Users/jane/.nvm/versions/node/v22.3.0/bin:"))
    }

    func testChildEnvironmentStillStripsAccountPins() {
        let env = ClaudeAuthCLI.childEnvironment(executable: "/usr/local/bin/claude")
        XCTAssertEqual(env["AGENTIC_TOOLKIT_HEADLESS"], "1")
        XCTAssertNil(env["CLAUDE_CODE_OAUTH_TOKEN"])
        XCTAssertNil(env["ANTHROPIC_API_KEY"])
    }

    // MARK: - Coming back

    /// `Process.waitUntilExit()` can miss the wake-up for a child that exits
    /// within a few milliseconds and then park its thread forever — on macOS
    /// 26.6 about one call in five against `/usr/bin/true`, and about one
    /// credential round in a thousand against `security`. The child is gone
    /// and reaped by then, so no timeout that watches the child ever fires.
    /// A `run` that never returns is what held a credential round open and
    /// froze "Switching to …" behind it: the run must come back for every
    /// child, however fast it exits. 240 runs make a one-in-five miss certain
    /// and a one-in-a-thousand one likely enough to be worth the few seconds.
    func testARunComesBackForEveryFastExitingChild() async {
        let stuckLanes = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            for _ in 0..<4 {
                group.addTask {
                    for _ in 0..<60 {
                        let returned = await Self.returns(within: 10) {
                            _ = try? await ClaudeAuthCLI.run(
                                executable: "/usr/bin/true", arguments: [], timeout: 5)
                        }
                        // One is enough: a stuck run is a parked thread for the
                        // rest of the process, and the next 59 would only wait.
                        if !returned { return 1 }
                    }
                    return 0
                }
            }
            return await group.reduce(0, +)
        }
        XCTAssertEqual(stuckLanes, 0, "\(stuckLanes) lane(s) had a run that never came back")
    }

    /// Whether `body` finishes within `seconds`. A body that does not is left
    /// where it is — the point is that it never comes back, so nothing can
    /// cancel it — and only its flag is consulted.
    private static func returns(within seconds: Double, _ body: @escaping @Sendable () async -> Void) async -> Bool {
        let finished = Flag()
        Task.detached {
            await body()
            finished.raise()
        }
        let deadline = ContinuousClock.now + .seconds(seconds)
        while !finished.isRaised, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }
        return finished.isRaised
    }

    private final class Flag: @unchecked Sendable {
        private let lock = NSLock()
        private var raised = false
        func raise() { lock.withLock { raised = true } }
        var isRaised: Bool { lock.withLock { raised } }
    }
}
