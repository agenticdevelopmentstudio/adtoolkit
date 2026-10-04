#if canImport(AgenticToolkitDatabase)
import Foundation
import AgenticToolkitDatabase
import GRDB

/// Key/value settings shared between the app and the daemon.
///
/// SQLite rather than `UserDefaults`: `olylod` and `Olylo.app` are separate
/// processes with separate defaults domains, and the settings must be the same
/// settings — the opt-in the user ticks in the app is the opt-in the daemon
/// obeys.
public final class SettingsStore: Sendable {
    private let db: BoundedDatabase
    public init(database: BoundedDatabase) { self.db = database }

    /// Brings the whole database up to date; the settings table is version 3
    /// of ``OlyloSchema``'s single registry.
    public func runMigrations() throws {
        try OlyloSchema.migrate(db)
    }

    // MARK: - Raw access

    public func string(_ key: String) throws -> String? {
        try db.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM settings WHERE key = ?", arguments: [key])
        }
    }

    public func setString(_ key: String, _ value: String) throws {
        try db.write { db in
            try db.execute(sql: "INSERT OR REPLACE INTO settings (key, value) VALUES (?,?)",
                           arguments: [key, value])
        }
    }

    public func bool(_ key: String, default fallback: Bool) throws -> Bool {
        guard let raw = try string(key) else { return fallback }
        return raw == "1"
    }

    public func setBool(_ key: String, _ value: Bool) throws {
        try setString(key, value ? "1" : "0")
    }

    // MARK: - Trigger opt-in

    public static func triggerKey(_ kind: ContextEventKind) -> String {
        "trigger.\(kind.rawValue).enabled"
    }

    /// Defaults to `false`: nothing is captured until the user says so.
    public func isTriggerEnabled(_ kind: ContextEventKind) throws -> Bool {
        try bool(Self.triggerKey(kind), default: false)
    }

    public func setTriggerEnabled(_ kind: ContextEventKind, _ enabled: Bool) throws {
        try setBool(Self.triggerKey(kind), enabled)
    }

    // MARK: - Inactivity threshold

    private static let inactivityThresholdKey = "trigger.input.inactivity_seconds"

    /// How long the machine must be quiet before `InputActivityTrigger`
    /// records that the user has gone.
    ///
    /// Here rather than in the app's `UserSettings` because the daemon obeys
    /// it: a setting the daemon reads lives in the database both processes
    /// share, and a setting only the viewer reads lives in the app's defaults.
    /// The work-block threshold is the other one and goes the other way.
    ///
    /// The default and the limits are ``InactivityThreshold``'s, not this
    /// store's: the panel that edits the value and the trigger that obeys it
    /// need the same numbers and neither can see this file.
    public func inactivityThresholdSeconds() throws -> Int {
        guard let raw = try string(Self.inactivityThresholdKey), let value = Int(raw) else {
            return InactivityThreshold.defaultSeconds
        }
        return InactivityThreshold.clamp(seconds: value)
    }

    public func setInactivityThresholdSeconds(_ seconds: Int) throws {
        try setString(Self.inactivityThresholdKey,
                      String(InactivityThreshold.clamp(seconds: seconds)))
    }

    // MARK: - Machine identity

    private static let machineIDKey = "machine.id"

    /// Mints this device's UUID on first call and returns the same value ever
    /// after. The read-then-maybe-write happens inside a single `db.write`
    /// transaction — `BoundedDatabase.write` runs its body on GRDB's one
    /// serial writer connection inside a transaction, so a second caller
    /// (e.g. the app and the daemon both starting for the first time at once)
    /// blocks until the first transaction commits and then reads back the id
    /// that transaction minted, rather than racing to mint a second one.
    public func machineID() throws -> UUID {
        try db.write { db in
            if let raw = try String.fetchOne(db, sql: "SELECT value FROM settings WHERE key = ?",
                                             arguments: [Self.machineIDKey]),
               let existing = UUID(uuidString: raw) {
                return existing
            }
            // Treat an unparseable stored id as absent and re-mint it. This forks this device's
            // history, but it's preferable to never producing an id at all.
            let minted = UUID()
            try db.execute(sql: "INSERT OR REPLACE INTO settings (key, value) VALUES (?,?)",
                           arguments: [Self.machineIDKey, minted.uuidString])
            return minted
        }
    }
}
#endif
