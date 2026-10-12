import Foundation

/// One LLM call the daemon made — a summarizer or oversight completion, logged at
/// the shared `DaemonAIChat` chokepoint so the AI Log window (XPC) and
/// `GET /ai/interactions` (HTTP) can show exactly what was asked and answered.
///
/// List reads truncate the three long text fields SQL-side (`truncated` = true when
/// anything was cut); a by-id read returns the full text with `truncated` = false.
public struct AIInteractionDTO: Codable, Sendable, Equatable {
    public let id: Int
    /// Which feature asked: `summarize` | `oversight`.
    public let feature: String
    /// The session the call was about ("" when not session-scoped).
    public let sessionId: String
    /// Which transport served it: `plugin` (a selected provider config) | `cli`
    /// (the zero-config `claude -p` fallback).
    public let providerKind: String
    /// The selected configuration's display name ("" on the CLI path).
    public let configName: String
    /// The model label the call resolved to (config model, plugin id, or CLI model).
    public let model: String
    public let systemPrompt: String
    public let userPrompt: String
    /// The reply text ("" when the call failed).
    public let response: String
    public let durationMs: Int
    /// `ok` | `error` | `guard_blocked` | `guard_deferred`.
    public let outcome: String
    /// The failure description ("" on success).
    public let error: String
    /// True when a list read cut any of the text fields; fetch by id for full text.
    public let truncated: Bool
    public let createdAt: String

    /// True when the call did not complete — any non-`ok` outcome (`error`,
    /// `guard_blocked`, `guard_deferred`), in which case `error` holds the reason
    /// and `response` is empty. The one place the outcome vocabulary is folded
    /// into a success/failure split, shared by list and detail rendering.
    public var isFailure: Bool { outcome != "ok" }

    public init(
        id: Int,
        feature: String,
        sessionId: String,
        providerKind: String,
        configName: String,
        model: String,
        systemPrompt: String,
        userPrompt: String,
        response: String,
        durationMs: Int,
        outcome: String,
        error: String,
        truncated: Bool,
        createdAt: String
    ) {
        self.id = id
        self.feature = feature
        self.sessionId = sessionId
        self.providerKind = providerKind
        self.configName = configName
        self.model = model
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        self.response = response
        self.durationMs = durationMs
        self.outcome = outcome
        self.error = error
        self.truncated = truncated
        self.createdAt = createdAt
    }
}
