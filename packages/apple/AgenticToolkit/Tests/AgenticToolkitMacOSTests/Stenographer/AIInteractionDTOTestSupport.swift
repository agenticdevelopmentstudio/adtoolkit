import AgenticToolkitCore

/// Shared `AIInteractionDTO` fixture builder for the AI Log suites — every field
/// defaulted so each test names only what it asserts on.
func makeAIInteractionDTO(
    id: Int = 1,
    feature: String = "summarize",
    sessionId: String = "abcdef1234567890",
    providerKind: String = "cli",
    configName: String = "",
    model: String = "haiku",
    systemPrompt: String = "sys",
    userPrompt: String = "user",
    response: String = "reply",
    durationMs: Int = 42,
    outcome: String = "ok",
    error: String = "",
    truncated: Bool = false,
    createdAt: String = "2026-07-10 12:00:00"
) -> AIInteractionDTO {
    AIInteractionDTO(
        id: id, feature: feature, sessionId: sessionId, providerKind: providerKind,
        configName: configName, model: model, systemPrompt: systemPrompt,
        userPrompt: userPrompt, response: response, durationMs: durationMs,
        outcome: outcome, error: error, truncated: truncated, createdAt: createdAt
    )
}
