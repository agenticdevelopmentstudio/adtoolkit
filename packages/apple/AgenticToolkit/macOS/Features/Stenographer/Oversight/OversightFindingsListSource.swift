import Foundation
import AgenticToolkitCore

/// Backs the AI Oversight window: fetches the observers' findings from the daemon. The
/// row → cell mapping is a pure static function so it is unit-tested without the
/// daemon. Read-only — this window observes; it does not act (yet).
@MainActor
final class OversightFindingsListSource {
    private(set) var rows: [OversightFindingDTO] = []
    private let service: any StenographerDaemonService

    init(service: any StenographerDaemonService) { self.service = service }

    func reload() async {
        // All statuses, ordered by severity (the daemon's default) so the most
        // urgent lead and resolved/stale history stays visible below them.
        rows = await service.oversightFindings() ?? []
    }

    /// Display cells for one finding. Pure — unit-tested directly.
    nonisolated static func cells(
        for dto: OversightFindingDTO
    ) -> (session: String, observer: String, kind: String, severity: String, status: String, reason: String) {
        let session = dto.sessionId.isEmpty ? "—" : String(dto.sessionId.prefix(8))
        let observer = dto.observer.isEmpty ? "—" : dto.observer
        let kind = dto.kind.isEmpty ? "—" : dto.kind
        let severity = "\(dto.severity)"
        let status = dto.status.isEmpty ? "—" : dto.status
        let reason = dto.reason.isEmpty ? "—" : dto.reason
        return (session, observer, kind, severity, status, reason)
    }
}
