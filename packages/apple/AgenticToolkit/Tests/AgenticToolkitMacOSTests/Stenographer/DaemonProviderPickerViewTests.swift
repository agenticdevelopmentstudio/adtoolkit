import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class DaemonProviderPickerViewTests: XCTestCase {

    func testEmptyRegistryShowsLeadingChoicesOnly() {
        let choices = DaemonProviderPickerView.menuChoices(
            leading: [.init(label: "Default (Claude CLI)", value: "")], configs: [])
        XCTAssertEqual(choices.map(\.label), ["Default (Claude CLI)"])
        XCTAssertEqual(choices.map(\.value), [""])
    }

    func testConfigsFollowLeadingChoicesByName() {
        let ollama = DaemonProviderConfig(id: UUID(), name: "Ollama", pluginIdentifier: "p", templateId: "t")
        let anthropic = DaemonProviderConfig(id: UUID(), name: "Anthropic", pluginIdentifier: "p", templateId: "t")
        let choices = DaemonProviderPickerView.menuChoices(
            leading: [
                .init(label: "Same as AI Summaries", value: ""),
                .init(label: "Default (Claude CLI)", value: "claude-cli")
            ],
            configs: [ollama, anthropic])
        XCTAssertEqual(choices.map(\.label), ["Same as AI Summaries", "Default (Claude CLI)", "Anthropic", "Ollama"])
        XCTAssertEqual(choices[2].value, anthropic.id.uuidString)
    }

    @MainActor
    func testSelectionWritesSetting() async {
        let setting = UserSetting<String>("test.daemonPicker.\(UUID().uuidString)", default: "")
        defer { setting.remove() }
        let config = DaemonProviderConfig(id: UUID(), name: "Ollama", pluginIdentifier: "p", templateId: "t")
        let picker = DaemonProviderPickerView(
            service: StubDaemonService(configs: [config]),
            selectedSetting: setting,
            leadingChoices: [.init(label: "Default (Claude CLI)", value: "")])
        await picker.reload()
        XCTAssertEqual(picker.choices.count, 2)
        picker.selectChoice(at: 1)
        XCTAssertEqual(setting.value, config.id.uuidString)
    }
}

/// A daemon that answers from fixtures. Shared by the Stenographer feature tests.
/// Non-final so a test can subclass it to make `summarize` throw or a reply differ.
class StubDaemonService: StenographerDaemonService, @unchecked Sendable {
    var configs: [DaemonProviderConfig]
    var sessionsReply: [SessionDTO]? = []
    var findingsReply: [OversightFindingDTO]? = []
    var scriptsReply: [OversightScript]? = []
    var interactionsReply: [AIInteractionDTO]? = []
    var conversationsReply: [ConversationEntryDTO]? = []
    private(set) var summaryRequests: [SummaryPreferenceRequest] = []
    private(set) var oversightRequests: [OversightPreferenceRequest] = []
    private var reconnectHandlers: [@Sendable () -> Void] = []

    init(configs: [DaemonProviderConfig] = []) { self.configs = configs }

    func health() async -> HealthDTO? { HealthDTO(status: "ok", uptime: 1, version: "test") }
    func sessions(
        status: String?, project: String?, sinceHours: Int, includeCounts: Bool
    ) async -> [SessionDTO]? { sessionsReply }
    func session(id: String, includeCounts: Bool) async -> SessionDTO?? {
        .some(sessionsReply?.first { $0.sessionId == id })
    }
    func summarize(sessionId: String) async throws {}
    func conversations(
        limit: Int, includeWorkOutput: Bool, before: String?, sessionId: String?
    ) async -> [ConversationEntryDTO]? { conversationsReply }
    func oversightFindings(status: String?) async -> [OversightFindingDTO]? { findingsReply }
    func oversightActionTarget(findingId: Int) async -> OversightActionTargetDTO? { nil }
    func actOnOversightFinding(findingId: Int) async -> OversightActResultDTO? { nil }
    func oversightScripts() async -> [OversightScript]? { scriptsReply }
    func saveOversightScript(_ script: OversightScript) async -> OversightScript? { script }
    func deleteOversightScript(id: String) async -> Bool { true }
    func resetOversightScript(id: String) async -> OversightScript? { nil }
    func aiInteractions(limit: Int) async -> [AIInteractionDTO]? { interactionsReply }
    func aiInteraction(id: Int) async -> AIInteractionDTO? { interactionsReply?.first { $0.id == id } }
    func aiProviderConfigs() async -> [DaemonProviderConfig]? { configs }
    func summaryPreferences() async -> SummaryPreferenceResponse? { nil }
    func oversightPreferences() async -> OversightPreferenceResponse? { nil }
    func setSummaryPreferences(_ request: SummaryPreferenceRequest) async -> Bool {
        summaryRequests.append(request)
        return true
    }
    func setOversightPreferences(_ request: OversightPreferenceRequest) async -> Bool {
        oversightRequests.append(request)
        return true
    }
    func onReconnect(_ handler: @escaping @Sendable () -> Void) { reconnectHandlers.append(handler) }
    func fireReconnect() { reconnectHandlers.forEach { $0() } }
}
