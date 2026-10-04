import AppKit
import Testing
@testable import AgenticToolkitLaunchUI

@MainActor
private final class Order {
    var entries: [String] = []
}

@MainActor @Suite struct RunAlertFromRunLoopTests {
    @Test func resumesWithTheInjectedResponse() async {
        let response = await runAlertFromRunLoop(NSAlert()) { _ in .alertSecondButtonReturn }
        #expect(response == .alertSecondButtonReturn)
    }

    @Test func defersToTheRunLoop() async {
        let order = Order()
        // Run-loop blocks fire FIFO, and the probe cannot fire until this
        // function suspends. An inline implementation would record "run" first.
        RunLoop.main.perform(inModes: [.common]) {
            MainActor.assumeIsolated { order.entries.append("probe") }
        }
        let response = await runAlertFromRunLoop(NSAlert()) { _ in
            order.entries.append("run")
            return .alertFirstButtonReturn
        }
        #expect(order.entries == ["probe", "run"])
        #expect(response == .alertFirstButtonReturn)
    }
}
