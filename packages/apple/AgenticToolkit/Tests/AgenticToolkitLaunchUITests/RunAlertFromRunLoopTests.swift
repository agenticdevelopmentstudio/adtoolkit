import AppKit
import Testing
@testable import AgenticToolkitLaunchUI

@MainActor
private final class Flag {
    var ran = false
}

@MainActor @Suite struct RunAlertFromRunLoopTests {
    @Test func resumesWithTheInjectedResponse() async {
        let response = await runAlertFromRunLoop(NSAlert()) { _ in .alertSecondButtonReturn }
        #expect(response == .alertSecondButtonReturn)
    }

    @Test func doesNotRunSynchronously() async {
        let flag = Flag()
        // Main-actor code never yields between scheduling and this check, so the
        // run-loop block cannot have fired: the closure must still be unrun.
        let task = Task { @MainActor in
            await runAlertFromRunLoop(NSAlert()) { _ in
                flag.ran = true
                return .alertFirstButtonReturn
            }
        }
        #expect(!flag.ran)
        let response = await task.value
        #expect(flag.ran)
        #expect(response == .alertFirstButtonReturn)
    }
}
