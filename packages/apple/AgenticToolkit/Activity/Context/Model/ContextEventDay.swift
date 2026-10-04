import Foundation

/// Formats and parses the `"YYYY-MM-DD"` keys that identify a local calendar
/// day throughout the timeline: in ``ContextEventQuery/day``, in
/// ``ContextEventDay/day``, and across the XPC boundary.
///
/// A string rather than a `Date` because a `Date` would have to *mean* "local
/// midnight" with nothing in the type enforcing it, would round-trip through
/// JSON as an instant, and would make "which day is this?" a computation
/// rather than a value.
public enum ContextEventDayKey {

    /// `en_US_POSIX` and a fixed format, deliberately: this string is compared
    /// against `date(occurred_at, 'localtime')` output from SQLite, and a
    /// locale that rendered a Buddhist or Japanese year would not match it.
    private static func makeFormatter(_ calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    public static func key(for date: Date, calendar: Calendar = .current) -> String {
        makeFormatter(calendar).string(from: date)
    }

    /// Local midnight beginning `key`, or `nil` when `key` is not a date.
    public static func startOfDay(_ key: String, calendar: Calendar = .current) -> Date? {
        guard let parsed = makeFormatter(calendar).date(from: key) else { return nil }
        return calendar.startOfDay(for: parsed)
    }

    /// Local midnight beginning the *following* day — the exclusive upper
    /// bound. `Calendar.date(byAdding:)` rather than `+86400` so a DST
    /// transition day is 23 or 25 hours long, as it actually is.
    public static func endOfDay(_ key: String, calendar: Calendar = .current) -> Date? {
        guard let start = startOfDay(key, calendar: calendar) else { return nil }
        return calendar.date(byAdding: .day, value: 1, to: start)
    }
}

/// One local calendar day that has events, and how many.
///
/// The day list is built from these, so a day with no rows never appears —
/// which is what makes "select a day" always land on something to show.
public struct ContextEventDay: Sendable, Equatable, Codable {
    /// `"YYYY-MM-DD"` in the reading machine's timezone.
    public let day: String
    public let count: Int

    public init(day: String, count: Int) {
        self.day = day
        self.count = count
    }
}
