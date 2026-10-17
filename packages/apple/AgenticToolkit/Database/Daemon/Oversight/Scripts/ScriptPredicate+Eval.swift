#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// The values a predicate can inspect about one live session during one tick.
/// Derived fields are computed here (tokens-in-context from pct × window) and the
/// one DB lookup (`last_event_type`) is memoized so a predicate referencing it in
/// several conditions costs one query.
struct EvaluationContext {
    let session: LiveSessionSnapshot
    let database: DaemonDatabase
    /// Injectable clock for `idle_minutes` tests.
    var now: Date = Date()

    private var cachedLastEventType: String??

    init(session: LiveSessionSnapshot, database: DaemonDatabase, now: Date = Date()) {
        self.session = session
        self.database = database
        self.now = now
    }

    /// Tokens currently in the context window, derived from the status-line feed
    /// (pct × window / 100). 0 when the session never reported (window unknown).
    var tokensInContext: Int {
        session.contextUsedPct * session.contextWindowSize / 100
    }

    /// Minutes since the session's last activity (0 when the timestamp is
    /// unparseable — "unknown" must not read as "idle forever"). `last_activity_at` is
    /// stored via SQLite's `datetime()`, so `TimestampParsing` (not a bare ISO parser)
    /// is what actually reads it.
    var idleMinutes: Double {
        guard let last = TimestampParsing.parse(session.lastActivityAt) else { return 0 }
        return max(0, now.timeIntervalSince(last) / 60)
    }

    mutating func lastEventType() -> String {
        if let cached = cachedLastEventType {
            return cached ?? ""
        }
        let value = (try? database.lastEventType(sessionId: session.sessionId)) ?? ""
        cachedLastEventType = value
        return value
    }

    /// The session's current value for one field, as the string it compares as.
    /// Numeric fields render without formatting so `Double(_)` round-trips.
    mutating func rawValue(for field: ConditionField) -> String {
        switch field {
        case .tokensInContext: return String(tokensInContext)
        case .contextUsedPct: return String(session.contextUsedPct)
        case .contextWindowSize: return String(session.contextWindowSize)
        case .idleMinutes: return String(idleMinutes)
        case .lastEventType: return lastEventType()
        case .sessionStatus: return session.status
        case .model: return session.model
        case .projectPath: return session.cwd
        }
    }

    /// Substitute `{{field}}` placeholders in a reason template with the session's
    /// current values (e.g. "Context {{context_used_pct}}% used").
    mutating func renderReason(_ template: String) -> String {
        var out = template
        for field in ConditionField.allCases {
            let placeholder = "{{\(field.rawValue)}}"
            guard out.contains(placeholder) else { continue }
            out = out.replacingOccurrences(of: placeholder, with: rawValue(for: field))
        }
        return out
    }
}

extension ScriptPredicate {

    /// Evaluate against one session. An empty `all`/`any` group is **false** (a
    /// trigger must state a condition to fire — also rejected at save); numeric
    /// fields with an unparseable comparison value are false (fail closed).
    func evaluate(_ context: inout EvaluationContext) -> Bool {
        switch self {
        case .all(let subs):
            guard !subs.isEmpty else { return false }
            for sub in subs where !sub.evaluate(&context) {
                return false
            }
            return true
        case .any(let subs):
            for sub in subs where sub.evaluate(&context) {
                return true
            }
            return false
        case .condition(let field, let operation, let value):
            return Self.compare(
                actual: context.rawValue(for: field), operation: operation,
                expected: value, numeric: field.isNumeric
            )
        }
    }

    static func compare(actual: String, operation: ConditionOperator, expected: String, numeric: Bool) -> Bool {
        if numeric {
            guard let lhs = Double(actual), let rhs = Double(expected) else { return false }
            switch operation {
            case .equals: return lhs == rhs
            case .notEquals: return lhs != rhs
            case .greaterThan: return lhs > rhs
            case .greaterOrEqual: return lhs >= rhs
            case .lessThan: return lhs < rhs
            case .lessOrEqual: return lhs <= rhs
            case .contains: return false   // meaningless on numbers — fail closed
            }
        }
        switch operation {
        case .equals: return actual == expected
        case .notEquals: return actual != expected
        case .contains: return actual.localizedCaseInsensitiveContains(expected)
        case .greaterThan, .greaterOrEqual, .lessThan, .lessOrEqual: return false   // ordering on strings — fail closed
        }
    }
}
#endif
