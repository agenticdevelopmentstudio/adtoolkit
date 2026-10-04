#if canImport(AgenticToolkitDatabase)
import Foundation
import AgenticToolkitDatabase
import GRDB

/// Owns the context-tracking schema and all writes into it.
///
/// A header row (`context_event`) plus exactly one typed detail row per event,
/// written in one transaction. Individual typed columns rather than a JSON
/// payload, because these columns need indexes.
public final class ContextStore: Sendable {
    /// Internal, not private: `ContextStore+Read` is the reader half of this
    /// type and lives in its own file.
    let database: BoundedDatabase
    public init(database: BoundedDatabase) { self.database = database }

    // One shared format for every store (M-2); fresh formatter per call
    // because ISO8601DateFormatter is not Sendable and BoundedDatabase runs
    // readers concurrently. See `ISO8601Timestamp`.
    private func s(_ d: Date) -> String { ISO8601Timestamp.string(from: d) }

    // MARK: - Schema

    /// Brings the whole database up to date, not just the context tables.
    ///
    /// The SQL lives in ``OlyloSchema`` — one registry for every store sharing
    /// this file and its `schema_migrations` table. Kept as a method here (and
    /// on the other stores) so the many callers that open a database and
    /// migrate through whichever store they need keep working unchanged.
    public func runMigrations() throws {
        try OlyloSchema.migrate(database)
    }

    // MARK: - Machines

    /// `first_seen_at` is written once and never overwritten; the mutable facts
    /// (hostname, model, OS version) refresh on every launch because they
    /// change under the same device. `last_seen_at` is monotonic — an
    /// out-of-order or replayed call with an older `seenAt` must not walk it
    /// backward, so the update takes `MAX` of the stored and incoming values
    /// (safe because both are fixed-width ISO-8601 UTC TEXT, which sort
    /// lexicographically the same as chronologically).
    public func upsertMachine(_ machine: MachineDescriptor, seenAt: Date) throws {
        let now = s(seenAt)
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO machine (id, platform, native_id, native_id_kind, hostname, model,
                                     os_version, first_seen_at, last_seen_at)
                VALUES (?,?,?,?,?,?,?,?,?)
                ON CONFLICT(id) DO UPDATE SET
                  platform = excluded.platform, native_id = excluded.native_id,
                  native_id_kind = excluded.native_id_kind, hostname = excluded.hostname,
                  model = excluded.model, os_version = excluded.os_version,
                  last_seen_at = MAX(last_seen_at, excluded.last_seen_at)
                """, arguments: [machine.id.uuidString, machine.platform.rawValue,
                                 machine.nativeID, machine.nativeIDKind?.rawValue,
                                 machine.hostname, machine.model, machine.osVersion, now, now])
        }
    }

    /// Records that two device rows are the same person's. Deliberately a
    /// side table: joining never rewrites `context_event.machine_id`, so the
    /// original attribution of every event survives.
    public func linkMachines(_ a: UUID, _ b: UUID, at when: Date, note: String?) throws {
        try database.write { db in
            try db.execute(sql: """
                INSERT OR REPLACE INTO machine_link (machine_id, linked_machine_id, linked_at, note)
                VALUES (?,?,?,?)
                """, arguments: [a.uuidString, b.uuidString, s(when), note])
        }
    }

    // MARK: - Events

    /// Ordering, for anyone querying this log later (M-3):
    /// `ORDER BY occurred_at, rowid`.
    ///
    /// `occurred_at` now carries fractional seconds (`ISO8601Timestamp`), so
    /// events milliseconds apart are ordered by the timestamp alone. Two
    /// events that genuinely share a timestamp are still ordered, because
    /// `context_event` is an ordinary rowid table — `id` is a random UUID and
    /// is useless for ordering, but SQLite's implicit `rowid` is assigned
    /// monotonically per insert and every insert here happens in one
    /// serialized writer. No sequence column is needed and none was added.
    ///
    /// Databases written before fractional seconds were adopted hold a mix of
    /// the two shapes in this column, and a mixed column sorts incorrectly as
    /// text (`"…00.500Z" < "…00Z"`). That is accepted pre-release rather than
    /// migrated; the mix stops growing from this change onward.
    public func insert(_ event: ContextEvent) throws {
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO context_event (id, machine_id, occurred_at, kind, capture_span_id)
                VALUES (?,?,?,?,NULL)
                """, arguments: [event.id.uuidString, event.machineID.uuidString,
                                 s(event.occurredAt), event.kind.rawValue])
            try insertDetail(event.detail, eventID: event.id, into: db)
        }
    }

    private func insertDetail(_ detail: ContextEventDetail, eventID: UUID, into db: Database) throws {
        let eid = eventID.uuidString
        switch detail {
        case .appFocus(let d):
            try db.execute(sql: """
                INSERT INTO context_event_app_focus
                (event_id, bundle_id, app_name, pid, executable_path, window_id, window_title,
                 document_path, document_size, document_modified_at, document_type, url)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
                """, arguments: [eid, d.bundleID, d.appName, d.pid, d.executablePath,
                                 d.windowID, d.windowTitle, d.documentPath, d.documentSize,
                                 d.documentModifiedAt.map(s), d.documentType, d.url])
        case .window(let d):
            try db.execute(sql: """
                INSERT INTO context_event_window
                (event_id, change, bundle_id, app_name, pid, window_id, window_title)
                VALUES (?,?,?,?,?,?,?)
                """, arguments: [eid, d.change.rawValue, d.bundleID, d.appName, d.pid,
                                 d.windowID, d.windowTitle])
        case .network(let d):
            try db.execute(sql: """
                INSERT INTO context_event_network
                (event_id, interface_type, is_satisfied, ssid, bssid, is_expensive, is_constrained)
                VALUES (?,?,?,?,?,?,?)
                """, arguments: [eid, d.interfaceType.rawValue, d.isSatisfied, d.ssid, d.bssid,
                                 d.isExpensive, d.isConstrained])
        case .location(let d):
            try db.execute(sql: """
                INSERT INTO context_event_location
                (event_id, latitude, longitude, horizontal_accuracy, altitude,
                 vertical_accuracy, speed, course)
                VALUES (?,?,?,?,?,?,?,?)
                """, arguments: [eid, d.latitude, d.longitude, d.horizontalAccuracy, d.altitude,
                                 d.verticalAccuracy, d.speed, d.course])
        case .input(let d):
            try db.execute(sql: """
                INSERT INTO context_event_input
                (event_id, change, idle_seconds, seconds_since_key, seconds_since_mouse_move,
                 seconds_since_click, seconds_since_scroll, key_count_delta, mouse_count_delta,
                 interval_ms)
                VALUES (?,?,?,?,?,?,?,?,?,?)
                """, arguments: [eid, d.change.rawValue, d.idleSeconds, d.secondsSinceKey,
                                 d.secondsSinceMouseMove, d.secondsSinceClick, d.secondsSinceScroll,
                                 d.keyCountDelta, d.mouseCountDelta, d.intervalMs])
        case .session(let d):
            try db.execute(sql: "INSERT INTO context_event_session (event_id, change) VALUES (?,?)",
                           arguments: [eid, d.change.rawValue])
        case .power(let d):
            try db.execute(sql: """
                INSERT INTO context_event_power (event_id, source, percent, is_charging)
                VALUES (?,?,?,?)
                """, arguments: [eid, d.source.rawValue, d.percent, d.isCharging])
        case .appLifecycle(let d):
            try db.execute(sql: """
                INSERT INTO context_event_app_lifecycle
                (event_id, change, bundle_id, app_name, pid)
                VALUES (?,?,?,?,?)
                """, arguments: [eid, d.change.rawValue, d.bundleID, d.appName, d.pid])
        }
    }

    public func eventCount(kind: ContextEventKind?) throws -> Int {
        try database.read { db in
            if let kind {
                return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM context_event WHERE kind = ?",
                                        arguments: [kind.rawValue]) ?? 0
            }
            return try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM context_event") ?? 0
        }
    }
}
#endif
