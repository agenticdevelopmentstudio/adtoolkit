#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Examines the live session fleet and emits findings — the read-only half of oversight.
///
/// An observer is a small, stateless unit of judgement (context pressure, stuck loop,
/// idle-too-long, cost spike…). It never mutates a session; it only reports what it sees.
/// `OversightService` runs every enabled observer over one fleet snapshot per tick and
/// persists the findings. Adding a new observer needs no new task, table, or endpoint —
/// conform, and register in `OversightRegistry`.
public protocol SessionObserver: Sendable {
    /// Stable identifier, namespacing this observer's findings (e.g. `"context"`).
    var name: String { get }

    /// Per-observer kill switch, read from settings each tick so it can be toggled live.
    /// The whole subsystem is additionally gated by `Oversight.isEnabled`.
    func isEnabled(_ database: DaemonDatabase) -> Bool

    /// Examine the fleet and return the findings that currently hold. Sessions absent
    /// from the returned set (but previously flagged by this observer) are reconciled to
    /// `stale` by the driver. `async` so an AI-backed observer can call the local model.
    func observe(
        sessions: [LiveSessionSnapshot],
        database: DaemonDatabase
    ) async -> [SessionFinding]
}

/// Performs an action about a session in response to a finding — the write-back half of
/// oversight. Defined now as the boundary future actors implement; the first concrete
/// actor (inject `/compact`) arrives with the action phase. The app's existing terminal
/// click-actions are conceptually actors too.
///
/// An actor is deliberately *not* wired into `OversightService` yet: Phase 1/2 only observe.
public protocol SessionActor: Sendable {
    /// Stable identifier (e.g. `"compact"`).
    var name: String { get }
    /// The finding `kind` this actor handles (e.g. `"compact"`).
    var handledKind: String { get }
    /// Act on a finding. Throwing signals the action could not be performed.
    func act(
        on finding: OversightFindingDTO,
        session: LiveSessionSnapshot,
        database: DaemonDatabase
    ) async throws
}

/// The set of observers one oversight tick runs: one `ScriptObserver` per enabled
/// stored script, all sharing a fresh per-tick LLM budget. Constructed per tick so
/// script edits (via the app/HTTP/XPC) take effect on the next tick without a
/// daemon restart.
public enum OversightRegistry {
    /// `analyzer` is the model path every script observer confirms through; the
    /// default has no model wired, so a confirmed trigger degrades to its rule.
    public static func observers(
        database: DaemonDatabase,
        budget: LLMTickBudget,
        analyzer: ScriptAnalyzer = .unavailable
    ) -> [any SessionObserver] {
        ScriptStore.scripts(database: database)
            .filter(\.enabled)
            .map { ScriptObserver(script: $0, budget: budget, analyzer: analyzer) }
    }
}

/// Subsystem-wide configuration, read from the settings table so the app can tune it
/// live without a daemon rebuild. Mirrors `DaemonSessionSummarizer.isEnabled`.
public enum Oversight {
    /// Master switch. **Opt-in** (default off) — unlike summaries, oversight watches and
    /// (later) acts on live sessions, so it stays dark until deliberately enabled.
    public static func isEnabled(_ database: DaemonDatabase) -> Bool {
        // Same opt-in truthiness as `retention_enabled`: Core's `RawSetting.bool`.
        RawSetting.bool((try? database.setting(for: "oversight_enabled")) ?? nil, default: false)
    }

    /// Context-used-% at or above which `ContextObserver` raises a `compact` finding.
    public static let defaultContextThresholdPct = 80

    public static func contextThresholdPct(_ database: DaemonDatabase) -> Int {
        // Out of range means the default here, not the nearest bound
        // (RawSetting.int clamps): a 0% or 150% threshold is a mistake, not a
        // request to compact at 1% or never.
        let raw = (try? database.setting(for: "oversight_context_threshold_pct")) ?? nil
        guard let raw, let value = Int(raw), (1...100).contains(value) else {
            return defaultContextThresholdPct
        }
        return value
    }

    /// Whether observers consult the local model for judgment (vs. the raw rule).
    /// **Opt-in** (default off): the rule keeps working without a provider configured,
    /// and turning this on is a deliberate step to spend model calls on oversight.
    public static func llmEnabled(_ database: DaemonDatabase) -> Bool {
        RawSetting.bool((try? database.setting(for: "oversight_llm_enabled")) ?? nil, default: false)
    }

    /// Cap on LLM evaluations per oversight tick — a burst guard mirroring the
    /// summarizer's `maxPerRun`. Candidates beyond it fall back to the rule this tick.
    public static let maxLLMEvaluationsPerTick = 4

    // MARK: - Provider selection

    /// Settings key: which provider configuration oversight completions use.
    /// "" (or unset) = inherit the AI Summaries selection (`ai_selected_config_id`);
    /// `claudeCLISentinel` = force the zero-config `claude -p` path; anything else is
    /// a configuration UUID from the synced registry.
    public static let selectedConfigKey = "oversight_selected_config_id"

    /// `selectedConfigKey` value that forces the CLI path even when summaries have a
    /// provider configuration selected. Defined once in the shared XPC package.
    public static let claudeCLISentinel = OversightProviderSelection.claudeCLISentinel

    /// Settings key: a model override for the oversight-selected configuration.
    /// "" (or unset) = the configuration's own stored model.
    public static let modelKey = "oversight_model"
}
#endif
