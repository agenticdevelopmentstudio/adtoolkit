import Foundation

/// Everything the moved windows ask stenographerd for, as one injectable seam.
///
/// Reads answer nil when the daemon cannot be reached (callers keep what is on
/// screen); writes answer `false`/nil the same way. The production
/// implementation is ``StenographerHTTPClient``; tests hand the windows a stub.
public protocol StenographerDaemonService: Sendable {
    func health() async -> HealthDTO?

    func sessions(status: String?, project: String?, sinceHours: Int, includeCounts: Bool) async -> [SessionDTO]?
    /// Outer nil = daemon unreachable; inner nil = no such session.
    func session(id: String, includeCounts: Bool) async -> SessionDTO??
    /// Throws ``SummarizeDaemonFailure`` with the daemon's reason, or any other
    /// error for a transport failure.
    func summarize(sessionId: String) async throws

    func conversations(
        limit: Int, includeWorkOutput: Bool, before: String?, sessionId: String?
    ) async -> [ConversationEntryDTO]?

    func oversightFindings(status: String?) async -> [OversightFindingDTO]?
    func oversightActionTarget(findingId: Int) async -> OversightActionTargetDTO?
    func actOnOversightFinding(findingId: Int) async -> OversightActResultDTO?
    func oversightScripts() async -> [OversightScript]?
    func saveOversightScript(_ script: OversightScript) async -> OversightScript?
    func deleteOversightScript(id: String) async -> Bool
    func resetOversightScript(id: String) async -> OversightScript?

    func aiInteractions(limit: Int) async -> [AIInteractionDTO]?
    func aiInteraction(id: Int) async -> AIInteractionDTO?

    /// The daemon's saved LLM provider configurations (what Stenographer's LLM
    /// Providers pane pushed), for the pickers in the moved panes.
    func aiProviderConfigs() async -> [DaemonProviderConfig]?
    func summaryPreferences() async -> SummaryPreferenceResponse?
    func oversightPreferences() async -> OversightPreferenceResponse?
    func setSummaryPreferences(_ request: SummaryPreferenceRequest) async -> Bool
    func setOversightPreferences(_ request: OversightPreferenceRequest) async -> Bool

    /// Registers a handler that fires when the daemon is seen to have restarted,
    /// so a preference push can re-send its snapshot.
    func onReconnect(_ handler: @escaping @Sendable () -> Void)
}

public extension StenographerDaemonService {
    func sessions(status: String? = nil, sinceHours: Int = 0, includeCounts: Bool = true) async -> [SessionDTO]? {
        await sessions(status: status, project: nil, sinceHours: sinceHours, includeCounts: includeCounts)
    }
    func session(id: String) async -> SessionDTO?? { await session(id: id, includeCounts: true) }
    func oversightFindings() async -> [OversightFindingDTO]? { await oversightFindings(status: nil) }
    func aiInteractions() async -> [AIInteractionDTO]? { await aiInteractions(limit: 200) }
    func conversations(
        limit: Int = 200, includeWorkOutput: Bool = false, sessionId: String? = nil
    ) async -> [ConversationEntryDTO]? {
        await conversations(limit: limit, includeWorkOutput: includeWorkOutput, before: nil, sessionId: sessionId)
    }
}

/// The daemon declined to summarize and said why (a memory guard, a provider
/// error). Distinct from a transport failure so the list can show the reason.
public struct SummarizeDaemonFailure: LocalizedError, Equatable, Sendable {
    public let reason: String
    public init(reason: String) { self.reason = reason }
    public var errorDescription: String? { reason }
}

/// One row of `GET /preferences/ai/configs`: a provider configuration as the
/// daemon stores it (no secrets, no model — those are the daemon's own).
public struct DaemonProviderConfig: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let pluginIdentifier: String
    public let templateId: String

    public init(id: UUID, name: String, pluginIdentifier: String, templateId: String) {
        self.id = id
        self.name = name
        self.pluginIdentifier = pluginIdentifier
        self.templateId = templateId
    }
}
