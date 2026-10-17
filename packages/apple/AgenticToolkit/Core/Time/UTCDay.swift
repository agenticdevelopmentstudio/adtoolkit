import Foundation

/// UTC calendar-day helpers shared by the rollup and the usage projections.
///
/// All day bucketing in the daemon is UTC (`substr(timestamp, 1, 10)` on stored
/// ISO-8601 timestamps), so day strings produced in Swift must use the same
/// fixed UTC calendar — otherwise the host's locale or time zone could shift a
/// boundary. The civil-date arithmetic is Core's `UTCTimestamp`; this is the
/// daemon's UTC-pinned spelling of it.
public enum UTCDay {
    private static let utc = TimeZone(identifier: "UTC")!

    /// The UTC calendar day (`yyyy-MM-dd`) containing `date`.
    public static func string(from date: Date) -> String {
        UTCTimestamp.day(of: date, in: utc)
    }

    /// The day after a `yyyy-MM-dd` (UTC) string. UTC has no DST so +86400s is
    /// exactly one day. Returns the input unchanged if it cannot be parsed
    /// (defensive — callers only ever pass strings this type produced).
    public static func dayAfter(_ day: String) -> String {
        guard let seconds = UTCTimestamp.epochSeconds("\(day)T00:00:00Z") else { return day }
        return UTCTimestamp.day(epochSeconds: seconds + 86_400, in: utc)
    }
}
