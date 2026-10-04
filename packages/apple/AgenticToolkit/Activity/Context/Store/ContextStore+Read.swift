#if canImport(AgenticToolkitDatabase)
import Foundation
import AgenticToolkitDatabase
import GRDB

/// Reading the context-event log back out.
///
/// Kept beside the writer but in its own file: `ContextStore` owns the
/// schema and the insert path, and a reader that grows filters, cursors and
/// per-kind hydration has a different reason to change than the schema does.
///
/// The shape is a page plus a cursor, not a stream. Everything a log window
/// needs — backfill on open, then "what arrived since?" on a timer — is two
/// calls to the same method with a different ``ContextEventQuery/afterSequence``,
/// which keeps this store free of any subscription machinery it would have to
/// keep alive across a process boundary.
extension ContextStore {

    /// Fetches a page of events with their detail rows attached.
    ///
    /// Two round trips at most per kind present in the page: one header
    /// query against `context_event`, then one `WHERE event_id IN (…)` per
    /// distinct kind. Deliberately not an eight-way `LEFT JOIN` — that pays
    /// for every detail table on every read and returns 40-odd mostly-NULL
    /// columns per row, where this pays only for the kinds actually present.
    ///
    /// An event whose detail row is missing is **dropped**, not returned
    /// half-built: `ContextEvent` requires a detail by construction, and a
    /// header without one is a torn write that never happens (both rows go in
    /// one transaction) or a hand-edited database. Silently skipping it keeps
    /// the caller's model total.
    ///
    /// Dropping is why the answer is a ``ContextEventPage`` and not a bare
    /// array: the page carries the highest sequence *examined*, taken before
    /// anything is dropped, so a tailing reader advances past unreadable rows
    /// instead of re-reading them forever. Same contract as
    /// ``UsageStore/segments(sinceRowID:limit:)``.
    public func events(_ query: ContextEventQuery) throws -> ContextEventPage {
        let limit = query.effectiveLimit
        guard limit > 0 else { return .empty }
        if let kinds = query.kinds, kinds.isEmpty { return .empty }

        return try database.read { db in
            var conditions: [String] = []
            var arguments: [any DatabaseValueConvertible] = []

            if let kinds = query.kinds {
                let slots = Array(repeating: "?", count: kinds.count).joined(separator: ",")
                conditions.append("kind IN (\(slots))")
                arguments.append(contentsOf: kinds.map(\.rawValue))
            }
            // A cursor means "tail forward from here", and a day is bounded
            // and read from its start — both want the *earliest recorded*
            // unseen rows. Only a cursor-less, day-less backfill wants the
            // newest page. Both modes hand rows back in ascending sequence
            // (see below), so a caller appends either result to the same
            // buffer.
            //
            // `rowid`, never `occurred_at`: the cursor this page hands back is
            // a sequence, and a page ordered by one column while paged by
            // another skips rows. `ContextEventQuery` states the rule.
            let isAscending = query.afterSequence != nil || query.day != nil
            if let after = query.afterSequence {
                conditions.append("rowid > ?")
                arguments.append(after)
            }
            if let day = query.day {
                // SQLite decides what local day a timestamp belongs to, here
                // and in `eventDays()` alike. There is exactly one authority
                // on that question and this is it.
                //
                // These bounds used to be computed in Swift, from
                // `ContextEventDayKey` and so from `Calendar.current`, while
                // the day list grouped by `date(occurred_at, 'localtime')`.
                // Those read two independently cached copies of the machine's
                // timezone — Foundation's and the C library's — inside one
                // process. They agree right up until the zone changes under a
                // long-lived daemon (travel, or a manual change), and then a
                // day's rows are hours away from the day the list files them
                // under and simply do not come back.
                //
                // Still bounds rather than `date(occurred_at, 'localtime') = ?`
                // so `idx_ctx_evt_occurred` stays usable: a function applied
                // to the indexed column would disable it, whereas these two
                // are constant for the whole query.
                //
                // The format string is `ISO8601Timestamp`'s exact shape,
                // fractional seconds and trailing `Z` included, because
                // `occurred_at` is TEXT and the comparison is lexical.
                // `datetime()` alone yields `YYYY-MM-DD HH:MM:SS`, which
                // compares against nothing in this column.
                //
                // A `day` that is not a date makes `strftime` answer NULL, and
                // every comparison against NULL is NULL, so a malformed key
                // matches no rows — the same contract `ContextEventQuery/day`
                // documents, now enforced by SQLite rather than by a guard.
                conditions.append("""
                    occurred_at >= strftime('%Y-%m-%dT%H:%M:%fZ', ? || ' 00:00:00', 'utc') \
                    AND occurred_at < strftime('%Y-%m-%dT%H:%M:%fZ', ? || ' 00:00:00', \
                    '+1 day', 'utc')
                    """)
                arguments.append(day)
                arguments.append(day)
            }
            let whereClause = conditions.isEmpty
                ? ""
                : "WHERE " + conditions.joined(separator: " AND ")
            arguments.append(limit)

            let headers = try Row.fetchAll(db, sql: """
                SELECT rowid AS seq, id, machine_id, occurred_at, kind
                FROM context_event
                \(whereClause)
                ORDER BY rowid \(isAscending ? "ASC" : "DESC")
                LIMIT ?
                """, arguments: StatementArguments(arguments))

            // The backfill query had to sort DESC to take the newest page;
            // flipping here is what makes both modes agree on display order.
            let ordered = Array(isAscending ? headers : headers.reversed())
            // Read the cursor off the raw rows, before hydration can drop any
            // of them. `ordered` ascends by sequence in both modes, so the last
            // row is the highest sequence the page covered.
            let nextSequence: Int64? = ordered.last.flatMap { $0["seq"] }
            return ContextEventPage(records: try Self.hydrate(ordered, in: db),
                                    examined: ordered.count,
                                    nextSequence: nextSequence)
        }
    }

    /// The highest sequence currently in the log, or `nil` when it is empty.
    ///
    /// Lets a reader that does not want any backfill (an empty window the
    /// user asked to start clean) still position its cursor at "now" without
    /// fetching and discarding a page.
    public func latestEventSequence() throws -> Int64? {
        try database.read { db in
            try Int64.fetchOne(db, sql: "SELECT MAX(rowid) FROM context_event")
        }
    }

    /// Every local calendar day that has events, newest first, with its row
    /// count.
    ///
    /// `date(occurred_at, 'localtime')` groups the whole table in SQLite
    /// rather than shipping every row across a process boundary to count it.
    /// This query is a full scan by nature — a `GROUP BY` over everything —
    /// so the index argument that shapes the day filter does not apply, and
    /// it runs once per window open and once per refresh, never per row.
    ///
    /// `'localtime'` resolves against the C library's timezone, which is what
    /// makes this the single authority: ``events(_:)``'s day filter asks
    /// SQLite the same question, in the same process, through the same
    /// library, so the two cannot answer differently. Deciding it in Swift on
    /// either side would reintroduce a second, separately cached copy of the
    /// machine's timezone, and the disagreement that follows a zone change
    /// under a running daemon.
    public func eventDays() throws -> [ContextEventDay] {
        try database.read { db in
            try Row.fetchAll(db, sql: """
                SELECT date(occurred_at, 'localtime') AS day, COUNT(*) AS n
                FROM context_event
                GROUP BY day
                ORDER BY day DESC
                """).compactMap { row in
                // A row whose timestamp SQLite cannot read as a date yields a
                // NULL day; skipped rather than shown as a nameless bucket.
                guard let day: String = row["day"], let count: Int = row["n"] else { return nil }
                return ContextEventDay(day: day, count: count)
            }
        }
    }

    // MARK: - Hydration

    /// Every column read in this method goes through the *optional* `Row`
    /// subscript and a `guard let`, including the ones the schema declares
    /// `NOT NULL`. GRDB's non-optional subscript traps on a NULL, and this
    /// runs inside the daemon: `id` and `event_id` are `TEXT PRIMARY KEY`,
    /// which SQLite has always allowed to be NULL, so one such row would take
    /// down the process that is collecting the data rather than being skipped
    /// like any other undecodable row. Reading uniformly, rather than only
    /// where a NULL is reachable today, keeps a later `NOT NULL` being dropped
    /// from being a crash.
    ///
    /// `decodeDetail` below is the exception, and deliberately: each detail
    /// column it reads non-optionally is declared `NOT NULL` in
    /// `OlyloSchema`, and its property in the model is non-optional to match.
    /// The two lists are checked against each other whenever either changes —
    /// making one column nullable without making its property optional is
    /// what would reintroduce the trap.
    private static func hydrate(_ headers: [Row], in db: Database) throws -> [ContextEventRecord] {
        guard !headers.isEmpty else { return [] }

        var idsByKind: [ContextEventKind: [String]] = [:]
        for header in headers {
            guard let raw: String = header["kind"],
                  let kind = ContextEventKind(rawValue: raw),
                  let id: String = header["id"] else { continue }
            idsByKind[kind, default: []].append(id)
        }

        var details: [String: ContextEventDetail] = [:]
        for (kind, ids) in idsByKind {
            let slots = Array(repeating: "?", count: ids.count).joined(separator: ",")
            let rows = try Row.fetchAll(db, sql: """
                SELECT * FROM \(kind.detailTable) WHERE event_id IN (\(slots))
                """, arguments: StatementArguments(ids))
            let reader = ISO8601Timestamp.makeReader()
            for row in rows {
                guard let eventID: String = row["event_id"] else { continue }
                details[eventID] = decodeDetail(kind: kind, row: row, reader: reader)
            }
        }

        let reader = ISO8601Timestamp.makeReader()
        return headers.compactMap { header -> ContextEventRecord? in
            guard let rawID: String = header["id"],
                  let rawMachine: String = header["machine_id"],
                  let rawOccurred: String = header["occurred_at"],
                  let sequence: Int64 = header["seq"],
                  let id = UUID(uuidString: rawID),
                  let machineID = UUID(uuidString: rawMachine),
                  let occurredAt = reader.date(from: rawOccurred),
                  let detail = details[rawID] else { return nil }
            return ContextEventRecord(
                sequence: sequence,
                event: ContextEvent(id: id, machineID: machineID,
                                    occurredAt: occurredAt, detail: detail))
        }
    }

    /// Column names here are the ones ``ContextStore/insertDetail(_:eventID:into:)``
    /// writes; the two lists are the same contract read from opposite ends.
    private static func decodeDetail(kind: ContextEventKind,
                                     row: Row,
                                     reader: ISO8601Timestamp.Reader) -> ContextEventDetail? {
        switch kind {
        case .appFocus:
            return .appFocus(AppFocusDetail(
                bundleID: row["bundle_id"], appName: row["app_name"], pid: row["pid"],
                executablePath: row["executable_path"], windowID: row["window_id"],
                windowTitle: row["window_title"], documentPath: row["document_path"],
                documentSize: row["document_size"],
                documentModifiedAt: (row["document_modified_at"] as String?).flatMap(reader.date(from:)),
                documentType: row["document_type"], url: row["url"]))
        case .window:
            guard let raw: String = row["change"],
                  let change = WindowChange(rawValue: raw) else { return nil }
            return .window(WindowDetail(
                change: change, bundleID: row["bundle_id"], appName: row["app_name"],
                pid: row["pid"], windowID: row["window_id"], windowTitle: row["window_title"]))
        case .network:
            guard let raw: String = row["interface_type"],
                  let type = NetworkInterfaceType(rawValue: raw) else { return nil }
            return .network(NetworkDetail(
                interfaceType: type, isSatisfied: row["is_satisfied"], ssid: row["ssid"],
                bssid: row["bssid"], isExpensive: row["is_expensive"],
                isConstrained: row["is_constrained"]))
        case .location:
            return .location(LocationDetail(
                latitude: row["latitude"], longitude: row["longitude"],
                horizontalAccuracy: row["horizontal_accuracy"], altitude: row["altitude"],
                verticalAccuracy: row["vertical_accuracy"], speed: row["speed"],
                course: row["course"]))
        case .input:
            // A row with no `change` predates migration 7 and predates the
            // backfill it ran, which can only happen if it was written by an
            // older build against an already-migrated file. It is a periodic
            // sample, the only thing that build produced.
            let change = (row["change"] as String?).flatMap(InputChange.init(rawValue:)) ?? .sample
            return .input(InputDetail(
                change: change,
                idleSeconds: row["idle_seconds"],
                secondsSinceKey: row["seconds_since_key"],
                secondsSinceMouseMove: row["seconds_since_mouse_move"],
                secondsSinceClick: row["seconds_since_click"],
                secondsSinceScroll: row["seconds_since_scroll"],
                keyCountDelta: row["key_count_delta"],
                mouseCountDelta: row["mouse_count_delta"],
                intervalMs: row["interval_ms"]))
        case .session:
            guard let raw: String = row["change"],
                  let change = SessionChange(rawValue: raw) else { return nil }
            return .session(SessionDetail(change: change))
        case .power:
            guard let raw: String = row["source"],
                  let source = PowerSourceKind(rawValue: raw) else { return nil }
            return .power(PowerDetail(
                source: source, percent: row["percent"], isCharging: row["is_charging"]))
        case .appLifecycle:
            guard let raw: String = row["change"],
                  let change = AppLifecycleChange(rawValue: raw) else { return nil }
            return .appLifecycle(AppLifecycleDetail(
                change: change, bundleID: row["bundle_id"], appName: row["app_name"],
                pid: row["pid"]))
        }
    }
}
#endif
