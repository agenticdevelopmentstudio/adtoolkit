import XCTest
import OSLog
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class StenographerPrefsPushTests: XCTestCase {

    override func tearDown() async throws {
        StenographerOversightPrefsPush.stopObserving()
        StenographerSummaryPrefsPush.stopObserving()
        UserSettings.stenographerAISummariesEnabled.remove()
        UserSettings.stenographerAISummariesProviderConfigId.remove()
        UserSettings.resetAISummaryTuning()
        UserSettings.stenographerAIOversightEnabled.remove()
        UserSettings.stenographerAIOversightProviderConfigId.remove()
        UserSettings.stenographerAIOversightLLMEnabled.remove()
        UserSettings.stenographerAISummariesSeededFromDaemon.remove()
        UserSettings.stenographerAIOversightSeededFromDaemon.remove()
    }

    private static let configId = UUID(uuidString: "0A1B2C3D-0000-4000-8000-000000000001")!

    private func nonDefaultSummaries() -> SummaryPreferenceResponse {
        SummaryPreferenceResponse(
            enabled: false, selectedConfigId: "claude-cli", prompt: "Custom prompt", maxWords: 7,
            activityLines: 11, detailChars: 222, intervalMinutes: 9, maxPerRun: 3, timeoutSeconds: 44)
    }

    // MARK: - Seeding from the daemon

    func testSummaryFreshStoreSeedsFromDaemonBeforeFirstPush() async {
        let daemon = StubDaemonService()
        daemon.summaryReply = nonDefaultSummaries()
        StenographerSummaryPrefsPush.startObserving(service: daemon)
        await StenographerSummaryPrefsPush.awaitPendingPush()
        XCTAssertEqual(UserSettings.stenographerAISummariesEnabled.value, false)
        XCTAssertEqual(UserSettings.stenographerAISummariesProviderConfigId.value, "claude-cli")
        XCTAssertEqual(UserSettings.stenographerAISummaryPrompt.value, "Custom prompt")
        XCTAssertEqual(UserSettings.stenographerAISummaryMaxWords.value, 7)
        XCTAssertEqual(UserSettings.stenographerAISummaryActivityLines.value, 11)
        XCTAssertEqual(UserSettings.stenographerAISummaryDetailChars.value, 222)
        XCTAssertEqual(UserSettings.stenographerAISummaryIntervalMinutes.value, 9)
        XCTAssertEqual(UserSettings.stenographerAISummaryMaxPerRun.value, 3)
        XCTAssertEqual(UserSettings.stenographerAISummaryTimeoutSeconds.value, 44)
        XCTAssertTrue(UserSettings.stenographerAISummariesSeededFromDaemon.value)
        await settleSummary()
        XCTAssertEqual(daemon.summaryRequests.count, 1, "seeding must not itself trigger a push")
        let body = daemon.summaryRequests.first
        XCTAssertEqual(body?.enabled, false)
        XCTAssertEqual(body?.selectedConfigId, "claude-cli")
        XCTAssertEqual(body?.prompt, "Custom prompt")
        XCTAssertEqual(body?.maxWords, 7)
        XCTAssertEqual(body?.timeoutSeconds, 44)
    }

    func testSummaryDefaultPromptFromDaemonStaysUnstored() async {
        let daemon = StubDaemonService()
        daemon.summaryReply = SummaryPreferenceResponse(
            enabled: true, selectedConfigId: "", prompt: SummaryDefaults.prompt, maxWords: 5,
            activityLines: 11, detailChars: 222, intervalMinutes: 9, maxPerRun: 3, timeoutSeconds: 44)
        StenographerSummaryPrefsPush.startObserving(service: daemon)
        await StenographerSummaryPrefsPush.awaitPendingPush()
        XCTAssertEqual(UserSettings.stenographerAISummaryPrompt.value, SummaryDefaults.prompt)
        XCTAssertEqual(daemon.summaryRequests.first?.prompt, "")
        XCTAssertEqual(daemon.summaryRequests.first?.maxWords, 5)
    }

    func testOversightFreshStoreSeedsFromDaemonBeforeFirstPush() async {
        let daemon = StubDaemonService()
        daemon.oversightReply = OversightPreferenceResponse(
            enabled: true, contextThresholdPct: 70, llmEnabled: true,
            selectedConfigId: Self.configId.uuidString, model: "big-model")
        StenographerOversightPrefsPush.startObserving(service: daemon)
        await StenographerOversightPrefsPush.awaitPendingPush()
        XCTAssertEqual(UserSettings.stenographerAIOversightEnabled.value, true)
        XCTAssertEqual(UserSettings.stenographerAIOversightLLMEnabled.value, true)
        XCTAssertEqual(UserSettings.stenographerAIOversightProviderConfigId.value, Self.configId.uuidString)
        let hidden = UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("stenographer_oversight_model") }
        XCTAssertTrue(hidden.isEmpty, "the daemon's model is not copied into a hidden local setting")
        XCTAssertTrue(UserSettings.stenographerAIOversightSeededFromDaemon.value)
        await settle()
        XCTAssertEqual(daemon.oversightRequests.count, 1, "seeding must not itself trigger a push")
        let body = daemon.oversightRequests.first
        XCTAssertEqual(body?.enabled, true)
        XCTAssertEqual(body?.llmEnabled, true)
        XCTAssertEqual(body?.selectedConfigId, Self.configId.uuidString)
        XCTAssertEqual(body?.model, "", "the push never sends a model, whatever the daemon stored")
    }

    func testSeededMarkerSkipsTheDaemonRead() async {
        UserSettings.stenographerAISummariesSeededFromDaemon.value = true
        UserSettings.stenographerAIOversightSeededFromDaemon.value = true
        let daemon = StubDaemonService()
        daemon.summaryReply = nonDefaultSummaries()
        StenographerSummaryPrefsPush.startObserving(service: daemon)
        StenographerOversightPrefsPush.startObserving(service: daemon)
        await StenographerSummaryPrefsPush.awaitPendingPush()
        await StenographerOversightPrefsPush.awaitPendingPush()
        XCTAssertEqual(daemon.summaryGets, 0)
        XCTAssertEqual(daemon.oversightGets, 0)
        XCTAssertEqual(daemon.summaryRequests.count, 1)
        XCTAssertEqual(daemon.summaryRequests.first?.maxWords, SummaryDefaults.maxWords)
        XCTAssertEqual(daemon.oversightRequests.count, 1)
    }

    func testDaemonDownPushesNothingUntilReconnectSeeds() async {
        let daemon = StubDaemonService()
        daemon.summaryReply = nil
        daemon.oversightReply = nil
        StenographerSummaryPrefsPush.startObserving(service: daemon)
        StenographerOversightPrefsPush.startObserving(service: daemon)
        await StenographerSummaryPrefsPush.awaitPendingPush()
        await StenographerOversightPrefsPush.awaitPendingPush()
        XCTAssertTrue(daemon.summaryRequests.isEmpty)
        XCTAssertTrue(daemon.oversightRequests.isEmpty)
        XCTAssertFalse(UserSettings.stenographerAISummariesSeededFromDaemon.value)
        // Observers are not installed: a change pushes nothing.
        UserSettings.stenographerAISummariesEnabled.value = false
        UserSettings.stenographerAIOversightEnabled.value = true
        await settleSummary()
        await settle()
        XCTAssertTrue(daemon.summaryRequests.isEmpty)
        XCTAssertTrue(daemon.oversightRequests.isEmpty)

        daemon.summaryReply = nonDefaultSummaries()
        daemon.oversightReply = OversightPreferenceResponse(
            enabled: true, contextThresholdPct: 80, llmEnabled: true, selectedConfigId: "claude-cli", model: "")
        daemon.fireReconnect()
        await settleSummary()
        await settle()
        XCTAssertEqual(daemon.summaryRequests.count, 1)
        XCTAssertEqual(daemon.summaryRequests.first?.maxWords, 7)
        XCTAssertEqual(daemon.oversightRequests.count, 1)
        XCTAssertEqual(daemon.oversightRequests.first?.selectedConfigId, "claude-cli")
        XCTAssertTrue(UserSettings.stenographerAISummariesSeededFromDaemon.value)
        XCTAssertTrue(UserSettings.stenographerAIOversightSeededFromDaemon.value)
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

    func testSummaryUnmodifiedPromptTravelsBlank() async {
        let daemon = StubDaemonService()
        StenographerSummaryPrefsPush.startObserving(service: daemon)
        await StenographerSummaryPrefsPush.awaitPendingPush()
        XCTAssertEqual(daemon.summaryRequests.count, 1)
        XCTAssertEqual(daemon.summaryRequests.first?.prompt, "")
        XCTAssertEqual(daemon.summaryRequests.first?.maxWords, SummaryDefaults.maxWords)
    }

    func testSummaryChangeAndReconnectPush() async {
        let daemon = StubDaemonService()
        StenographerSummaryPrefsPush.startObserving(service: daemon)
        await StenographerSummaryPrefsPush.awaitPendingPush()
        UserSettings.stenographerAISummariesEnabled.value = true
        UserSettings.stenographerAISummariesProviderConfigId.value = "claude-cli"
        await settleSummary()
        XCTAssertEqual(daemon.summaryRequests.last?.enabled, true)
        XCTAssertEqual(daemon.summaryRequests.last?.selectedConfigId, "claude-cli")
        let before = daemon.summaryRequests.count
        daemon.fireReconnect()
        await settleSummary()
        XCTAssertEqual(daemon.summaryRequests.count, before + 1)
    }

    private func settleSummary() async {
        try? await Task.sleep(for: .milliseconds(50))
        await StenographerSummaryPrefsPush.awaitPendingPush()
    }

    /// Lets a setting change (delivered on the next main-queue turn) or a
    /// reconnect (hopped onto the main actor) start its push, then awaits it.
    private func settle() async {
        try? await Task.sleep(for: .milliseconds(50))
        await StenographerOversightPrefsPush.awaitPendingPush()
    }
}

/// The seeding engine in `SettingsSnapshotPush` itself, with a short retry delay.
@MainActor
final class SettingsSnapshotPushSeedTests: XCTestCase {

    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        var count: Int { lock.withLock { value } }
        func bump() { lock.withLock { value += 1 } }
    }

    private let setting = UserSetting<Int>("settings_snapshot_push_seed_tests", default: 0)

    override func tearDown() async throws {
        setting.remove()
    }

    /// A push whose seed succeeds once `reachable` says so; the reconnect handler is never fired.
    private func makePush(
        gets: Counter, posts: Counter, reachable: @escaping @Sendable () -> Bool
    ) -> SettingsSnapshotPush {
        SettingsSnapshotPush(
            label: "Seed test",
            logger: Logger(subsystem: "tests", category: "SettingsSnapshotPushSeedTests"),
            backoffs: [0],
            reconnectDelay: { _ in 100_000_000 },
            snapshot: { Data("{}".utf8) },
            send: { _ in
                posts.bump()
                return true
            },
            registerReconnect: { _ in },
            seed: {
                gets.bump()
                return reachable()
            }
        )
    }

    func testFailedSeedRetriesOnItsOwnWithoutAReconnect() async {
        let (gets, posts, comeUp) = (Counter(), Counter(), Counter())
        let push = makePush(gets: gets, posts: posts) { comeUp.count > 0 }
        push.start(observing: [setting])
        await push.awaitPendingPush()
        XCTAssertEqual(posts.count, 0)
        comeUp.bump()  // the receiver comes up
        await push.awaitPendingPush()
        await push.awaitPendingPush()
        XCTAssertGreaterThanOrEqual(gets.count, 2)
        XCTAssertEqual(posts.count, 1)
        push.stop()
    }

    func testPushWhileSeedPendingSendsNothing() async {
        let (gets, posts) = (Counter(), Counter())
        let push = makePush(gets: gets, posts: posts) { false }
        push.start(observing: [setting])
        push.push()
        push.push()
        await push.awaitPendingPush()
        XCTAssertEqual(posts.count, 0)
        push.stop()
    }

    func testStopCancelsThePendingReseed() async {
        let (gets, posts) = (Counter(), Counter())
        let push = makePush(gets: gets, posts: posts) { false }
        push.start(observing: [setting])
        await push.awaitPendingPush()
        push.stop()
        let before = gets.count
        try? await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(gets.count, before)
        XCTAssertEqual(posts.count, 0)
    }
}
