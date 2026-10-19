#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB

// MARK: - Settings

extension DaemonDatabase {

    public func setting(for key: String) throws -> String? {
        var result: String?
        try query("SELECT value FROM settings WHERE key = ?", params: [key]) { row in
            result = string(row, 0)
        }
        return result
    }

    public func setSetting(_ key: String, _ value: String) throws {
        // Route through execute (reentrant on the current connection) rather than
        // opening a nested write. Mirrors the `setting(for:)` getter.
        try execute("""
            INSERT INTO settings(key, value) VALUES (?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
        """, params: [key, value])
    }

    /// Removes a settings row, so the reader's default applies again. No row is not an error.
    public func deleteSetting(_ key: String) throws {
        try execute("DELETE FROM settings WHERE key = ?", params: [key])
    }
}
#endif
