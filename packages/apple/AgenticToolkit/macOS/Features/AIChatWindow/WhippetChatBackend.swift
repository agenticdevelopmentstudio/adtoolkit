import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

import Foundation

/// A `ChatBackend` that dispatches to the provider configured in `WhippetSettingsViewModel`.
/// Routes to the Claude CLI when `aiProvider.usesCLI`, otherwise uses `AIRequestBuilder`
/// to build a provider-specific HTTP request.
///
/// Tool calling is not wired up: `AIRequestBuilder` produces a flat
/// chat-completion request and the Claude CLI path doesn't take a tool list.
/// The class therefore inherits `ChatBackend`'s default tool-aware
/// `sendMessages`, which delegates to the text-only path and emits every
/// chunk as a `.textDelta`.
@MainActor
public class WhippetChatBackend: ChatBackend {

    public var aiInfo: AIModelChatConfig

    public init(aiInfo: AIModelChatConfig) {
        self.aiInfo = aiInfo
    }

    // MARK: - ChatBackend

    public var isReady: Bool { true }

    public nonisolated func isReadyChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(true)
            continuation.finish()
        }
    }

    public func sendMessages(_ messages: [ChatBackendMessage]) async -> AsyncThrowingStream<String, Error> {
        let provider = aiInfo.aiProvider
        let model = aiInfo.aiModel
        let baseURL = aiInfo.aiBaseURL
        let summariesEnabled = aiInfo.aiSummariesEnabled
        // Read the API key on the MainActor (where SettingsStore lives) before
        // hopping into the detached task, which is non-isolated.
        let apiKey = aiInfo.apiKey

        return AsyncThrowingStream { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    let reply: String
                    if provider.usesCLI {
                        let prompt = messages.last(where: { $0.role == .user })?.content ?? ""
                        reply = try await Self.runClaudeCLI(prompt: prompt, model: model)
                    } else {
                        guard summariesEnabled else {
                            throw WhippetChatBackendError.featuresDisabled
                        }
                        guard !apiKey.isEmpty else {
                            throw WhippetChatBackendError.missingAPIKey
                        }
                        reply = try await Self.runAPIRequest(
                            provider: provider, model: model, apiKey: apiKey,
                            baseURL: baseURL, messages: messages
                        )
                    }
                    continuation.yield(reply)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - API Dispatch

    private static func runAPIRequest(
        provider: AIProvider,
        model: String,
        apiKey: String,
        baseURL: String,
        messages: [ChatBackendMessage]
    ) async throws -> String {
        let apiMessages = messages.compactMap { msg -> [String: String]? in
            let role: String
            switch msg.role {
            case .user: role = "user"
            case .assistant: role = "assistant"
            case .system: role = "system"
            case .toolUse, .toolResult: return nil
            }
            return ["role": role, "content": msg.content]
        }

        let config = AIRequestConfig(
            provider: provider, model: model, apiKey: apiKey,
            customBaseURL: baseURL, maxTokens: 256, timeoutInterval: 30
        )
        let request = try AIRequestBuilder.buildRequest(config: config, messages: apiMessages)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIRequestError.invalidResponse
        }
        guard http.statusCode == 200 || http.statusCode == 201 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw WhippetChatBackendError.httpError(
                AIRequestBuilder.parseErrorMessage(from: body, statusCode: http.statusCode)
            )
        }
        return AIRequestBuilder.parseAssistantReply(from: data, provider: provider)
    }

    // MARK: - Claude CLI

    /// How long a chat reply from `claude -p` may take before it is given up on.
    private static let cliTimeout: TimeInterval = 30

    /// `ClaudeCLI.run`, which owns finding the binary, the child's PATH and a
    /// run that always comes back, with its errors read into this backend's.
    private static func runClaudeCLI(prompt: String, model: String) async throws -> String {
        do {
            return try await ClaudeCLI.run(prompt: prompt, systemPrompt: "", model: model, timeout: cliTimeout)
        } catch let error as ClaudeCLI.CLIError {
            switch error {
            case .binaryNotFound:
                throw WhippetChatBackendError.cliNotFound
            case .emptyReply:
                throw WhippetChatBackendError.emptyReply
            case .nonZeroExit(let code, let stderr):
                let message = stderr.isEmpty ? "Exit code \(code)" : stderr
                throw WhippetChatBackendError.cliFailed(String(message.prefix(200)))
            case .launchFailed, .timedOut:
                throw WhippetChatBackendError.cliFailed(String(error.localizedDescription.prefix(200)))
            }
        }
    }
}

// MARK: - Errors

public enum WhippetChatBackendError: Error, LocalizedError {
    case cliNotFound
    case cliFailed(String)
    case emptyReply
    case missingAPIKey
    case featuresDisabled
    case httpError(String)

    public var errorDescription: String? {
        switch self {
        case .cliNotFound: return "Claude CLI not found. Install Claude Code or check your PATH."
        case .cliFailed(let msg): return "claude -p failed: \(msg)"
        case .emptyReply: return "Empty reply from Claude CLI"
        case .missingAPIKey: return "No API key configured."
        case .featuresDisabled: return "AI features are disabled — enable them in Settings."
        case .httpError(let msg): return msg
        }
    }
}
