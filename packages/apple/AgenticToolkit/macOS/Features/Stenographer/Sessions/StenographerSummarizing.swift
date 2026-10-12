import Foundation
import AgenticToolkitCore

/// Routes the Sessions window's "Summarize" action to the daemon's
/// `POST /sessions/:id/summarize`, so the daemon (not the app) owns summarization —
/// keeping the app a thin viewer. The new summary lands in the DB and the list
/// source's poll surfaces it.
public final class StenographerSummarizing: SessionWatcher.SessionSummarizing, @unchecked Sendable {

    public enum SummarizeError: LocalizedError {
        /// `reason` is the daemon's own description when it reported one (e.g. the
        /// local-model memory guard's refusal); nil for transport-level failures.
        case requestFailed(reason: String?)

        public var errorDescription: String? {
            switch self {
            case .requestFailed(let reason):
                guard let reason, !reason.isEmpty else { return "the daemon could not generate a summary" }
                return reason
            }
        }
    }

    private let service: any StenographerDaemonService

    public init(service: any StenographerDaemonService) { self.service = service }

    public func summarize(sessionId: String) async throws {
        do {
            try await service.summarize(sessionId: sessionId)
        } catch let failure as SummarizeDaemonFailure {
            // Keep the daemon's reason — the sessions list surfaces
            // `localizedDescription` directly in its error banner.
            throw SummarizeError.requestFailed(reason: failure.reason)
        } catch {
            throw SummarizeError.requestFailed(reason: nil)
        }
    }
}
