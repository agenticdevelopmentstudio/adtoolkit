import Foundation

/// The AI-summaries tuning knobs, shared by the app's settings panel and the
/// daemon's summarizer so the two can't drift.
///
/// The app owns the values (they live in `UserSettings` and are pushed over XPC);
/// the daemon persists them in its settings table under ``SummarySettingsKeys`` and
/// falls back to these defaults for anything never pushed. Because both sides read
/// the same constants, the panel's "Reset to Defaults" lands exactly where a daemon
/// that has never been configured already sits.
public enum SummaryDefaults {

    /// Substituted with the effective max-word count wherever it appears in
    /// ``prompt``. A user-edited prompt that drops the placeholder keeps whatever
    /// wording it has — the word cap still applies to the *reply*, but the model is
    /// no longer told about it. Explicit beats a hidden sentence appended behind
    /// the user's back.
    public static let maxWordsPlaceholder = "{maxWords}"

    /// The system prompt template. Edited verbatim in Settings → AI Summaries.
    public static let prompt = """
        You write a title of at most \(maxWordsPlaceholder) words for a coding session. \
        Start with a verb ending in -ing. \
        Be brief and plain — no jargon, no technical detail, no explanation. \
        NEVER ask questions. NEVER explain. NEVER say you lack context. \
        If the activity is unclear, make your best guess from what is there. \
        Output ONLY the short phrase and nothing else. \
        Examples: "fixing the sessions window UI", "adding keyboard shortcuts", \
        "cleaning up old code", "exploring the codebase".
        """

    /// Hard cap on the title's word count — told to the model via the placeholder
    /// *and* enforced on the reply, since a small local model routinely overruns it.
    public static let maxWords = 8
    /// How many of the session's most recent events go into the prompt.
    public static let activityLines = 60
    /// Per-event detail cap inside the prompt (data minimization + prompt size).
    public static let detailChars = 120
    /// How often the daemon looks for sessions that still need a summary.
    public static let intervalMinutes = 5
    /// How many sessions one pass summarizes, so a backlog drains gently rather
    /// than bursting a pile of model calls at once.
    public static let maxPerRun = 5
    /// Per-completion budget. Local models on a cold load need more than a cloud API.
    public static let timeoutSeconds = 60

    /// Belt-and-braces character cap for a title, for a reply that is one enormous
    /// "word" (a pasted path, a wall of punctuation): ~10 characters per allowed
    /// word. **The startup purge of overlong summaries must use this same number** —
    /// a purge threshold below the cap wipes titles the summarizer just wrote and
    /// re-queues them forever (they come back the same length), so the two live here
    /// together rather than as two literals that can drift.
    public static func characterCap(maxWords: Int) -> Int { max(80, maxWords * 10) }
}

/// Accepted ranges for the tuning knobs. Both sides clamp through these, so an
/// out-of-range value from an older app (or a hand-rolled HTTP POST) lands on a
/// sane number instead of wedging the summarizer.
public enum SummaryLimits {
    public static let maxWords = 4...20
    public static let activityLines = 10...400
    public static let detailChars = 40...500
    public static let intervalMinutes = 1...240
    public static let maxPerRun = 1...50
    public static let timeoutSeconds = 10...600

    public static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(range.upperBound, max(range.lowerBound, value))
    }
}

/// The daemon settings-table keys the summaries preferences persist under. Named
/// here (rather than in the daemon) so the wire contract and the storage contract
/// are read from one file.
public enum SummarySettingsKeys {
    public static let prompt = "ai_summary_prompt"
    public static let maxWords = "ai_summary_max_words"
    public static let activityLines = "ai_summary_activity_lines"
    public static let detailChars = "ai_summary_detail_chars"
    public static let intervalMinutes = "ai_summary_interval_minutes"
    public static let maxPerRun = "ai_summary_max_per_run"
    public static let timeoutSeconds = "ai_summary_timeout_seconds"
}
