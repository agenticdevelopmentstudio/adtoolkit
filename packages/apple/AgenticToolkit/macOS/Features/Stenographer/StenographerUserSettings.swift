import Foundation
import AgenticToolkitCore
import AIPluginKit

/// The preferences of the Stenographer-fed windows and panes (Sessions,
/// Conversations, AI Oversight, AI Summaries). Keys keep the `stenographer_`
/// prefix they had when these lived in the Stenographer app, so an existing
/// store reads unchanged.
@MainActor
extension UserSettings {

    /// Whether the always-on daemon generates AI summaries for sessions. Toggling
    /// this POSTs `/preferences/summaries` so the daemon's summarizer + SummarizeTask pick
    /// it up. "claude_cli" needs no API key (it uses the local Claude Code login).
    public static let stenographerAISummariesEnabled = UserSetting<Bool>(
        "stenographer_ai_summaries_enabled",
        default: true
    )

    /// The daemon provider configuration AI summaries use, by id; "" = the
    /// daemon's zero-config Claude CLI path. Pushed with the summaries switch
    /// by `StenographerSummaryPrefsPush`.
    public static let stenographerAISummariesProviderConfigId = UserSetting<String>(
        "stenographer_ai_summaries_provider_config_id",
        default: ""
    )

    // MARK: - AI summaries tuning
    //
    // Settings → AI Summaries. The daemon is the one that actually prompts the
    // model, so these are pushed to it by `StenographerSummaryPrefsPush`; the
    // defaults and accepted ranges come from `SummaryDefaults`/`SummaryLimits`,
    // so the panel, the wire, and the daemon's own fallbacks are one set of
    // numbers rather than three.

    /// The system prompt sent with every summarization request.
    /// `SummaryDefaults.maxWordsPlaceholder` in the text is substituted with the
    /// effective word cap; a prompt that drops it simply stops telling the model
    /// about the cap (the reply is still trimmed to it).
    public static let stenographerAISummaryPrompt = UserSetting<String>(
        "stenographer_ai_summary_prompt",
        default: SummaryDefaults.prompt
    )

    /// Word cap for a generated title.
    public static let stenographerAISummaryMaxWords = UserSetting<Int>(
        "stenographer_ai_summary_max_words",
        default: SummaryDefaults.maxWords
    )

    /// How many of a session's most recent events are described to the model.
    public static let stenographerAISummaryActivityLines = UserSetting<Int>(
        "stenographer_ai_summary_activity_lines",
        default: SummaryDefaults.activityLines
    )

    /// Per-event detail cap inside the prompt — bounds how much session content
    /// leaves the machine, and keeps the prompt small.
    public static let stenographerAISummaryDetailChars = UserSetting<Int>(
        "stenographer_ai_summary_detail_chars",
        default: SummaryDefaults.detailChars
    )

    /// How often the daemon looks for sessions that still need a summary.
    public static let stenographerAISummaryIntervalMinutes = UserSetting<Int>(
        "stenographer_ai_summary_interval_minutes",
        default: SummaryDefaults.intervalMinutes
    )

    /// How many sessions one pass summarizes, so a backlog drains gently.
    public static let stenographerAISummaryMaxPerRun = UserSetting<Int>(
        "stenographer_ai_summary_max_per_run",
        default: SummaryDefaults.maxPerRun
    )

    /// Per-request budget. A local model on a cold load needs more than a cloud API.
    public static let stenographerAISummaryTimeoutSeconds = UserSetting<Int>(
        "stenographer_ai_summary_timeout_seconds",
        default: SummaryDefaults.timeoutSeconds
    )

    /// Returns every summaries knob to its default, in one place so the panel's
    /// "Reset to Defaults" button can't drift from the list above.
    ///
    /// Removes rather than re-writes: storing today's `SummaryDefaults` values would
    /// freeze this build's numbers — and this build's prompt wording — into
    /// UserDefaults, so a later release's better default would never reach anyone who
    /// had ever pressed Reset. An absent key reads back as the *current* default.
    public static func resetAISummaryTuning() {
        stenographerAISummaryPrompt.remove()
        stenographerAISummaryMaxWords.remove()
        stenographerAISummaryActivityLines.remove()
        stenographerAISummaryDetailChars.remove()
        stenographerAISummaryIntervalMinutes.remove()
        stenographerAISummaryMaxPerRun.remove()
        stenographerAISummaryTimeoutSeconds.remove()
    }

    /// Whether the always-on daemon runs AI oversight over the live session fleet —
    /// watching for sessions that need attention (e.g. context filling up) and
    /// recording findings. **Opt-in** (default off): oversight watches (and, in
    /// later phases, acts on) live sessions, so it stays dark until enabled.
    /// The daemon persists the setting, so it survives daemon restarts without a
    /// re-push.
    public static let stenographerAIOversightEnabled = UserSetting<Bool>(
        "stenographer_ai_oversight_enabled",
        default: false
    )

    /// Whether oversight observers consult the model for judgment (vs. the raw
    /// rule alone). **Opt-in** (default off) — mirrors the daemon's
    /// `oversight_llm_enabled`; `StenographerOversightPrefsPush` pushes it.
    public static let stenographerAIOversightLLMEnabled = UserSetting<Bool>(
        "stenographer_ai_oversight_llm_enabled",
        default: false
    )

    /// Which provider configuration oversight completions use. "" = inherit the
    /// AI Summaries selection (the pre-existing behavior); "claude-cli" forces the
    /// zero-config CLI path; anything else is a configuration UUID.
    public static let stenographerAIOversightProviderConfigId = UserSetting<String>(
        "stenographer_ai_oversight_provider_config_id",
        default: ""
    )

    /// Whether this store has taken the AI summaries values from the daemon once.
    /// The daemon holds the only copy of what the user chose before these panes
    /// moved to a new app, so the first push reads them instead of overwriting
    /// them with this build's defaults. Set by `StenographerSummaryPrefsPush`.
    public static let stenographerAISummariesSeededFromDaemon = UserSetting<Bool>(
        "stenographer_ai_summaries_seeded_from_daemon",
        default: false
    )

    /// Whether this store has taken the AI oversight values from the daemon once;
    /// the oversight counterpart of ``stenographerAISummariesSeededFromDaemon``.
    /// Set by `StenographerOversightPrefsPush`.
    public static let stenographerAIOversightSeededFromDaemon = UserSetting<Bool>(
        "stenographer_ai_oversight_seeded_from_daemon",
        default: false
    )

    /// The oversight model override for one daemon provider configuration; ""
    /// means "the configuration's own model".
    public static func oversightModelSetting(config id: UUID) -> UserSetting<String> {
        UserSetting<String>("stenographer_oversight_model.\(id.uuidString)", default: "")
    }

    /// Whether the Sessions window floats above all other windows.
    public static let stenographerSessionsWindowAlwaysOnTop = UserSetting<Bool>(
        "stenographer_sessions_window_always_on_top",
        default: false
    )

    /// Whether the Conversations window floats above all other windows.
    public static let stenographerConversationsAlwaysOnTop = UserSetting<Bool>(
        "stenographer_conversations_window_always_on_top",
        default: false
    )

    /// Whether the Conversations window shows the agent's work output — its
    /// narration of what it is doing, and its thinking — alongside what it
    /// actually said to the human.
    ///
    /// Off by default, and that is what makes the window readable: measured
    /// against live transcripts, narration outnumbers replies and runs far
    /// shorter, so showing it by default buries the conversation in "let me
    /// check X".
    public static let stenographerConversationsShowWorkOutput = UserSetting<Bool>(
        "stenographer_conversations_show_work_output",
        default: false
    )

    /// The sessions the Conversations window is not drawing, by session id —
    /// the shelf's unticked boxes.
    ///
    /// Persisted for the same reason the work-output filter is: a filter that
    /// forgets itself when the window closes has to be set again every time,
    /// and the reader who hid four noisy sessions to follow a fifth hid them
    /// for as long as that is what they are doing, not for as long as the
    /// window happens to be open. Ids of sessions that never come back are
    /// harmless — nothing in the shelf matches them, so nothing is hidden.
    public static let stenographerConversationsHiddenSessions = UserSetting<Set<String>>(
        "stenographer_conversations_hidden_sessions",
        default: []
    )

    /// Whether the Conversations window reads one conversation at a time
    /// rather than several merged onto one timeline.
    ///
    /// Stored as a flag rather than as the mode itself so the key is one a
    /// defaults dump reads plainly, and because the two modes are what the enum
    /// is: a third would be a new setting, not a new case.
    ///
    /// Off by default: the merged feed is what this window is for, and single
    /// mode is the narrowing a reader asks for once they have found the
    /// conversation they want to follow.
    public static let stenographerConversationsSingleMode = UserSetting<Bool>(
        "stenographer_conversations_single_mode",
        default: false
    )

    /// The session single mode was reading, by id; empty for none.
    ///
    /// Persisted beside the mode because the two are one answer: single mode
    /// restored onto whichever session happened to come first is the window
    /// forgetting what the reader was following. An id whose session never
    /// comes back is harmless — the shelf replaces a pick it cannot find.
    public static let stenographerConversationsSoloSession = UserSetting<String>(
        "stenographer_conversations_solo_session",
        default: ""
    )

    /// Sessions window opacity (0.3 = highly transparent, 1.0 = opaque).
    public static let stenographerSessionsWindowTransparency = UserSetting<Double>(
        "stenographer_sessions_window_transparency",
        default: 1.0
    )

    /// Sessions-window time filter: show sessions active within the last N
    /// hours (any status). 0 = no time filter (all sessions).
    public static let stenographerSessionsFilterHours = UserSetting<Int>(
        "stenographer_sessions_filter_hours",
        default: 24
    )
}
