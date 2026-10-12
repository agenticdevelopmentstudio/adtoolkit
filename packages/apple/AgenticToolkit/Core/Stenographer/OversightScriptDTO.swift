import Foundation

/// The oversight provider-selection sentinel, shared by the app's provider picker and
/// the daemon's oversight settings reader so the two can't drift: an
/// `oversight_selected_config_id` equal to `claudeCLISentinel` forces the zero-config
/// `claude -p` path ("" = inherit the AI Summaries selection; anything else is a
/// configuration UUID).
public enum OversightProviderSelection {
    public static let claudeCLISentinel = "claude-cli"
}

/// One oversight script: a trigger (a predicate over a live session, optionally
/// confirmed by the LLM) and a response (the finding it records and the action a
/// human can dispatch on it). Scripts are the configuration surface of oversight —
/// the shipped "compact" script is just the first one; users create their own.
///
/// Lives in the shared XPC package so the daemon (evaluation, storage), the app
/// (editor), HTTP, and XPC all speak the identical shape. Wire encoding uses the
/// stenographer-wide snake_case strategies; the enums below hand-write their
/// Codable with fixed single-word keys so they are strategy-invariant.
public struct OversightScript: Codable, Sendable, Equatable {
    /// Stable identifier — a slug for built-ins ("compact"), a UUID string for
    /// user scripts. Doubles as the findings' `observer` namespace.
    public var id: String
    public var name: String
    public var enabled: Bool
    /// Shipped with the daemon (upgradeable, resettable, not deletable).
    public var builtIn: Bool
    /// Version of the *shipped definition* — bumped in code when a built-in's
    /// definition improves, so upgrades can refresh unmodified rows.
    public var version: Int
    public var trigger: ScriptTrigger
    public var response: ScriptResponse

    public init(
        id: String,
        name: String,
        enabled: Bool,
        builtIn: Bool,
        version: Int,
        trigger: ScriptTrigger,
        response: ScriptResponse
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.builtIn = builtIn
        self.version = version
        self.trigger = trigger
        self.response = response
    }
}

/// When a script fires: the deterministic predicate, optionally double-checked by
/// the LLM (which itself is double-gated by the `oversight_llm_enabled` switch).
public struct ScriptTrigger: Codable, Sendable, Equatable {
    public var predicate: ScriptPredicate
    public var llmConfirmation: LLMConfirmation?

    public init(predicate: ScriptPredicate, llmConfirmation: LLMConfirmation? = nil) {
        self.predicate = predicate
        self.llmConfirmation = llmConfirmation
    }
}

/// Ask the model to confirm a predicate match before recording the finding. The
/// reply contract is fixed: one line, `"<ACTKEYWORD>: reason"` to act or
/// `"WAIT: reason"` to skip this tick.
public struct LLMConfirmation: Codable, Sendable, Equatable {
    public var systemPrompt: String
    /// The affirmative keyword the model replies with (e.g. "COMPACT").
    public var actKeyword: String

    public init(systemPrompt: String, actKeyword: String) {
        self.systemPrompt = systemPrompt
        self.actKeyword = actKeyword
    }
}

/// A boolean tree over one live session — the NSPredicate-editor idiom
/// (`Match All/Any of: [field][op][value]`) as a small Codable model the daemon
/// evaluates in Swift. Empty groups evaluate to false (and are rejected at save).
public indirect enum ScriptPredicate: Sendable, Equatable {
    case all([ScriptPredicate])
    case any([ScriptPredicate])
    case condition(field: ConditionField, operation: ConditionOperator, value: String)
}

/// What a condition inspects about a session. Numeric fields compare the
/// condition's value parsed as a number; string fields support eq/ne/contains.
/// `tokens_in_context` is derived: context_used_pct × context_window_size / 100.
public enum ConditionField: String, Codable, Sendable, CaseIterable {
    case tokensInContext = "tokens_in_context"
    case contextUsedPct = "context_used_pct"
    case contextWindowSize = "context_window_size"
    case lastEventType = "last_event_type"
    case idleMinutes = "idle_minutes"
    case sessionStatus = "session_status"
    case model = "model"
    case projectPath = "project_path"

    /// Whether comparisons parse the value numerically.
    public var isNumeric: Bool {
        switch self {
        case .tokensInContext, .contextUsedPct, .contextWindowSize, .idleMinutes:
            return true
        case .lastEventType, .sessionStatus, .model, .projectPath:
            return false
        }
    }
}

public enum ConditionOperator: String, Codable, Sendable, CaseIterable {
    case equals = "eq"
    case notEquals = "ne"
    case greaterThan = "gt"
    case greaterOrEqual = "gte"
    case lessThan = "lt"
    case lessOrEqual = "lte"
    case contains
}

/// What a fired script records: the finding's actionable `kind`, its
/// human-readable reason (with `{{field}}` substitution), and the action a human
/// click dispatches.
public struct ScriptResponse: Codable, Sendable, Equatable {
    /// The finding `kind` (e.g. "compact").
    public var kind: String
    /// Reason line; `{{context_used_pct}}`-style placeholders substitute the
    /// session's current values.
    public var reasonTemplate: String
    public var action: ScriptAction

    public init(kind: String, reasonTemplate: String, action: ScriptAction) {
        self.kind = kind
        self.reasonTemplate = reasonTemplate
        self.action = action
    }
}

/// v1 actions: type text into the session's terminal (human-approved via the
/// existing safety gate), or record-only. The `type`-discriminated wire format
/// accommodates future cases (notify, run-command, …) without a shape change.
public enum ScriptAction: Sendable, Equatable {
    case injectText(String)
    case none
}

// MARK: - Hand-written Codable (type-discriminated, strategy-invariant keys)

extension ScriptPredicate: Codable {
    private enum Keys: String, CodingKey {
        case type
        case predicates
        case field
        case operation = "op"
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "all":
            self = .all(try container.decode([ScriptPredicate].self, forKey: .predicates))
        case "any":
            self = .any(try container.decode([ScriptPredicate].self, forKey: .predicates))
        case "condition":
            self = .condition(
                field: try container.decode(ConditionField.self, forKey: .field),
                operation: try container.decode(ConditionOperator.self, forKey: .operation),
                value: try container.decode(String.self, forKey: .value)
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown predicate type '\(type)'"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        switch self {
        case .all(let predicates):
            try container.encode("all", forKey: .type)
            try container.encode(predicates, forKey: .predicates)
        case .any(let predicates):
            try container.encode("any", forKey: .type)
            try container.encode(predicates, forKey: .predicates)
        case .condition(let field, let operation, let value):
            try container.encode("condition", forKey: .type)
            try container.encode(field, forKey: .field)
            try container.encode(operation, forKey: .operation)
            try container.encode(value, forKey: .value)
        }
    }
}

extension ScriptAction: Codable {
    private enum Keys: String, CodingKey {
        case type
        case text
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "inject":
            self = .injectText(try container.decode(String.self, forKey: .text))
        case "none":
            self = .none
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown action type '\(type)'"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        switch self {
        case .injectText(let text):
            try container.encode("inject", forKey: .type)
            try container.encode(text, forKey: .text)
        case .none:
            try container.encode("none", forKey: .type)
        }
    }
}
