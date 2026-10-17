#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// The scripts oversight ships with. Code-defined so an upgrade improves untouched
/// built-ins: bump the script's `version` here and `synchronizeShipped` refreshes
/// any stored copy the user hasn't modified.
public enum ShippedScripts {

    /// The compact script's default trigger: tokens actually in context.
    public static let compactDefaultTokens = 70_000

    public static func compact(trigger predicate: ScriptPredicate? = nil) -> OversightScript {
        OversightScript(
            id: "compact",
            name: "Compact",
            enabled: true,
            builtIn: true,
            version: 1,
            trigger: ScriptTrigger(
                predicate: predicate ?? .condition(
                    field: .tokensInContext, operation: .greaterOrEqual, value: String(compactDefaultTokens)
                ),
                llmConfirmation: LLMConfirmation(
                    systemPrompt: """
                        You supervise long-running Claude Code coding sessions. Given one session whose \
                        context window is filling up, decide whether to compact it NOW to free space, or \
                        wait. Compact when context is high AND the session is at a natural pause — the last \
                        action completed, not mid-edit. Wait when it is mid-task or still has room. \
                        Reply on ONE line, exactly "COMPACT: <reason>" or "WAIT: <reason>", reason under \
                        12 words. Output nothing else.
                        """,
                    actKeyword: "COMPACT"
                )
            ),
            response: ScriptResponse(
                kind: "compact",
                reasonTemplate: "Context {{context_used_pct}}% used — compact at a clean breakpoint",
                action: .injectText("/compact")
            )
        )
    }

    /// The canonical shipped definitions — the source of truth for `reset` and for
    /// version upgrades. The one-time legacy-threshold import is deliberately NOT
    /// baked in here (that would make `reset` restore a stale percentage instead of
    /// the shipped default); it is applied only on first insert via
    /// `seededForFirstInsert`.
    public static func all() -> [OversightScript] {
        [compact()]
    }

    /// The definition to write when a shipped script is inserted for the very first
    /// time: identical to the canonical one, except the compact script imports a
    /// tuned legacy `oversight_context_threshold_pct` as its trigger (once).
    public static func seededForFirstInsert(
        _ shipped: OversightScript, database: DaemonDatabase
    ) -> OversightScript {
        guard shipped.id == "compact", let legacy = legacyCompactTrigger(database) else { return shipped }
        return compact(trigger: legacy)
    }

    /// One-time intent import: a user who had tuned the legacy
    /// `oversight_context_threshold_pct` away from its default expressed "flag at
    /// N% used" — seed the compact trigger as that percentage condition instead of
    /// the token default. Only consulted when the script is first inserted.
    private static func legacyCompactTrigger(_ database: DaemonDatabase) -> ScriptPredicate? {
        let pct = Oversight.contextThresholdPct(database)
        guard pct != Oversight.defaultContextThresholdPct else { return nil }
        return .condition(field: .contextUsedPct, operation: .greaterOrEqual, value: String(pct))
    }
}

/// Storage/business rules over `oversight_scripts`: shipped-script seeding and
/// upgrade, validation, and the CRUD surface HTTP/XPC forward to.
public enum ScriptStore {

    public enum ScriptError: Error, LocalizedError {
        case invalid(String)
        case notFound
        case builtInUndeletable
        case notBuiltIn

        public var errorDescription: String? {
            switch self {
            case .invalid(let why): return why
            case .notFound: return "Script not found"
            case .builtInUndeletable: return "Built-in scripts can't be deleted (disable or reset instead)"
            case .notBuiltIn: return "Only built-in scripts can be reset"
            }
        }
    }

    /// Reconciles the stored table with the code-defined shipped scripts: inserts
    /// missing ones (importing legacy threshold intent), refreshes unmodified rows
    /// whose shipped definition version moved on, and never touches `user_modified`
    /// rows. Idempotent and cheap — run at the top of every oversight tick and
    /// before list reads, so the table is correct however the daemon got here.
    public static func synchronizeShipped(database: DaemonDatabase) {
        for shipped in ShippedScripts.all() {
            guard let existing = try? database.fetchOversightScriptRow(id: shipped.id) else {
                // First insert imports any tuned legacy threshold; later resets/upgrades
                // restore the canonical definition instead.
                try? database.upsertOversightScript(
                    ShippedScripts.seededForFirstInsert(shipped, database: database), userModified: false
                )
                continue
            }
            if !existing.userModified && existing.script.version < shipped.version {
                // Upgrade an untouched built-in to the canonical shipped definition; a
                // user-modified row is theirs.
                try? database.upsertOversightScript(shipped, userModified: false)
            }
        }
    }

    /// Every stored script (synchronizing shipped ones first).
    public static func scripts(database: DaemonDatabase) -> [OversightScript] {
        synchronizeShipped(database: database)
        return ((try? database.fetchOversightScriptRows()) ?? []).map(\.script)
    }

    public static func script(id: String, database: DaemonDatabase) -> OversightScript? {
        synchronizeShipped(database: database)
        return (try? database.fetchOversightScriptRow(id: id))?.script
    }

    /// Create-or-update from a user edit. Preserves `builtIn` from the stored row
    /// (a client can't promote/demote a script), stamps built-ins `user_modified`,
    /// and validates before writing. Returns the stored script.
    @discardableResult
    public static func save(_ incoming: OversightScript, database: DaemonDatabase) throws -> OversightScript {
        try validate(incoming)
        var script = incoming
        if let existing = try? database.fetchOversightScriptRow(id: script.id) {
            script.builtIn = existing.script.builtIn
            try database.upsertOversightScript(script, userModified: script.builtIn)
        } else {
            script.builtIn = false
            try database.upsertOversightScript(script, userModified: true)
        }
        return script
    }

    public static func delete(id: String, database: DaemonDatabase) throws {
        synchronizeShipped(database: database)
        guard let existing = try? database.fetchOversightScriptRow(id: id) else {
            throw ScriptError.notFound
        }
        guard !existing.script.builtIn else { throw ScriptError.builtInUndeletable }
        try database.deleteOversightScript(id: id)
    }

    /// Restore a built-in to its current shipped definition.
    @discardableResult
    public static func reset(id: String, database: DaemonDatabase) throws -> OversightScript {
        synchronizeShipped(database: database)
        guard let existing = try? database.fetchOversightScriptRow(id: id) else {
            throw ScriptError.notFound
        }
        guard existing.script.builtIn else { throw ScriptError.notBuiltIn }
        guard let shipped = ShippedScripts.all().first(where: { $0.id == id }) else {
            throw ScriptError.notFound
        }
        try database.upsertOversightScript(shipped, userModified: false)
        return shipped
    }

    /// The save-time rules; evaluation-side, an empty group is also false, so an
    /// invalid script can never fire even if one sneaks in.
    public static func validate(_ script: OversightScript) throws {
        guard !script.id.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ScriptError.invalid("Script id must not be empty")
        }
        guard !script.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ScriptError.invalid("Script name must not be empty")
        }
        guard !script.response.kind.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ScriptError.invalid("Response kind must not be empty")
        }
        if case .injectText(let text) = script.response.action,
           text.trimmingCharacters(in: .whitespaces).isEmpty {
            throw ScriptError.invalid("Inject text must not be empty")
        }
        if let confirmation = script.trigger.llmConfirmation,
           confirmation.actKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
            // An empty act keyword makes the parser read every verdict as "act" (an
            // empty prefix always matches), defeating the WAIT confirmation.
            throw ScriptError.invalid("An LLM-confirmed trigger needs a non-empty act keyword")
        }
        try validatePredicate(script.trigger.predicate)
    }

    private static func validatePredicate(_ predicate: ScriptPredicate) throws {
        switch predicate {
        case .all(let subs), .any(let subs):
            guard !subs.isEmpty else {
                throw ScriptError.invalid("A Match All/Any group needs at least one condition")
            }
            for sub in subs { try validatePredicate(sub) }
        case .condition(let field, _, let value):
            // `Double("nan")`/`Double("inf")` parse, so a plain non-nil check would
            // admit non-finite values that then compare per IEEE-754 (e.g. `!= nan`
            // is always true) and fire every tick — require a finite number.
            if field.isNumeric {
                guard let number = Double(value), number.isFinite else {
                    throw ScriptError.invalid("'\(field.rawValue)' compares numbers — '\(value)' isn't one")
                }
            }
        }
    }
}
#endif
