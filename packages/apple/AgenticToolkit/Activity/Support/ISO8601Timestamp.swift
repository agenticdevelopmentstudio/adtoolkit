import Foundation

/// The one ISO-8601 timestamp format every Olylo store reads and writes.
///
/// Previously three byte-identical `makeFormatter()` copies (`ContextStore`,
/// `SchemaMigrator`, `UsageStore`) each had to stay in agreement about UTC and
/// about format options. They are collapsed here because that agreement is
/// load-bearing, not cosmetic: `occurred_at` / `last_seen_at` are compared and
/// sorted **as text**, and mixing the two ISO-8601 shapes in one column sorts
/// *incorrectly* — `"…00.500Z" < "…00Z"`, because `.` (0x2E) sorts below
/// `Z` (0x5A). One writer means one shape.
///
/// **Fractional seconds are part of the format** (M-3). Without them a burst of
/// events inside the same second is stored with byte-identical timestamps, and
/// their order — the thing the event log exists to reconstruct — is only
/// recoverable from the implicit `rowid` (see `ContextStore.insert`). Unlike
/// data volume, resolution cannot be recovered later: it was never captured.
///
/// Nothing here is a shared instance. `ISO8601DateFormatter` is not `Sendable`,
/// `BoundedDatabase` runs readers concurrently, and every store is `Sendable`,
/// so each call site makes its own short-lived formatter — the same idiom the
/// three copies used, kept deliberately.
public enum ISO8601Timestamp {
    /// A fresh writer. Callers that format many dates in a row (a page of
    /// rows) should hold one of these for the batch rather than calling
    /// ``string(from:)`` per field.
    public static func makeWriter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    /// Formats one date in the canonical shape.
    public static func string(from date: Date) -> String {
        makeWriter().string(from: date)
    }

    /// A fresh reader. Lenient by construction — see ``Reader``.
    public static func makeReader() -> Reader { Reader() }

    /// Parses both shapes: the fractional-second form written today, and the
    /// whole-second form written before fractional seconds were adopted.
    ///
    /// `ISO8601DateFormatter` will not parse a string whose shape disagrees
    /// with its `formatOptions` — a fractional-only parser returns `nil` for
    /// `2026-08-16T12:00:00Z`. Rows in that older shape exist in every
    /// database written before this change, and `UsageStore.segments` drops a
    /// row whose timestamp will not parse, so a strict reader would silently
    /// discard real history. Reading is therefore lenient even though writing
    /// is not.
    public struct Reader {
        private let fractional: ISO8601DateFormatter
        private let wholeSeconds: ISO8601DateFormatter

        init() {
            fractional = ISO8601Timestamp.makeWriter()
            let whole = ISO8601DateFormatter()
            whole.timeZone = TimeZone(identifier: "UTC")
            whole.formatOptions = [.withInternetDateTime]
            wholeSeconds = whole
        }

        public func date(from string: String) -> Date? {
            fractional.date(from: string) ?? wholeSeconds.date(from: string)
        }
    }
}
