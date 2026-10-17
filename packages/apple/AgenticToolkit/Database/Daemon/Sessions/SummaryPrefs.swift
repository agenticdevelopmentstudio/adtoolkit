#if canImport(AgenticToolkitCore)
import Foundation
import AgenticToolkitCore

/// The AI-summaries tuning knobs as the daemon reads them: the prompt, the word
/// cap, how much of a session travels in the prompt, and the schedule.
///
/// Values live in the settings table (written by whatever surface the host exposes
/// for them) and are read
/// *live*, so a change in Settings → AI Summaries takes effect on the next
/// summarization pass with no daemon restart. Anything unset — or stored
/// out of range by an older app or a hand-rolled POST — falls back through
/// ``SummaryDefaults``/``SummaryLimits``, which the app shares, so a daemon that
/// has never been configured behaves exactly like one just reset to defaults.
///
/// Read a ``Snapshot`` once per pass rather than calling the accessors per
/// session: they are global values, and re-reading them around an `await` let one
/// pass prompt with one word count and truncate to another.
public enum SummaryPrefs {

    /// Every knob one summarization needs, read together. Taking them in one go is
    /// what makes a pass internally consistent — and keeps a 50-session pass to 7
    /// settings reads instead of 350.
    public struct Snapshot: Sendable {
        /// The prompt with `{maxWords}` already resolved.
        public let systemPrompt: String
        public let maxWords: Int
        public let activityLines: Int
        public let detailChars: Int
        public let maxTokens: Int
        public let timeout: TimeInterval
        public let maxPerRun: Int

        /// Hard character cap for the stored title. Shared with the startup purge.
        public var characterCap: Int { SummaryDefaults.characterCap(maxWords: maxWords) }
    }

    public static func snapshot(_ database: DaemonDatabase) -> Snapshot {
        let words = maxWords(database)
        return Snapshot(
            systemPrompt: resolvedPrompt(database, maxWords: words),
            maxWords: words,
            activityLines: activityLines(database),
            detailChars: detailChars(database),
            maxTokens: maxTokens(maxWords: words),
            timeout: timeoutSeconds(database),
            maxPerRun: maxPerRun(database)
        )
    }

    /// The raw prompt template, placeholder unresolved. A blank stored value means
    /// "never configured" and yields the default — an empty system prompt would
    /// silently turn a titling model into a chatbot.
    public static func prompt(_ database: DaemonDatabase) -> String {
        let raw = ((try? database.setting(for: SummarySettingsKeys.prompt)) ?? nil) ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? SummaryDefaults.prompt : raw
    }

    /// The prompt with `{maxWords}` resolved. A prompt the user stripped the
    /// placeholder out of is sent verbatim — the cap still trims the *reply*.
    public static func resolvedPrompt(_ database: DaemonDatabase, maxWords resolved: Int? = nil) -> String {
        prompt(database).replacingOccurrences(
            of: SummaryDefaults.maxWordsPlaceholder,
            with: String(resolved ?? maxWords(database))
        )
    }

    public static func maxWords(_ database: DaemonDatabase) -> Int {
        intSetting(database, SummarySettingsKeys.maxWords,
                   default: SummaryDefaults.maxWords, range: SummaryLimits.maxWords)
    }

    public static func activityLines(_ database: DaemonDatabase) -> Int {
        intSetting(database, SummarySettingsKeys.activityLines,
                   default: SummaryDefaults.activityLines, range: SummaryLimits.activityLines)
    }

    public static func detailChars(_ database: DaemonDatabase) -> Int {
        intSetting(database, SummarySettingsKeys.detailChars,
                   default: SummaryDefaults.detailChars, range: SummaryLimits.detailChars)
    }

    public static func intervalMinutes(_ database: DaemonDatabase) -> Int {
        intSetting(database, SummarySettingsKeys.intervalMinutes,
                   default: SummaryDefaults.intervalMinutes, range: SummaryLimits.intervalMinutes)
    }

    /// What `TaskSchedule` wants. `Scheduler` re-reads the task's interval when it
    /// reschedules — i.e. *after the currently armed interval elapses*, so a change
    /// from 4 hours to 1 minute is honored on the tick after the four hours are up,
    /// not immediately. Restarting the daemon applies it at once.
    public static func intervalSeconds(_ database: DaemonDatabase) -> TimeInterval {
        TimeInterval(intervalMinutes(database) * 60)
    }

    public static func maxPerRun(_ database: DaemonDatabase) -> Int {
        intSetting(database, SummarySettingsKeys.maxPerRun,
                   default: SummaryDefaults.maxPerRun, range: SummaryLimits.maxPerRun)
    }

    public static func timeoutSeconds(_ database: DaemonDatabase) -> TimeInterval {
        TimeInterval(intSetting(database, SummarySettingsKeys.timeoutSeconds,
                                default: SummaryDefaults.timeoutSeconds, range: SummaryLimits.timeoutSeconds))
    }

    /// Completion budget for one title. Derived from the word cap rather than
    /// configured separately: the reply is a phrase, and a user who raises the cap
    /// must not have the answer truncated mid-word by a stale token limit.
    public static func maxTokens(_ database: DaemonDatabase) -> Int {
        maxTokens(maxWords: maxWords(database))
    }

    public static func maxTokens(maxWords: Int) -> Int { max(64, maxWords * 8) }

    private static func intSetting(
        _ database: DaemonDatabase, _ key: String, default fallback: Int, range: ClosedRange<Int>
    ) -> Int {
        RawSetting.int((try? database.setting(for: key)) ?? nil, default: fallback, range: range)
    }
}
#endif
