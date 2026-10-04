import Foundation

/// The timeline's value-formatting rules: how a duration reads in the Length
/// column, and how an event's clock time reads in the Time column.
///
/// One home for both rather than two single-function enums. `formatted` had
/// this file to itself for exactly one round; the type is one round old with
/// a single call site, so merging now is cheap and merging later — once the
/// window has more call sites to update — would not be.
public enum TimelineFormat {

    /// Whole units only, and never more than two of them: a table column is
    /// read at a glance, and "1h 4m" answers the question that "1h 4m 12s"
    /// buries.
    public static func formatted(duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m \(seconds)s" }
        return "\(seconds)s"
    }

    /// `HH:mm:ss` in the reading machine's local time.
    ///
    /// `en_US_POSIX` and a fixed Gregorian calendar, deliberately: this label
    /// sits next to raw event data in the same window, and a locale that
    /// rendered a 12-hour clock or localized digits would not match it — the
    /// same reasoning ``ContextEventDayKey`` documents for the day-key
    /// format. `calendar` supplies only the time zone; a caller that needs a
    /// pinned zone (tests, a future non-local view) passes one explicitly.
    public static func eventTime(_ date: Date, calendar: Calendar = .current) -> String {
        makeTimeFormatter(calendar).string(from: date)
    }

    private static func makeTimeFormatter(_ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
}
