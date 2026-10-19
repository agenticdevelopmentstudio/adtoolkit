#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import AIPluginKit
import Foundation

extension DaemonAIChat {
    /// `complete` with a daemon database's settings table as the provider-registry
    /// reader. Every completion is recorded in the `ai_interactions` log (feature,
    /// provider identity, full prompts, reply-or-error, duration); the error path
    /// records **and rethrows**, so callers' error handling is unchanged. The local-model
    /// memory guard runs inside `complete` — a refusal surfaces here as `AIGuardError`
    /// and is recorded with a `guard_blocked` / `guard_deferred` outcome (reason in the
    /// error column) so the AI Log shows why nothing ran.
    public static func complete(
        feature: AIFeature,
        sessionId: String? = nil,
        systemPrompt: String,
        userPrompt: String,
        maxTokens: Int,
        cliModel: String = "haiku",
        timeout: TimeInterval = defaultTimeout,
        database: DaemonDatabase,
        runtime: PluginRuntime = .live,
        cliRunner: CLIRunner = liveCLIRunner,
        secretStore: any SecretStoring = KeychainSecretStore(),
        inferenceGuard: LocalInferenceGuard? = .shared
    ) async throws -> String {
        // Snapshot the provider identity through the same reader the completion will use,
        // so the log row names what actually served the request (config vs CLI path).
        // Oversight resolves through its remapped reader (its own provider selection).
        let settings = database.aiProviderSettings(for: feature)
        let config = DaemonProviderResolver.selectedConfiguration(settings)
        let model: String = {
            guard let config else { return cliModel }
            let stored = DaemonProviderResolver.model(config: config.id, settings)
            return stored.isEmpty ? config.pluginIdentifier : stored
        }()
        let startedAt = Date()

        func record(response: String, outcome: String, errorText: String) {
            AIInteractionLog.record(
                feature: feature, sessionId: sessionId,
                providerKind: config == nil ? "cli" : "plugin",
                configName: config?.name ?? "", model: model,
                systemPrompt: systemPrompt, userPrompt: userPrompt, response: response,
                startedAt: startedAt, outcome: outcome, errorText: errorText,
                database: database
            )
        }

        do {
            let reply = try await complete(
                systemPrompt: systemPrompt, userPrompt: userPrompt, maxTokens: maxTokens,
                cliModel: cliModel, timeout: timeout, settings: settings,
                runtime: runtime, cliRunner: cliRunner, secretStore: secretStore,
                inferenceGuard: inferenceGuard
            )
            record(response: reply, outcome: "ok", errorText: "")
            return reply
        } catch let error as AIGuardError {
            let outcome = switch error {
            case .blocked: "guard_blocked"
            case .deferred: "guard_deferred"
            }
            record(response: "", outcome: outcome, errorText: error.localizedDescription)
            throw error
        } catch {
            record(response: "", outcome: "error", errorText: error.localizedDescription)
            throw error
        }
    }
}

extension ScriptAnalyzer {
    /// The live model path: a one-shot completion through `DaemonAIChat`, recorded in the
    /// `ai_interactions` log against the database the observer passes in.
    public static var live: ScriptAnalyzer { live(runtime: .live) }

    /// `live`, loading plugins through `runtime` (a daemon's
    /// `SessionDaemonRuntime.pluginRuntime`, which adds its configured folders).
    public static func live(runtime: DaemonAIChat.PluginRuntime) -> ScriptAnalyzer {
        ScriptAnalyzer(chat: { systemPrompt, userPrompt, sessionId, database in
            try await DaemonAIChat.complete(
                feature: .oversight, sessionId: sessionId,
                systemPrompt: systemPrompt, userPrompt: userPrompt, maxTokens: 48,
                cliModel: "haiku", database: database, runtime: runtime
            )
        })
    }
}

#endif
