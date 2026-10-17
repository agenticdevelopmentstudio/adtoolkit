#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import AIPluginKit
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - AI interaction log

    /// Working bound for `ai_interactions`: every insert prunes to the newest N in the
    /// same write, so the log never grows past this even with retention off.
    public static let maxAIInteractionRows = 500

    /// Records one LLM call (full prompt/response text) and prunes the table to the
    /// newest `maxAIInteractionRows` in the same write.
    public func insertAIInteraction(
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
        error: String
    ) throws {
        try write { _ in
            try execute("""
                INSERT INTO ai_interactions
                    (feature, session_id, provider_kind, config_name, model,
                     system_prompt, user_prompt, response, duration_ms, outcome, error)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, params: [
                feature, sessionId, providerKind, configName, model,
                systemPrompt, userPrompt, response, durationMs, outcome, error
            ])
            try execute("""
                DELETE FROM ai_interactions WHERE id NOT IN
                    (SELECT id FROM ai_interactions ORDER BY id DESC LIMIT ?)
            """, params: [Self.maxAIInteractionRows])
        }
    }

    /// Recent interactions, newest first, with the three long text fields truncated
    /// SQL-side to `truncateTo` chars (`truncated` = true when anything was cut) so the
    /// list stays light; `fetchAIInteraction(id:)` returns the full text.
    public func fetchAIInteractions(limit: Int = 200, truncateTo: Int = 300) throws -> [AIInteractionDTO] {
        try read { _ in
            var out: [AIInteractionDTO] = []
            try query("""
                SELECT id, feature, session_id, provider_kind, config_name, model,
                       substr(system_prompt, 1, ?), substr(user_prompt, 1, ?),
                       substr(response, 1, ?), duration_ms, outcome, error, created_at,
                       (length(system_prompt) > ? OR length(user_prompt) > ?
                        OR length(response) > ?)
                FROM ai_interactions
                ORDER BY id DESC LIMIT ?
            """, params: [
                truncateTo, truncateTo, truncateTo,
                truncateTo, truncateTo, truncateTo, limit
            ]) { row in
                out.append(makeAIInteraction(row, truncated: int(row, 13) != 0))
            }
            return out
        }
    }

    /// One interaction with its full prompt/response text, or nil if absent.
    public func fetchAIInteraction(id: Int) throws -> AIInteractionDTO? {
        try read { _ in
            var out: AIInteractionDTO?
            try query("""
                SELECT id, feature, session_id, provider_kind, config_name, model,
                       system_prompt, user_prompt, response, duration_ms, outcome,
                       error, created_at
                FROM ai_interactions WHERE id = ?
            """, params: [id]) { row in
                out = makeAIInteraction(row, truncated: false)
            }
            return out
        }
    }

    /// Column order matches the two SELECTs above (the by-id read simply has no
    /// trailing truncated flag) — one row→DTO mapping so the reads can't drift.
    private func makeAIInteraction(_ row: Row, truncated: Bool) -> AIInteractionDTO {
        AIInteractionDTO(
            id: Int(int(row, 0)),
            feature: string(row, 1),
            sessionId: string(row, 2),
            providerKind: string(row, 3),
            configName: string(row, 4),
            model: string(row, 5),
            systemPrompt: string(row, 6),
            userPrompt: string(row, 7),
            response: string(row, 8),
            durationMs: Int(int(row, 9)),
            outcome: string(row, 10),
            error: string(row, 11),
            truncated: truncated,
            createdAt: string(row, 12)
        )
    }
}

/// Namespaces the interaction-log writes (and their failure logging) out of the
/// completion path's control flow.
enum AIInteractionLog {
    /// Best-effort: a failed log write must never block or alter the completion.
    static func record(
        feature: AIFeature, sessionId: String?, providerKind: String, configName: String,
        model: String, systemPrompt: String, userPrompt: String, response: String,
        startedAt: Date, outcome: String, errorText: String, database: DaemonDatabase
    ) {
        let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
        do {
            try database.insertAIInteraction(
                feature: feature.rawValue,
                sessionId: sessionId ?? "",
                providerKind: providerKind,
                configName: configName,
                model: model,
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                response: response,
                durationMs: durationMs,
                outcome: outcome,
                error: errorText
            )
        } catch {
            logger.error("Failed to record AI interaction: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension AIInteractionLog: Loggable {
    public static nonisolated let logger = makeLogger()
}

#endif
