#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import OSLog

/// Drives session oversight: once per tick it takes one snapshot of the live fleet,
/// runs every enabled `SessionObserver` over it, and reconciles their findings into the
/// `oversight_findings` store (new/updated findings upserted; resolved ones marked
/// `stale`). Read-only with respect to sessions — it observes and records, never acts.
///
/// Gated on `oversight_enabled` (default off). Generic by construction: adding an
/// observer to `OversightRegistry` needs no change here. The host owns the schedule;
/// this owns what one tick does.
public enum OversightService {

    /// What one tick did, for the host's own accounting.
    public struct TickResult: Sendable, Equatable {
        /// Findings the observers reported this tick (zero when the subsystem is off).
        public let findings: Int
        /// Live sessions the observers examined.
        public let sessions: Int

        public init(findings: Int, sessions: Int) {
            self.findings = findings
            self.sessions = sessions
        }

        /// A tick that did nothing — the subsystem is off.
        public static let idle = TickResult(findings: 0, sessions: 0)
    }

    /// The default observer set: one `ScriptObserver` per enabled stored script,
    /// sharing a fresh per-tick LLM budget. Constructed per tick, so a script edit
    /// takes effect on the next tick.
    public static func defaultObservers(
        database: DaemonDatabase,
        analyzer: ScriptAnalyzer = .unavailable
    ) -> [any SessionObserver] {
        OversightRegistry.observers(
            database: database,
            budget: LLMTickBudget(Oversight.maxLLMEvaluationsPerTick),
            analyzer: analyzer
        )
    }

    /// Run one oversight tick. `makeObservers` builds the tick's observers; it is
    /// injectable so a host (or a test) can substitute canned observers.
    @discardableResult
    public static func tick(
        database: DaemonDatabase,
        makeObservers: @Sendable (DaemonDatabase) -> [any SessionObserver]
    ) async -> TickResult {
        guard Oversight.isEnabled(database) else { return .idle }

        let snapshot = (try? database.fetchLiveSessionsWithContext()) ?? []
        // Even with no live sessions we still reconcile, so findings for sessions that
        // just ended get marked stale rather than lingering as pending.

        // Constructed per tick, so a script edit takes effect on the next tick.
        let observers = makeObservers(database)

        var totalFindings = 0
        for observer in observers where observer.isEnabled(database) {
            let findings = await observer.observe(sessions: snapshot, database: database)
            for finding in findings {
                do {
                    try database.upsertOversightFinding(finding)
                } catch {
                    logger.debug("oversight upsert failed: \(error.localizedDescription, privacy: .public)")
                }
            }
            // Resolve: any still-pending finding this observer no longer reports goes stale.
            let stillHolding = Set(findings.map(\.sessionId))
            try? database.markOversightFindingsResolved(observer: observer.name, exceptSessions: stillHolding)
            totalFindings += findings.count
        }

        // Orphan reconciliation: pending findings from observers that no longer run
        // (deleted/disabled scripts, retired observers like the old "context" one) go
        // stale rather than lingering as pending forever.
        try? database.markOversightFindingsStale(observersNotIn: Set(observers.map(\.name)))

        if totalFindings > 0 {
            logger.info("Oversight recorded \(totalFindings) finding(s) across \(snapshot.count) live session(s)")
        }
        return TickResult(findings: totalFindings, sessions: snapshot.count)
    }
}

extension OversightService: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
