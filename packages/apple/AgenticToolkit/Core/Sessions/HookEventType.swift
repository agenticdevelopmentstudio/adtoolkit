import Foundation

/// The Claude Code hook events a session daemon captures.
///
/// Both daemons and their apps derive hook registration from `allCases`: the
/// installer registers exactly this list, and the apps' Settings UIs need the
/// same list to drive install/uninstall.
public enum HookEventType: String, CaseIterable, Sendable {
    // Core session lifecycle
    case sessionStart        = "SessionStart"
    case sessionEnd          = "SessionEnd"

    // Prompt
    case userPromptSubmit    = "UserPromptSubmit"

    // Tool use
    case preToolUse          = "PreToolUse"
    case postToolUse         = "PostToolUse"
    case postToolUseFailure  = "PostToolUseFailure"

    // Permissions
    case permissionRequest   = "PermissionRequest"
    case permissionDenied    = "PermissionDenied"

    // Turn completion
    case stop                = "Stop"
    case stopFailure         = "StopFailure"

    // Subagents
    case subagentStart       = "SubagentStart"
    case subagentStop        = "SubagentStop"

    // Notifications
    case notification        = "Notification"

    // Compaction
    case preCompact          = "PreCompact"
    case postCompact         = "PostCompact"

    // Setup
    case setup               = "Setup"

    // Teammates
    case teammateIdle        = "TeammateIdle"

    // Tasks
    case taskCreated         = "TaskCreated"
    case taskCompleted       = "TaskCompleted"

    // MCP elicitation
    case elicitation         = "Elicitation"
    case elicitationResult   = "ElicitationResult"

    // Configuration
    case configChange        = "ConfigChange"
    case instructionsLoaded  = "InstructionsLoaded"

    // Worktrees
    case worktreeCreate      = "WorktreeCreate"
    case worktreeRemove      = "WorktreeRemove"

    // Environment
    case cwdChanged          = "CwdChanged"
    case fileChanged         = "FileChanged"

    // Status line (stenographer-specific; Claude Code itself does not emit
    // this event — the stenographer-status-line dispatcher forwards each
    // render's stdin payload to `steno hook --event StatusLine`).
    case statusLine          = "StatusLine"

    /// Event types that are *not* evidence the session did anything.
    ///
    /// Everything else advances `sessions.last_activity_at` and flips the row back to
    /// `active` (whether it may also set the activity icon's `last_event_type` is
    /// ``setsTurnState(_:hookData:)``'s call). These must not,
    /// because they fire for reasons that have nothing to do with the session:
    ///
    /// - `ConfigChange` fans out to **every** live session the instant a settings
    ///   file is edited. One `~/.claude/settings.json` save stamped seven untouched
    ///   sessions with the same second, which is exactly what pulled hours-old
    ///   sessions back inside the Sessions window's "last 6 hours" filter.
    /// - `StatusLine` is a *render*, posted many times per second while a terminal
    ///   is merely visible. Counting it would make every on-screen session look
    ///   permanently busy and make the recency filter meaningless.
    /// - `InstructionsLoaded` reports a CLAUDE.md/AGENTS.md read, which likewise
    ///   fans out when an instruction file changes underneath idle sessions.
    ///
    /// A row these events create from scratch still gets the event's timestamp —
    /// learning of a session at all is news. What they may not do is *move* a row
    /// that already exists.
    public static let ambientEventTypes: Set<String> = [
        configChange.rawValue,
        statusLine.rawValue,
        instructionsLoaded.rawValue
    ]

    /// Whether an event of this raw type should advance the session's activity.
    /// Unknown types count as activity: a hook we don't model yet is more likely
    /// to be real work than ambient noise.
    public static func isActivity(_ rawEventType: String) -> Bool {
        !ambientEventTypes.contains(rawEventType)
    }

    /// Event types that report on *something other than the main agent's turn*, so
    /// they may not decide whether the session reads as working, idle or waiting.
    ///
    /// - Subagent and task bookkeeping arrives after the main turn has already
    ///   ended: a background agent's `SubagentStop` lands after the `Stop`, and
    ///   stored as the session's state it left a finished session spinning forever.
    /// - Compaction is housekeeping around a turn, not a turn. A manual `/compact`
    ///   runs from the prompt and returns to it; an automatic one happens inside a
    ///   turn that is already working. Either way the state before it is still right.
    /// - `FileChanged` reports a watched file changing on disk, whoever changed it.
    public static let offTurnEventTypes: Set<String> = [
        subagentStart.rawValue,
        subagentStop.rawValue,
        taskCreated.rawValue,
        taskCompleted.rawValue,
        teammateIdle.rawValue,
        preCompact.rawValue,
        postCompact.rawValue,
        fileChanged.rawValue
    ]

    /// The `Notification` types that mean the agent is blocked on the user. The rest
    /// are informational — above all `idle_prompt`, which Claude Code sends a minute
    /// after *every* finished turn, so reading it as "waiting" turned every idle
    /// session into one asking for attention.
    public static let waitingNotificationTypes: Set<String> = [
        "permission_prompt",
        "elicitation_dialog"
    ]

    /// The event types that end the main agent's turn: nothing is running until the
    /// user says something. `InterruptedTurnTask` skips sessions already in one.
    public static let turnEndingEventTypes: Set<String> = [
        stop.rawValue,
        stopFailure.rawValue,
        sessionEnd.rawValue
    ]

    /// The synthetic `last_event_type` recorded when the user interrupts a turn.
    /// Claude Code fires no hook for an interrupt, so without it the session kept
    /// the state of whatever tool call was cut short — working, indefinitely. See
    /// `InterruptedTurnTask`.
    public static let interruptedEventType = "Interrupted"

    /// Whether an event may set the session's `last_event_type` — the state behind
    /// the Sessions window's activity icon (working / idle / waiting).
    ///
    /// Only events about the **main agent's turn** may. Ambient events don't (see
    /// ``ambientEventTypes``), nor do the ``offTurnEventTypes``, nor anything a
    /// subagent did — every hook a subagent fires carries its `agent_id`. A
    /// `Notification` counts only when it is one the user has to answer, and a
    /// `SessionStart` only when it opens a session (a `compact` start is the
    /// compaction's own bookkeeping).
    ///
    /// Requests that block on the user — `PermissionRequest`, `Elicitation` — count
    /// even from a subagent: the session is waiting on the user either way.
    /// A `Notification` without a `notification_type` keeps the old reading
    /// (waiting), because nothing says it isn't one.
    public static func setsTurnState(_ rawEventType: String, hookData: [String: Any]) -> Bool {
        guard isActivity(rawEventType), !offTurnEventTypes.contains(rawEventType) else { return false }
        switch rawEventType {
        case permissionRequest.rawValue, elicitation.rawValue:
            return true
        case notification.rawValue:
            let type = hookData["notification_type"] as? String ?? ""
            return type.isEmpty || waitingNotificationTypes.contains(type)
        case sessionStart.rawValue:
            return hookData["source"] as? String != "compact"
        default:
            let agentId = hookData["agent_id"] as? String ?? ""
            return agentId.isEmpty
        }
    }

    /// What this event says about the session's *subagents*, which
    /// ``setsTurnState(_:hookData:)`` deliberately refuses to hear.
    ///
    /// - `1` — a subagent did something, so stamp `sessions.subagent_activity_at`.
    ///   Every hook a subagent fires carries its `agent_id`, and a working one fires
    ///   them constantly: measured over a week of real capture, the median gap
    ///   between one subagent's tool hooks is 1s and the 99th percentile is 67s.
    /// - `-1` — a `SubagentStop`, which is **terminal**: one per subagent, not one
    ///   per turn (1.03 rows per distinct `agent_id` across 121,075 of them). So it
    ///   clears the stamp outright rather than ageing out. With two subagents in
    ///   flight one finishing clears both, and the survivor's next hook re-stamps
    ///   within seconds — a self-healing blink, against a false "working" that would
    ///   otherwise outlive the work by the whole freshness window.
    /// - `-1` too for a subagent's `StopFailure` (one carrying an `agent_id`): a
    ///   subagent the API refused — a rate limit, an overload — is just as finished,
    ///   and measured over real capture 94% of them never send a `SubagentStop`, so
    ///   stamping one read the session as working for the whole freshness window
    ///   after its subagent had died.
    /// - `0` — nothing to do with a subagent.
    ///
    /// `SubagentStart` is not enough on its own to track this by counting: it is a
    /// far younger hook than `SubagentStop`, so most subagents on disk have a stop
    /// and no start, and a counter would run permanently negative.
    public static func subagentClock(_ rawEventType: String, hookData: [String: Any]) -> Int {
        if rawEventType == subagentStop.rawValue { return -1 }
        let agentId = hookData["agent_id"] as? String ?? ""
        if agentId.isEmpty { return 0 }
        return rawEventType == stopFailure.rawValue ? -1 : 1
    }

    /// The SQLite table name for this event type's detail rows.
    public var tableName: String {
        // Convert CamelCase to snake_case and append "_events"
        let name = rawValue
        var result = ""
        for (index, char) in name.enumerated() {
            if char.isUppercase && index > 0 { result += "_" }
            result += char.lowercased()
        }
        return result + "_events"
    }
}
