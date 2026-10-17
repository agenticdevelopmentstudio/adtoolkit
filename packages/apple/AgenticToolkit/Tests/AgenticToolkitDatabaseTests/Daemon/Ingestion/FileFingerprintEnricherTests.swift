import AgenticToolkitCore
import XCTest
import SQLite3
import Foundation
import CryptoKit
@testable import AgenticToolkitDatabase

/// Unit tests for `FileFingerprintEnricher` plus the ingest gate that applies
/// it, which since 2.121.0 covers `InstructionsLoaded` as well as
/// `ConfigChange`.
///
/// The fingerprint exists so a `system_prompt_changed` prompt-cache miss can be
/// *attributed* to an instructions edit rather than guessed at, so the tests
/// that matter are the ones asserting the hash moves when the file's contents
/// move — not merely that a column exists.
final class FileFingerprintEnricherTests: XCTestCase {

    private var database: DaemonDatabase!
    private var tmpPath: String!
    private var scratch: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        (database, tmpPath) = try TestDaemonDatabase.makeSessionDatabase()
        scratch = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fingerprint-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
        if let scratch { try? FileManager.default.removeItem(at: scratch) }
        try super.tearDownWithError()
    }

    // MARK: - enrich

    func testEnrichReportsSizeAndSHA256OfTheNamedFile() throws {
        let path = try writeFile("CLAUDE.md", "# Instructions\n")
        let out = FileFingerprintEnricher.enrich(hookData: ["file_path": path])

        XCTAssertEqual(out["file_size_bytes"] as? Int, 15)
        // Pinned so a change of hash function or hex spelling is a failing test,
        // not a silently unjoinable column.
        XCTAssertEqual(out["file_sha256"] as? String,
                       SHA256.hash(data: Data("# Instructions\n".utf8)).hexString)
    }

    func testEditingTheFileMovesTheHash() throws {
        let path = try writeFile("CLAUDE.md", "one\n")
        let before = FileFingerprintEnricher.enrich(hookData: ["file_path": path])
        try "two\n".write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
        let after = FileFingerprintEnricher.enrich(hookData: ["file_path": path])

        XCTAssertNotEqual(after["file_sha256"] as? String, before["file_sha256"] as? String,
                          "an edited CLAUDE.md must be distinguishable from an untouched one")
    }

    func testEnrichReturnsNothingForAMissingOrEmptyPath() throws {
        XCTAssertTrue(FileFingerprintEnricher.enrich(hookData: [:]).isEmpty)
        XCTAssertTrue(FileFingerprintEnricher.enrich(hookData: ["file_path": ""]).isEmpty)
        XCTAssertTrue(FileFingerprintEnricher.enrich(
            hookData: ["file_path": scratch.appendingPathComponent("gone.md").path]).isEmpty,
            "a path that no longer exists yields no fields rather than a zero size")
    }

    func testEnrichSkipsTheHashButKeepsTheSizeForAnOversizedFile() throws {
        // Hashing is bounded so a stray huge file can't stall the ingest queue;
        // the size still lands, because it is free and still diffable.
        let big = Data(count: FileFingerprintEnricher.maxHashBytes + 1)
        let path = scratch.appendingPathComponent("huge.bin").path
        try big.write(to: URL(fileURLWithPath: path))

        let out = FileFingerprintEnricher.enrich(hookData: ["file_path": path])
        XCTAssertEqual(out["file_size_bytes"] as? Int, FileFingerprintEnricher.maxHashBytes + 1)
        XCTAssertNil(out["file_sha256"])
    }

    // MARK: - Ingest gate

    func testInstructionsLoadedRowCarriesTheFingerprint() throws {
        let path = try writeFile("CLAUDE.md", "# Project\n")
        try database.ingestEvent(
            eventType: "InstructionsLoaded",
            timestamp: iso8601(),
            hookData: [
                "session_id": "s1",
                "cwd": scratch.path,
                "file_path": path,
                "memory_type": "Project",
                "load_reason": "startup"
            ]
        )

        let row = try fetchRow(
            "SELECT file_size_bytes, file_sha256 FROM instructions_loaded_events LIMIT 1")
        XCTAssertEqual(row[0], "10")
        XCTAssertEqual(row[1], SHA256.hash(data: Data("# Project\n".utf8)).hexString)
    }

    func testConfigChangeStillCarriesTheFingerprint() throws {
        let path = try writeFile("settings.json", "{}\n")
        try database.ingestEvent(
            eventType: "ConfigChange",
            timestamp: iso8601(),
            hookData: [
                "session_id": "s2",
                "cwd": scratch.path,
                "file_path": path,
                "source": "user_settings"
            ]
        )

        let row = try fetchRow(
            "SELECT file_size_bytes, file_sha256 FROM config_change_events LIMIT 1")
        XCTAssertEqual(row[0], "3")
        XCTAssertEqual(row[1], SHA256.hash(data: Data("{}\n".utf8)).hexString)
    }

    func testAnUnrelatedEventTypeIsNotFingerprinted() throws {
        // The gate is by event type on purpose: `file_path` shows up on tool
        // payloads too, and hashing every file a Read touched would be a hash
        // per tool call for a question nobody asked.
        try database.ingestEvent(
            eventType: "PreToolUse",
            timestamp: iso8601(),
            hookData: [
                "session_id": "s3",
                "cwd": scratch.path,
                "file_path": try writeFile("other.md", "x\n"),
                "tool_name": "Read"
            ]
        )
        XCTAssertFalse(try columnsOf(table: "pre_tool_use_events").contains("file_sha256"))
    }

    // MARK: - Column affinity (migration036)

    func testFileSizeIsAnIntegerColumnOnBothFingerprintedTables() throws {
        // Reading the value back through `sqlite3_column_text` cannot see this:
        // SQLite coerces on the way out, so a size stored as the string '10'
        // and one stored as the number 10 both read back "10". The split is
        // only visible in the declared type and the storage class — and it is
        // the declared type that decides whether `ORDER BY file_size_bytes`
        // sorts 9 before 10 or after it.
        try database.ingestEvent(
            eventType: "ConfigChange",
            timestamp: iso8601(),
            hookData: [
                "session_id": "s4", "cwd": scratch.path,
                "file_path": try writeFile("settings.json", "{}\n"), "source": "user_settings"
            ]
        )
        try database.ingestEvent(
            eventType: "InstructionsLoaded",
            timestamp: iso8601(),
            hookData: [
                "session_id": "s4", "cwd": scratch.path,
                "file_path": try writeFile("CLAUDE.md", "# P\n"),
                "memory_type": "Project", "load_reason": "startup"
            ]
        )

        for table in ["config_change_events", "instructions_loaded_events"] {
            XCTAssertEqual(try declaredType(of: "file_size_bytes", in: table), "INTEGER",
                           "\(table).file_size_bytes must be declared INTEGER")
            XCTAssertEqual(
                try storageClass(of: "file_size_bytes", in: table), SQLITE_INTEGER,
                "\(table) stored the size in the wrong storage class"
            )
            // The digest is not a number in any affinity, and must stay TEXT.
            XCTAssertEqual(try declaredType(of: "file_sha256", in: table), "TEXT")
        }
    }

    func testMigration036RetypesALegacyTextFileSizeColumn() throws {
        try database.ingestEvent(
            eventType: "ConfigChange",
            timestamp: iso8601(),
            hookData: [
                "session_id": "s5", "cwd": scratch.path,
                "file_path": try writeFile("settings.json", "{}\n"), "source": "user_settings"
            ]
        )
        database = nil

        // Rewind this DB to the pre-migration036 shape: the column declared
        // TEXT (which is what every install created before `DynamicSchema`
        // learned affinities), its values re-stored as text, and the migration
        // marked un-applied.
        try makeFileSizeLegacyText()
        try exec("""
            UPDATE config_change_events SET file_size_bytes = CAST(file_size_bytes AS TEXT);
            DELETE FROM schema_migrations WHERE version = 36;
        """)
        XCTAssertEqual(try declaredType(of: "file_size_bytes", in: "config_change_events"), "TEXT",
                       "the legacy shape was not established, so the test proves nothing")

        database = try reopenDatabase()

        XCTAssertEqual(try declaredType(of: "file_size_bytes", in: "config_change_events"),
                       "INTEGER")
        XCTAssertEqual(try storageClass(of: "file_size_bytes", in: "config_change_events"),
                       SQLITE_INTEGER,
                       "the rebuild must rewrite the rows through the new affinity, "
                       + "not just correct the header")
        XCTAssertEqual(try fetchRow("SELECT file_size_bytes FROM config_change_events LIMIT 1"),
                       ["3"], "the value itself must survive the rebuild")
    }

    func testMigration036LeavesANonNumericColumnAlone() throws {
        try database.ingestEvent(
            eventType: "ConfigChange",
            timestamp: iso8601(),
            hookData: [
                "session_id": "s6", "cwd": scratch.path,
                "file_path": try writeFile("settings.json", "{}\n"), "source": "user_settings"
            ]
        )
        database = nil

        try makeFileSizeLegacyText()
        // A value no INTEGER cast can carry. Retyping would truncate it to 0,
        // so the migration must refuse rather than lose it.
        try exec("""
            UPDATE config_change_events SET file_size_bytes = 'unknown';
            DELETE FROM schema_migrations WHERE version = 36;
        """)

        database = try reopenDatabase()

        XCTAssertEqual(try declaredType(of: "file_size_bytes", in: "config_change_events"), "TEXT")
        XCTAssertEqual(try fetchRow("SELECT file_size_bytes FROM config_change_events LIMIT 1"),
                       ["unknown"])
    }

    // MARK: - Helpers

    /// Reopens the same file, which re-runs any migration the test un-applied.
    private func reopenDatabase() throws -> DaemonDatabase {
        try DaemonDatabase(
            path: tmpPath,
            migrations: SessionSchema.migrations,
            postMigration: SessionSchema.postMigration
        )
    }

    private func writeFile(_ name: String, _ contents: String) throws -> String {
        let url = scratch.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    private func iso8601() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }

    /// One row of TEXT-coerced column values, or `[]` when there is no row.
    private func fetchRow(_ sql: String) throws -> [String] {
        var handle: OpaquePointer?
        guard sqlite3_open(tmpPath, &handle) == SQLITE_OK else {
            XCTFail("could not open db at \(tmpPath ?? "?")")
            return []
        }
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else {
            XCTFail("prepare failed: \(String(cString: sqlite3_errmsg(handle)))")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return [] }
        return (0..<sqlite3_column_count(stmt)).map { index in
            sqlite3_column_text(stmt, index).map { String(cString: $0) } ?? ""
        }
    }

    /// The column's *declared* type from `PRAGMA table_info`, uppercased —
    /// the thing `sqlite3_column_text` cannot show you.
    private func declaredType(of column: String, in table: String) throws -> String {
        try fetchRow("""
            SELECT upper(type) FROM pragma_table_info('\(table)') WHERE name = '\(column)'
        """).first ?? ""
    }

    /// The storage class SQLite actually put the first row's value in
    /// (`SQLITE_INTEGER` / `SQLITE_TEXT` / …).
    private func storageClass(of column: String, in table: String) throws -> Int32 {
        var handle: OpaquePointer?
        guard sqlite3_open(tmpPath, &handle) == SQLITE_OK else {
            XCTFail("could not open db at \(tmpPath ?? "?")")
            return SQLITE_NULL
        }
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        let sql = "SELECT \"\(column)\" FROM \"\(table)\" LIMIT 1"
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else {
            XCTFail("prepare failed: \(String(cString: sqlite3_errmsg(handle)))")
            return SQLITE_NULL
        }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return SQLITE_NULL }
        return sqlite3_column_type(stmt, 0)
    }

    /// Rebuild `config_change_events` with `file_size_bytes` declared TEXT —
    /// the shape every install created before `DynamicSchema` learned
    /// affinities, and the one `migration036` exists to reconcile. The daemon
    /// itself will never create that column as TEXT again, so the fixture has
    /// to build it.
    ///
    /// The obvious route — `PRAGMA writable_schema = ON` plus an `UPDATE
    /// sqlite_master` — does not work here: the SQLite this links against
    /// refuses the write with "table sqlite_master may not be modified"
    /// regardless of the pragma. So this does what the migration under test
    /// does, in reverse: rename, re-create from the recorded DDL with the one
    /// word changed, copy, drop — and re-create the indexes, which follow the
    /// rename onto the renamed table and would otherwise go with it.
    private func makeFileSizeLegacyText() throws {
        let table = "config_change_events"
        let original = try fetchRow("""
            SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '\(table)'
        """).first ?? ""
        guard original.contains("\"file_size_bytes\" INTEGER") else {
            return XCTFail("`\(table).file_size_bytes` is not INTEGER to begin with: \(original)")
        }
        let legacy = original.replacingOccurrences(
            of: "\"file_size_bytes\" INTEGER", with: "\"file_size_bytes\" TEXT"
        )
        let indexes = try fetchColumn("""
            SELECT sql FROM sqlite_master
             WHERE type = 'index' AND tbl_name = '\(table)' AND sql IS NOT NULL
        """)

        try exec("""
            BEGIN;
            ALTER TABLE \(table) RENAME TO \(table)_fixture_old;
            \(legacy);
            INSERT INTO \(table) SELECT * FROM \(table)_fixture_old;
            DROP TABLE \(table)_fixture_old;
            \(indexes.map { $0 + ";" }.joined(separator: "\n"))
            COMMIT;
        """)
    }

    /// The first column of every row a query returns.
    private func fetchColumn(_ sql: String) throws -> [String] {
        var handle: OpaquePointer?
        guard sqlite3_open(tmpPath, &handle) == SQLITE_OK else {
            XCTFail("could not open db at \(tmpPath ?? "?")")
            return []
        }
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else {
            XCTFail("prepare failed: \(String(cString: sqlite3_errmsg(handle)))")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        var rows: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? "")
        }
        return rows
    }

    /// Run SQL against the test DB directly, for setting up a shape the daemon
    /// itself will no longer produce.
    private func exec(_ sql: String) throws {
        var handle: OpaquePointer?
        guard sqlite3_open(tmpPath, &handle) == SQLITE_OK else {
            XCTFail("could not open db at \(tmpPath ?? "?")")
            return
        }
        defer { sqlite3_close(handle) }
        var error: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(handle, sql, nil, nil, &error) != SQLITE_OK {
            let message = error.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(error)
            XCTFail("exec failed: \(message)")
        }
    }

    private func columnsOf(table: String) throws -> Set<String> {
        var handle: OpaquePointer?
        guard sqlite3_open(tmpPath, &handle) == SQLITE_OK else { return [] }
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, "PRAGMA table_info(\(table))", -1, &stmt, nil) == SQLITE_OK
        else { return [] }
        defer { sqlite3_finalize(stmt) }
        var result: Set<String> = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let name = sqlite3_column_text(stmt, 1) { result.insert(String(cString: name)) }
        }
        return result
    }
}
