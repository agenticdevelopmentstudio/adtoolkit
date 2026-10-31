import Foundation
import AgenticToolkitCore
import os

/// The `partner_*` tools the coding partner's Claude Code calls over MCP.
///
/// Only the partner may call them: every call is logged, then refused unless
/// its caller is the pane id the partner is running under. Any other terminal
/// that can reach the MCP endpoint is refused.
public final class PartnerToolSource: ChatToolSource, @unchecked Sendable {

    public struct Project: Codable, Sendable {
        public var id: String
        public var name: String
        public var path: String
        public var remote: String?
        public var branch: String?

        public init(id: String, name: String, path: String, remote: String? = nil, branch: String? = nil) {
            self.id = id; self.name = name; self.path = path; self.remote = remote; self.branch = branch
        }
    }

    typealias Handler = (Data) async -> (String, Bool)

    let callerID: @Sendable () -> String?
    let store: PartnerStore
    let sessions: PartnerSessionRegistry
    let projects: @MainActor () -> [Project]
    let notifier: PartnerNotifier

    /// Tools added by later features (the review tools).
    var extraTools: [(ToolDefinition, Handler)] = []

    /// - Parameter reviews: Answers the review tools; `nil` leaves them out.
    @MainActor
    public init(callerID: @escaping @Sendable () -> String?, store: PartnerStore, sessions: PartnerSessionRegistry,
                projects: @escaping @MainActor () -> [Project], notifier: PartnerNotifier,
                reviews: ReviewService? = nil) {
        self.callerID = callerID
        self.store = store
        self.sessions = sessions
        self.projects = projects
        self.notifier = notifier
        if let reviews { extraTools += Self.reviewTools(reviews) }
    }

    public func toolDefinitions() async -> [ToolDefinition] {
        var definitions = Self.projectsDefinitions + Self.sessionDefinitions + Self.attentionDefinitions
        definitions += extraTools.map(\.0)
        return definitions
    }

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        let allowed = callerID().map { $0 == caller } ?? false
        let result: (content: String, isError: Bool)
        if !allowed {
            result = ("refused: only the partner may call \(name)", true)
        } else {
            result = await dispatch(name: name, argumentsJSON: argumentsJSON)
        }
        let arguments = String(data: argumentsJSON, encoding: .utf8) ?? ""
        do {
            try store.logToolCall(caller: caller, name: name, arguments: arguments, isError: result.isError)
        } catch {
            Self.logger.error("Logging partner tool call \(name) failed: \(error.localizedDescription)")
        }
        return result
    }

    private func dispatch(name: String, argumentsJSON: Data) async -> (content: String, isError: Bool) {
        if name == "partner_projects_list" { return await projectsList() }
        if name.hasPrefix("partner_session_") { return await sessionTool(name, argumentsJSON) }
        if name.hasPrefix("partner_attention_") || name == "partner_notify" {
            return await attentionTool(name, argumentsJSON)
        }
        if let extra = extraTools.first(where: { $0.0.name == name }) {
            let (content, isError) = await extra.1(argumentsJSON)
            return (content, isError)
        }
        return ("unknown tool \(name)", true)
    }

    // MARK: - Projects

    private static var projectsDefinitions: [ToolDefinition] {
        [ToolDefinition(name: "partner_projects_list",
                        description: "Lists the Projects registry: id, name, path, remote, current branch.",
                        parametersJSONSchema: ToolJSONSchema.object(properties: [:]))]
    }

    private func projectsList() async -> (content: String, isError: Bool) {
        let list = await MainActor.run { projects() }
        return Self.encode(list)
    }

    // MARK: - Shared helpers

    static func arguments(_ data: Data) -> [String: Any] {
        ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any]) ?? [:]
    }

    static func encode(_ value: some Encodable) -> (content: String, isError: Bool) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            return ("could not encode the result", true)
        }
        return (text, false)
    }

    static func failure(_ message: String) -> (content: String, isError: Bool) { (message, true) }
}

extension PartnerToolSource: Loggable {
    public static nonisolated let logger = makeLogger()
}
