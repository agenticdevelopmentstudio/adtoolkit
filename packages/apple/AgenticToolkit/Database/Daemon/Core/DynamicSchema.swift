#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import OSLog
import Foundation
import GRDB

/// Caches per-table column sets and issues ALTER TABLE for unknown scalar fields.
///
/// Calls come from inside a DaemonDatabase write, but the cache is also touched
/// from GRDB's post-transaction callback (see `ensureColumns`), so the dictionary
/// is lock-guarded rather than resting on that single-writer discipline.
public final class DynamicSchema: @unchecked Sendable {

    /// How wide a dynamic table may grow before further columns are refused.
    ///
    /// SQLite's own ceiling is 2000, and reaching it is not a soft landing: the
    /// ALTER fails, `ensureColumns` propagates that, and every event carrying the
    /// unaddable field is quarantined from then on — one runaway field name would
    /// stop the table taking rows at all. A budget well under the ceiling turns
    /// that into logged, dropped fields instead: ingestion keeps working and the
    /// table stays readable. 512 is roughly ten times the widest payload seen
    /// (~55 columns), so it is a backstop for a shape nobody anticipated rather
    /// than a limit real growth is expected to meet.
    public static let maxColumns = 512

    private let lock = NSLock()
    private var columnCache: [String: Set<String>] = [:]
    /// Tables already logged as full, so the refusal is said once per process
    /// rather than on every render.
    private var reportedFull: Set<String> = []

    public init() {}

    // MARK: - Column lookup

    public func columns(for table: String, database: Database) throws -> Set<String> {
        if let cached = lock.withLock({ columnCache[table] }) { return cached }
        // `columns(in:)` throws "no such table" for a table that doesn't exist yet;
        // treat that as no columns (matches the old PRAGMA table_info behaviour).
        let cols = Set((try? database.columns(in: table).map(\.name)) ?? [])
        lock.withLock { columnCache[table] = cols }
        return cols
    }

    // MARK: - Column addition

    /// Ensures all scalar keys in `fields` exist as columns in `table`. Skips nested
    /// objects/arrays (they get their own tables), runs ALTER TABLE for any missing
    /// columns, and updates the in-memory cache.
    ///
    /// Returns the columns the table actually has afterwards — the set a caller
    /// must confine its INSERT to. A key can be missing from it for a benign
    /// reason (an unusable name, the column budget), and an INSERT that named it
    /// anyway would fail with `no such column` and take the caller's whole
    /// transaction with it.
    ///
    /// Throws when a column genuinely could not be added, which is not benign:
    /// the field is one the table is supposed to hold, and swallowing that
    /// leaves the schema quietly wrong.
    @discardableResult
    public func ensureColumns(
        for table: String, fields: [String: Any], database: Database
    ) throws -> Set<String> {
        var known = try columns(for: table, database: database)
        var addedAny = false

        defer {
            lock.withLock { columnCache[table] = known }
            if addedAny {
                // ALTER TABLE is DDL inside the caller's transaction, and SQLite
                // rolls DDL back with everything else. A later step throwing —
                // a BUSY, a deadline ejection — therefore takes the new columns
                // away again, while the cache would go on claiming them: every
                // later event would skip the ALTER and then INSERT into a column
                // that no longer exists, permanently. Drop the table's entry on
                // rollback so the next call re-reads it from the database.
                //
                // GRDB keeps a schema cache of its own, and a writer connection
                // never clears it by itself (only DatabasePool READERS do, per
                // `clearSchemaCacheIfNeeded`). The ALTER refreshed it to the
                // post-ALTER shape and the rollback did not put it back, so
                // re-reading through `columns(in:)` would hand us the very
                // column that no longer exists — this invalidation alone would
                // have accomplished nothing. Clear both.
                database.afterNextTransaction(
                    onCommit: { _ in },
                    onRollback: { [self] database in
                        database.clearSchemaCache()
                        invalidate(table: table)
                    }
                )
            }
        }

        for (key, value) in fields {
            guard !known.contains(key) else { continue }
            if value is [String: Any] || value is [Any] { continue }
            // Belt and braces: `insertDynamic` drops unsafe names before they
            // reach here, but this is also a direct entry point.
            guard Self.isSafeColumnName(key) else { continue }
            guard known.count < Self.maxColumns else {
                reportTableFull(table, refusing: key)
                continue
            }
            let type = Self.affinity(for: value)
            do {
                try database.execute(sql: #"ALTER TABLE "\#(table)" ADD COLUMN "\#(key)" \#(type)"#)
                known.insert(key)
                addedAny = true
                let column = "\(key) \(type)"
                logger.info(
                    "DynamicSchema: added '\(column, privacy: .public)' to '\(table, privacy: .public)'"
                )
            } catch {
                // An ALTER fails benignly when the column already exists (a stale
                // cache, a concurrent add) and fatally when it doesn't — SQLite's
                // 2000-column ceiling, a full disk. Those are not the same
                // failure, and this used to treat them as one: the benign reading
                // was assumed, the key was left out of `known`, and the INSERT
                // that followed named a column that was never created. Ask the
                // database which case this is instead of guessing.
                let actual = Set(try database.columns(in: table).map(\.name))
                known.formUnion(actual)
                guard actual.contains(key) else { throw error }
            }
        }
        return known
    }

    private func reportTableFull(_ table: String, refusing key: String) {
        let fresh = lock.withLock { reportedFull.insert(table).inserted }
        guard fresh else { return }
        let detail = "\(table) is at its \(Self.maxColumns)-column budget, refusing '\(key)'"
        logger.error("DynamicSchema: \(detail, privacy: .public) and any further new field")
    }

    /// True for a key safe to interpolate into a double-quoted SQL identifier.
    ///
    /// Column names here come from payload keys — names Anthropic controls, not
    /// this repo — and both the ALTER above and the INSERT in `insertDynamic`
    /// interpolate them into `"…"` rather than binding them, because an
    /// identifier cannot be a bound parameter. A key holding a double quote
    /// closes the identifier early and the remainder parses as SQL. Rather than
    /// escape and trust every call site to escape identically, accept only names
    /// that need no escaping at all.
    ///
    /// The length cap is SQLite's own limit on an identifier being far higher
    /// than anything a real field path reaches; a name past it is a payload bug,
    /// and a rejected column is one missing field rather than a broken table.
    public static func isSafeColumnName(_ name: String) -> Bool {
        guard !name.isEmpty, name.count <= 128 else { return false }
        guard let first = name.first, first == "_" || (first.isASCII && first.isLetter) else {
            return false
        }
        return name.allSatisfy { $0 == "_" || ($0.isASCII && ($0.isLetter || $0.isNumber)) }
    }

    /// The column affinity for a value's Swift type.
    ///
    /// Every column used to be TEXT, which is fine until you compare one: TEXT
    /// affinity stores 10 as `'10'`, and `'10' < '9'` is true, so an ordering or
    /// a threshold over a token count silently returns the wrong rows. Affinity
    /// in SQLite is advisory rather than a constraint — a REAL column accepts a
    /// string and an INTEGER column keeps a fractional value as REAL — so
    /// inferring it from the first value seen can misjudge a column but cannot
    /// lose what is written to it.
    ///
    /// Only columns created from here on are affected; an existing column is
    /// never altered. `migration033` retypes the ones an earlier version left
    /// TEXT, so an upgraded install and a fresh one agree.
    private static func affinity(for value: Any) -> String {
        // Numbers are asked what they hold rather than pattern-matched. Values
        // arrive from `JSONSerialization` as NSNumber, and an NSNumber holding
        // exactly 1 or 0 satisfies `is Bool` as readily as `is Double` — so
        // matching `is Bool` first declared `prompt_cache.hit_ratio` INTEGER
        // forever if the first session to report it happened to sit at 100%.
        // Only a real JSON true/false is a CFBoolean; everything else answers
        // with the C type it actually stores.
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return "INTEGER" }
            let code = String(cString: number.objCType)
            return (code == "f" || code == "d") ? "REAL" : "INTEGER"
        }
        switch value {
        case is Bool, is Int, is Int64, is Int32: return "INTEGER"
        case is Double, is Float: return "REAL"
        default: return "TEXT"
        }
    }

    /// Clears the cache for a table (e.g. after external schema changes).
    public func invalidate(table: String) {
        lock.withLock { _ = columnCache.removeValue(forKey: table) }
    }
}

extension DynamicSchema: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
