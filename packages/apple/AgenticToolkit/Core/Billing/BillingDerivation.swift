import Foundation

/// One continuous stretch of work derived from a session's activity.
/// `endedAt == ""` means still running, in which case `seconds` is 0: a run is
/// only billable once it has closed.
public struct BillingRun: Sendable, Equatable {
    public let startedAt: String
    public let endedAt: String
    public let seconds: Int

    public init(startedAt: String, endedAt: String, seconds: Int) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.seconds = seconds
    }

    public var isOpen: Bool { endedAt.isEmpty }
}

/// Turns a session's activity timestamps into runs.
///
/// Pure by design. Segments are *derived*, never driven by a live state
/// machine, which is why a daemon crash, a reinstall mid-session, a laptop
/// sleep, or a timer nobody stopped all cost nothing: sleep produces a gap, a
/// gap produces a split, and re-deriving the same events produces the same
/// runs. The price is up to one scheduling interval of lag, and a run that is
/// still open is not yet billable.
public enum BillingDerivation {

    /// The cutoff used when the caller supplies a nonsensical one.
    public static let defaultCutoffSeconds = 15 * 60

    /// How late an idle row can land relative to the input it describes: the
    /// input trigger's 60 s threshold plus one 30 s poll. Two idle rows this
    /// close are one absence (a daemon restart splits one in two), and a
    /// closed span younger than this may still gain the row for its tail.
    public static let inputLagSeconds = 90

    /// - Parameters:
    ///   - activityTimestamps: UTC ISO-8601, any order; ambient event types are
    ///     already excluded by the caller (the host decides which events count as activity).
    ///   - sessionStartedAt: used only as a lead-in for the *first* run.
    ///   - sessionIsActive: whether the session is still live.
    ///   - now: the caller's clock, passed in so this stays testable.
    ///   - cutoffSeconds: idle gap that ends a run.
    public static func runs(
        activityTimestamps: [String],
        sessionStartedAt: String,
        sessionIsActive: Bool,
        now: String,
        cutoffSeconds: Int
    ) -> [BillingRun] {
        // Parse, drop anything that isn't a timestamp, de-duplicate, and sort.
        // Whole epoch seconds are what make the order chronological (fractional
        // seconds would otherwise sort before their own whole second as
        // strings). Hooks land out of order often enough that trusting arrival
        // order would produce negative-length runs.
        let seconds = activityTimestamps.compactMap { UTCTimestamp.epochSeconds($0) }
        return runs(
            activitySeconds: Array(Set(seconds)).sorted(),
            sessionStartedAt: sessionStartedAt,
            sessionIsActive: sessionIsActive,
            now: now,
            cutoffSeconds: cutoffSeconds
        )
    }

    /// The same derivation over stamps already parsed to whole epoch seconds,
    /// **sorted ascending and de-duplicated** — the form `BillingActivityCache`
    /// keeps, so a pass over a long session does no parsing at all.
    public static func runs(
        activitySeconds stamps: [Int],
        sessionStartedAt: String,
        sessionIsActive: Bool,
        now: String,
        cutoffSeconds: Int
    ) -> [BillingRun] {
        let cutoff = cutoffSeconds > 0 ? cutoffSeconds : defaultCutoffSeconds
        guard let first = stamps.first else { return [] }

        // Splitting at every gap longer than the cutoff is `ActivityRuns`: a
        // run closes at the PREVIOUS event. The idle stretch is how the stop
        // is detected; it is never billed.
        var spans = ActivityRuns.split(stamps, idleGap: cutoff)
        // The first run may lead in from the session's own start: the minutes
        // spent reading the prompt that caused the first event are real work,
        // and this is the one place there is evidence for them. Later runs get
        // no lead-in — see the spec's head-of-run undercount note.
        // `sessions.started_at` is usually SQLite's space-separated form, which
        // `epochSeconds` accepts.
        if let started = UTCTimestamp.epochSeconds(sessionStartedAt),
           started < first,
           first - started <= cutoff {
            spans[0].start = started
        }
        let last = spans.removeLast()
        var result = spans.map { closed(from: $0.start, to: $0.end) }

        // The last run stays open only if the session is still live and its
        // most recent event is inside the cutoff. Anything else has stopped,
        // whether or not anything told us so. A malformed `now` can't prove
        // recency, so it closes the run rather than leaving it open forever.
        let nowSeconds = UTCTimestamp.epochSeconds(now)
        let stillRunning = sessionIsActive
            && nowSeconds.map { $0 - last.end <= cutoff } == true
        result.append(
            stillRunning
                ? BillingRun(startedAt: UTCTimestamp.string(epochSeconds: last.start), endedAt: "", seconds: 0)
                : closed(from: last.start, to: last.end)
        )
        return result
    }

    /// Splits one app-activity span into runs at its idle gaps.
    ///
    /// An absence of at least `cutoffSeconds` is cut out of the span (an open
    /// idle row counts as idle until `now`); shorter idles stay billed. Idle
    /// rows no more than `inputLagSeconds` apart are one absence, so a restart
    /// that split it into two short rows does not make it billable.
    /// An open span (`spanEnd == ""`) runs to `now`, and its last run stays
    /// open unless an open idle past the cutoff ends it — then it closes at
    /// the idle's start, the last input. Any unparsable timestamp yields no
    /// runs.
    public static func appRuns(
        spanStart: String,
        spanEnd: String,
        idle: [BillingIdleInterval],
        cutoffSeconds: Int,
        now: String
    ) -> [BillingRun] {
        let cutoff = cutoffSeconds > 0 ? cutoffSeconds : defaultCutoffSeconds
        guard let start = UTCTimestamp.epochSeconds(spanStart),
              let nowSeconds = UTCTimestamp.epochSeconds(now) else { return [] }
        let end: Int
        if spanEnd.isEmpty {
            end = nowSeconds
        } else {
            guard let parsed = UTCTimestamp.epochSeconds(spanEnd) else { return [] }
            end = parsed
        }
        guard end > start else { return [] }

        var rows: [ActivityRuns.Span<Int>] = []
        for interval in idle {
            guard let from = UTCTimestamp.epochSeconds(interval.idleFrom) else { return [] }
            let until: Int
            if interval.idleUntil.isEmpty {
                until = nowSeconds
            } else {
                guard let parsed = UTCTimestamp.epochSeconds(interval.idleUntil) else { return [] }
                until = parsed
            }
            if until > from { rows.append(ActivityRuns.Span(start: from, end: until)) }
        }

        // Rows within `inputLagSeconds` of each other are one absence split
        // by a restart: the cutoff applies to the whole absence, the cut only
        // to the rows that recorded it.
        var gaps: [ActivityRuns.Span<Int>] = []
        var cluster: [ActivityRuns.Span<Int>] = []
        for row in ActivityRuns.union(rows) {
            if let first = cluster.first, let last = cluster.last, row.start - last.end > inputLagSeconds {
                if last.end - first.start >= cutoff { gaps += cluster }
                cluster = []
            }
            cluster.append(row)
        }
        if let first = cluster.first, let last = cluster.last, last.end - first.start >= cutoff { gaps += cluster }

        let pieces = ActivityRuns.subtract([ActivityRuns.Span(start: start, end: end)], gaps)

        return pieces.map { piece in
            // A piece reaching `now` on an open span means no gap ends at
            // now: the user is still at it, so the run is still running.
            if spanEnd.isEmpty && piece.end == end {
                return BillingRun(startedAt: UTCTimestamp.string(epochSeconds: piece.start), endedAt: "", seconds: 0)
            }
            return closed(from: piece.start, to: piece.end)
        }
    }

    private static func closed(from start: Int, to end: Int) -> BillingRun {
        BillingRun(
            startedAt: UTCTimestamp.string(epochSeconds: start),
            endedAt: UTCTimestamp.string(epochSeconds: end),
            seconds: max(0, end - start)
        )
    }
}
