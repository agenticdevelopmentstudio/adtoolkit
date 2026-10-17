#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import AIPluginKit
import Foundation
import OSLog

/// The per-tick LLM-call allowance, shared across every script observer so a large
/// fleet with several LLM-confirmed scripts can't burst model calls. Candidates
/// beyond the budget fall back to the deterministic rule this tick.
public final class LLMTickBudget: @unchecked Sendable {
    private let lock = NSLock()
    private var remaining: Int

    public init(_ limit: Int) {
        remaining = limit
    }

    /// Take one call from the budget; false when exhausted.
    public func consume() -> Bool {
        lock.withLock {
            guard remaining > 0 else { return false }
            remaining -= 1
            return true
        }
    }

    /// Drain the budget — no further LLM calls this tick. Used when the memory guard
    /// refuses local inference: every remaining candidate (this script's and every
    /// other observer sharing the budget) would hit the same wall.
    public func exhaust() {
        lock.withLock { remaining = 0 }
    }
}

/// One stored script as a `SessionObserver`: evaluates the trigger predicate over
/// each live session, optionally puts matches to the model for confirmation, and
/// records the script's response as a finding. Findings are namespaced by the
/// script's id (`observer == script.id`), so per-script reconciliation and the
/// action lookup both key off it.
public struct ScriptObserver: SessionObserver {
    public let script: OversightScript
    public let budget: LLMTickBudget
    /// Injectable so tests drive the LLM path without a real model.
    public var analyzer: ScriptAnalyzer

    public init(script: OversightScript, budget: LLMTickBudget, analyzer: ScriptAnalyzer = .unavailable) {
        self.script = script
        self.budget = budget
        self.analyzer = analyzer
    }

    public var name: String { script.id }

    public func isEnabled(_ database: DaemonDatabase) -> Bool { script.enabled }

    public func observe(
        sessions: [LiveSessionSnapshot],
        database: DaemonDatabase
    ) async -> [SessionFinding] {
        var findings: [SessionFinding] = []
        let llmEnabled = Oversight.llmEnabled(database)
        for session in sessions {
            var context = EvaluationContext(session: session, database: database)
            guard script.trigger.predicate.evaluate(&context) else { continue }

            // The predicate matched. LLM confirmation runs only when the script asks
            // for it AND the subsystem switch is on AND this tick's budget allows;
            // otherwise the deterministic match stands on its own.
            guard let confirmation = script.trigger.llmConfirmation, llmEnabled, budget.consume() else {
                findings.append(finding(for: session, context: &context, source: .rule, model: ""))
                continue
            }
            let verdict: ScriptAnalyzer.Verdict
            do {
                verdict = try await analyzer.verdict(
                    for: session, confirmation: confirmation, database: database
                )
            } catch {
                // The guard refused local inference (model over budget / memory
                // pressure) — terminal for this tick, mirroring a summarizer's halt:
                // drain the shared budget so no further model call happens (this
                // candidate and all remaining ones degrade to the rule), and at most
                // one guard row lands in ai_interactions per tick.
                budget.exhaust()
                Self.logger.notice(
                    "Oversight LLM confirmation halted by guard: \(error.localizedDescription, privacy: .public)"
                )
                findings.append(finding(for: session, context: &context, source: .rule, model: ""))
                continue
            }
            switch verdict {
            case .act(let reason):
                findings.append(finding(
                    for: session, context: &context, source: .llm,
                    model: ScriptAnalyzer.modelLabel(database), reason: reason
                ))
            case .wait:
                // The model judged this not a good moment → no finding (the driver
                // reconciles any prior one to stale).
                continue
            case .unavailable:
                // Unreachable/unparseable model degrades to the rule — never dark.
                findings.append(finding(for: session, context: &context, source: .rule, model: ""))
            }
        }
        return findings
    }

    /// The recorded finding: the script's response kind, its rendered reason (unless
    /// the model supplied one), context pressure as the ordering hint, and the same
    /// structured detail the compact flow has always carried.
    private func finding(
        for session: LiveSessionSnapshot,
        context: inout EvaluationContext,
        source: FindingSource,
        model: String,
        reason: String? = nil
    ) -> SessionFinding {
        SessionFinding(
            sessionId: session.sessionId,
            observer: script.id,
            kind: script.response.kind,
            severity: session.contextUsedPct,
            source: source,
            model: model,
            reason: reason ?? context.renderReason(script.response.reasonTemplate),
            detail: "{\"context_used_pct\":\(session.contextUsedPct),"
                + "\"context_window_size\":\(session.contextWindowSize)}"
        )
    }
}

extension ScriptObserver: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
