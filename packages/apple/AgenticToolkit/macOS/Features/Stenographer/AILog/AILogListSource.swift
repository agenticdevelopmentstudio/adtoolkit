import Foundation
import AgenticToolkitCore

/// Backs the AI Log window: fetches `ai_interactions` rows from the daemon.
/// The row → cell mapping is a pure static function so it is unit-tested without
/// a daemon. Read-only.
@MainActor
final class AILogListSource {
    private let service: any StenographerDaemonService
    private(set) var rows: [AIInteractionDTO] = []

    init(service: any StenographerDaemonService) { self.service = service }

    func reload() async {
        // Newest first (the daemon's order); list rows carry truncated text.
        rows = await service.aiInteractions() ?? []
    }

    /// The full row (untruncated prompts/response) for the detail pane.
    func detail(id: Int) async -> AIInteractionDTO? {
        await service.aiInteraction(id: id)
    }

    /// Display cells for one interaction. `sessionName` is the human-friendly
    /// session label the window resolves from the sessions list (summary → git
    /// branch); when empty the session column falls back to the short id. Pure —
    /// unit-tested directly.
    nonisolated static func cells(
        for dto: AIInteractionDTO, sessionName: String = ""
    ) -> (time: String, feature: String, session: String, provider: String,
          duration: String, result: String) {
        let time = dto.createdAt.isEmpty ? "—" : dto.createdAt
        let feature = featureLabel(dto.feature)
        let session = sessionLabel(for: dto, name: sessionName)
        let duration = durationText(milliseconds: dto.durationMs)
        return (time, feature, session, providerText(for: dto), duration, resultText(for: dto))
    }

    /// Friendly, capitalized label for the `feature` discriminator
    /// (`summarize` → "Summary", `oversight` → "Oversight").
    nonisolated static func featureLabel(_ feature: String) -> String {
        switch feature {
        case "summarize": return "Summary"
        case "oversight": return "Oversight"
        case "": return "—"
        default: return feature.capitalized
        }
    }

    /// The session column: the resolved name when known, else the short id, else a dash.
    nonisolated static func sessionLabel(for dto: AIInteractionDTO, name: String) -> String {
        if !name.isEmpty { return name }
        return dto.sessionId.isEmpty ? "—" : String(dto.sessionId.prefix(8))
    }

    /// What the call actually did, on one line: the reply on success, the failure
    /// (marked with a warning glyph) on error, flattened so multi-line text sits in
    /// a single table row.
    nonisolated static func resultText(for dto: AIInteractionDTO) -> String {
        if dto.isFailure {
            let flat = flattenedSingleLine(dto.error)
            return flat.isEmpty ? "⚠ error" : "⚠ \(flat)"
        }
        let flat = flattenedSingleLine(dto.response)
        return flat.isEmpty ? "—" : flat
    }

    /// Collapses newlines/tabs to single spaces so prompt/response text renders on
    /// one table row (the full text still shows in the detail pane).
    nonisolated static func flattenedSingleLine(_ text: String) -> String {
        text.split(whereSeparator: { $0 == "\n" || $0 == "\r" || $0 == "\t" })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    /// "config · model" for the plugin path; "claude-cli · model" for the zero-config
    /// fallback — who actually served the call, at a glance.
    nonisolated static func providerText(for dto: AIInteractionDTO) -> String {
        let origin = dto.providerKind == "cli" ? "claude-cli" : dto.configName
        let parts = [origin, dto.model].filter { !$0.isEmpty }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    nonisolated static func durationText(milliseconds: Int) -> String {
        milliseconds < 1000
            ? "\(milliseconds) ms"
            : String(format: "%.1f s", Double(milliseconds) / 1000)
    }
}
