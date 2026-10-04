// `AgenticToolkitDatabase` (this store's `BoundedDatabase`) only ships a
// macOS target in agenticdevelopertoolkit today, so this whole file — like
// `UsageCollector.swift` — is macOS-only. iOS performs no capture at all
// (c9), so `AgenticToolkitActivity-iOS` simply doesn't compile a `UsageStore` type.
#if os(macOS)
import Foundation
import AgenticToolkitDatabase
import GRDB

// Public: `olylod` opens the local database and constructs this directly
// (`UsageStore(database:)`) before handing it to `UsageCollector`'s public
// initializer. Its query/mutation methods below stay internal — only
// `UsageCollector` (same module) and `@testable` tests call them.
public final class UsageStore {
    private let db: BoundedDatabase
    public init(database: BoundedDatabase) { self.db = database }

    // One shared format for every store (M-2), still a fresh formatter per
    // call rather than a shared static: ISO8601DateFormatter is not Sendable
    // under Swift 6 strict concurrency and BoundedDatabase.read can run
    // concurrently across its reader pool. See `ISO8601Timestamp`.
    private func s(_ d: Date) -> String { ISO8601Timestamp.string(from: d) }

    /// Brings the whole database up to date; the usage tables are versions 1
    /// and 4 of ``OlyloSchema``'s single registry.
    ///
    /// This used to be the *only* place versions 1 and 4 were declared, and it
    /// is reached only from `UsageCollector.start()` — so a daemon on which
    /// capture had never been switched on had a database missing two of the
    /// four versions its `schema_migrations` table was numbered against.
    func runMigrations() throws {
        try OlyloSchema.migrate(db)
    }

    func insertSegment(_ seg: FocusSegment) throws {
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO usage_focus_segments
                (id, started_at, ended_at, duration_ms, app_bundle_id, app_name, pid,
                 window_id, window_title, document_path, end_reason)
                VALUES (?,?,?,?,?,?,?,?,?,?,?)
                """, arguments: [seg.id.uuidString, s(seg.startedAt), seg.endedAt.map(s),
                    seg.durationMs, seg.focus.app.bundleID, seg.focus.app.name, seg.focus.app.pid,
                    seg.focus.windowID, seg.focus.title, seg.focus.documentPath,
                    (seg.endReason ?? .collectorStop).rawValue])
        }
    }

    func openSpan(id: UUID, machineID: UUID, startedAt: Date) throws {
        try db.write { db in
            try db.execute(
                sql: "INSERT INTO usage_capture_spans (id, machine_id, started_at, last_heartbeat_at) VALUES (?,?,?,?)",
                arguments: [id.uuidString, machineID.uuidString, s(startedAt), s(startedAt)])
        }
    }
    func heartbeatSpan(id: UUID, at when: Date) throws {
        try db.write { db in
            try db.execute(sql: "UPDATE usage_capture_spans SET last_heartbeat_at = ? WHERE id = ?",
                           arguments: [s(when), id.uuidString])
        }
    }
    func closeSpan(id: UUID, endedAt: Date, reason: String) throws {
        try db.write { db in
            try db.execute(sql: "UPDATE usage_capture_spans SET ended_at = ?, end_reason = ? WHERE id = ?",
                           arguments: [s(endedAt), reason, id.uuidString])
        }
    }
    func closeStaleSpans() throws {
        try db.write { db in
            try db.execute(sql: """
                UPDATE usage_capture_spans SET ended_at = last_heartbeat_at, end_reason = 'stale'
                WHERE ended_at IS NULL
                """)
        }
    }
    func openSpanCount() throws -> Int {
        try db.read { db in try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM usage_capture_spans WHERE ended_at IS NULL") ?? 0 }
    }

    /// Reads one keyset page of segments after `sinceRowID`, together with the
    /// cursor (`nextCursor`) the caller passes as the next `sinceRowID`.
    /// `nextCursor` is the rowid of the last row fetched — including any rows
    /// dropped as malformed below — so paging always advances and never
    /// re-fetches a corrupt row; it is `nil` only when the page came back empty
    /// (no more rows). Returning `[FocusSegment]` alone made the cursor
    /// unrecoverable, so a caller could not page past the first batch.
    func segments(sinceRowID: Int64, limit: Int) throws -> (segments: [FocusSegment], nextCursor: Int64?) {
        try db.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT rowid, * FROM usage_focus_segments WHERE rowid > ? ORDER BY rowid LIMIT ?
                """, arguments: [sinceRowID, limit])
            // One reader for the whole page (created inside this reader's
            // closure, so it stays thread-local and Sendable-safe) rather than
            // allocating a fresh ISO8601DateFormatter per row per date field.
            // Lenient: rows written before fractional seconds were adopted
            // (M-3) are still parsed rather than dropped as malformed below.
            let fmt = ISO8601Timestamp.makeReader()
            // compactMap, not map: skip malformed rows (bad UUID, unparsable
            // timestamp) rather than trapping on a force-unwrap — a single
            // corrupt row must not crash the daemon or fail the whole page.
            let segments = rows.compactMap { r -> FocusSegment? in
                guard let idStr = r["id"] as String?, let id = UUID(uuidString: idStr),
                      let startedStr = r["started_at"] as String?, let started = fmt.date(from: startedStr) else { return nil }
                let ended = (r["ended_at"] as String?).flatMap { fmt.date(from: $0) }
                return FocusSegment(id: id, startedAt: started, endedAt: ended,
                    focus: WindowFocus(app: AppInfo(bundleID: r["app_bundle_id"], name: r["app_name"], pid: r["pid"]),
                        windowID: r["window_id"], title: r["window_title"], documentPath: r["document_path"]),
                    endReason: EndReason(rawValue: r["end_reason"]))
            }
            let nextCursor = rows.last.map { $0["rowid"] as Int64 }
            return (segments, nextCursor)
        }
    }
}
#endif
