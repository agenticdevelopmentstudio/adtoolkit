import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class StenographerPrefsPushTests: XCTestCase {

    override func tearDown() async throws {
        StenographerOversightPrefsPush.stopObserving()
        UserSettings.stenographerAIOversightEnabled.remove()
        UserSettings.stenographerAIOversightProviderConfigId.remove()
    }

    func testOversightSnapshotCarriesSentinelWithEmptyModel() {
        let request = StenographerOversightPrefsPush.makeRequest(
            enabled: true, llmEnabled: false, selectedConfigId: "claude-cli", model: "")
        XCTAssertEqual(request.enabled, true)
        XCTAssertEqual(request.selectedConfigId, "claude-cli")
        XCTAssertEqual(request.model, "")
    }

    func testOversightStartPushesAndRepushesOnReconnect() async {
        let daemon = StubDaemonService()
        StenographerOversightPrefsPush.startObserving(service: daemon)
        await StenographerOversightPrefsPush.awaitPendingPush()
        XCTAssertEqual(daemon.oversightRequests.count, 1)
        daemon.fireReconnect()
        await settle()
        XCTAssertEqual(daemon.oversightRequests.count, 2)
    }

    func testOversightChangePushesNewValue() async {
        let daemon = StubDaemonService()
        StenographerOversightPrefsPush.startObserving(service: daemon)
        await StenographerOversightPrefsPush.awaitPendingPush()
        UserSettings.stenographerAIOversightEnabled.value = true
        await settle()
        XCTAssertEqual(daemon.oversightRequests.last?.enabled, true)
    }

    /// Lets a setting change (delivered on the next main-queue turn) or a
    /// reconnect (hopped onto the main actor) start its push, then awaits it.
    private func settle() async {
        try? await Task.sleep(for: .milliseconds(50))
        await StenographerOversightPrefsPush.awaitPendingPush()
    }
}
