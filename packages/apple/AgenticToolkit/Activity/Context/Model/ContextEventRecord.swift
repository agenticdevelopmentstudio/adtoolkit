import Foundation

/// A stored ``ContextEvent`` plus the monotonic position it occupies in the
/// log.
///
/// `sequence` is the cursor a tailing reader carries between polls: ask for
/// everything after the highest sequence already seen and you get exactly the
/// rows written since, with no duplicates and no gaps. It is deliberately a
/// plain `Int64` in the domain rather than "the SQLite rowid" — the store
/// happens to source it from `rowid` today (`context_event` is an ordinary
/// rowid table, so every insert gets a monotonically increasing one from the
/// single serialized writer), but a future backend on another platform only
/// has to supply *some* monotonic per-insert number, not SQLite's.
///
/// Not `occurred_at`: two events can share a timestamp, and a clock that
/// steps backwards would make a timestamp cursor skip rows. A sequence
/// cannot.
public struct ContextEventRecord: Sendable, Equatable, Codable {
    public let sequence: Int64
    public let event: ContextEvent

    public init(sequence: Int64, event: ContextEvent) {
        self.sequence = sequence
        self.event = event
    }
}

/// What a reader wants out of the context-event log.
///
/// Two modes, distinguished by ``afterSequence``:
///
/// - `nil` — **backfill**: the newest ``limit`` records. Returned in
///   ascending sequence, which is display order for a log that grows
///   downward.
/// - non-`nil` — **tail**: every record with a sequence strictly greater than
///   the cursor, ascending, capped at ``limit``.
///
/// Both modes answer in the same order so a caller can append either result
/// to the same buffer without re-sorting.
///
/// **Ascending sequence, not ascending `occurredAt`** — the order rows were
/// recorded in, which is very nearly but not exactly the order they happened
/// in. The two can differ: a trigger that reports a moment slightly after the
/// fact lands after a row with an earlier sequence and a later timestamp.
///
/// Sequence wins because the cursor is a sequence. Sorting a page by
/// `occurredAt` and then carrying its highest *sequence* forward would let a
/// tailing reader step over rows it never returned — the page would end on a
/// row whose sequence exceeds rows still unread. A reader that wants
/// chronological order has the timestamps and can sort the buffer it is
/// building; a reader that wants to not miss rows cannot recover from this
/// one.
public struct ContextEventQuery: Sendable, Equatable, Codable {
    /// Kinds to include. `nil` means every kind; an empty array means none
    /// and is answered with no rows (a filter that selects nothing is a
    /// legitimate UI state, not a caller error).
    public var kinds: [ContextEventKind]?

    /// Exclusive lower bound on ``ContextEventRecord/sequence``. `nil`
    /// requests the newest page instead.
    public var afterSequence: Int64?

    /// Restricts the page to one local calendar day, `"YYYY-MM-DD"`. `nil`
    /// means every day. A key that does not parse matches nothing, rather
    /// than silently widening to the whole log.
    ///
    /// A day is bounded and is read from its start, so setting this also
    /// makes the page ascend by sequence, beginning with the first row
    /// recorded that day, rather than returning the day's newest rows — see
    /// ``ContextStore/events(_:)``.
    public var day: String?

    /// Upper bound on returned rows. Clamped to at least 0 by the store; a
    /// caller asking for 0 gets nothing rather than an error.
    public var limit: Int

    public init(kinds: [ContextEventKind]? = nil,
                afterSequence: Int64? = nil,
                day: String? = nil,
                limit: Int = ContextEventQuery.defaultLimit) {
        self.kinds = kinds
        self.afterSequence = afterSequence
        self.day = day
        self.limit = limit
    }

    /// One screenful of scrollback with room to scroll. Chosen to match the
    /// page a log window backfills on open; nothing in the store depends on
    /// it.
    public static let defaultLimit = 500

    /// Hard ceiling applied by the store regardless of what a caller asks
    /// for. The log reader crosses a process boundary (the daemon answers
    /// over XPC by serializing the whole page), so an unbounded `limit` is a
    /// client-supplied memory bill on the daemon.
    public static let maximumLimit = 2_000

    /// The number of rows the store will actually return: ``limit`` floored
    /// at 0 and capped at ``maximumLimit``.
    ///
    /// Public because it is the only number a caller may compare
    /// ``ContextEventPage/examined`` against. Comparing against ``limit``
    /// itself looks right and is wrong the moment a caller asks for more than
    /// the ceiling: the page can never reach the request, so "did a full page
    /// come back?" answers `false` forever and a drain loop stops after its
    /// first page on every tick.
    public var effectiveLimit: Int {
        min(max(limit, 0), ContextEventQuery.maximumLimit)
    }
}

/// One page of log reads: the records that decoded, plus enough bookkeeping
/// for a tailing reader to advance past the ones that did not.
///
/// A bare `[ContextEventRecord]` cannot express "I looked at 500 rows and none
/// of them decoded". A reader that advanced its cursor from the returned
/// records alone would then re-read those same unreadable rows forever and
/// never see anything written after them. ``nextSequence`` is taken *before*
/// any row is dropped, so paging always moves; ``examined`` counts the rows
/// the page actually covered, so "is there more?" is answered by rows read
/// rather than by rows that survived.
///
/// Same contract as ``UsageStore/segments(sinceRowID:limit:)`` one layer over.
public struct ContextEventPage: Sendable, Equatable, Codable {
    /// The records that decoded, in ascending sequence.
    public let records: [ContextEventRecord]

    /// Log rows this page covered, including any dropped as malformed. Equal
    /// to the query's effective limit exactly when more rows may follow.
    public let examined: Int

    /// The highest sequence examined, or `nil` when the page was empty. A
    /// tailing reader carries this forward, not `records.last?.sequence`.
    public let nextSequence: Int64?

    public init(records: [ContextEventRecord], examined: Int, nextSequence: Int64?) {
        self.records = records
        self.examined = examined
        self.nextSequence = nextSequence
    }

    /// The answer to a query that cannot match anything (no kinds, zero
    /// limit) — distinct from "we could not look", which callers spell `nil`.
    public static let empty = ContextEventPage(records: [], examined: 0, nextSequence: nil)

    /// Whether rows beyond this page may still be waiting — the question every
    /// tail-draining reader asks between round trips.
    ///
    /// Lives here rather than in each reader because it is a rule about the
    /// page, not about any one window, and because both readers that need it
    /// are in the app target, where nothing can test them.
    public func mayHaveMore(after query: ContextEventQuery) -> Bool {
        examined >= query.effectiveLimit && nextSequence != nil
    }
}
