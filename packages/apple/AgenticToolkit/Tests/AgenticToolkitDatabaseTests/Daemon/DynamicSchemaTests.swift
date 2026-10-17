import XCTest
import GRDB
@testable import AgenticToolkitDatabase

final class DynamicSchemaTests: XCTestCase {

    private var queue: DatabaseQueue!

    override func setUpWithError() throws {
        queue = try DatabaseQueue()   // in-memory
        try queue.write { conn in
            try conn.execute(sql: "CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)")
        }
    }

    override func tearDownWithError() throws {
        queue = nil
    }

    // MARK: - Helpers (run DynamicSchema inside a GRDB connection)

    private func columns(_ schema: DynamicSchema, _ table: String = "t") throws -> Set<String> {
        try queue.write { conn in try schema.columns(for: table, database: conn) }
    }
    private func ensure(_ schema: DynamicSchema, _ fields: [String: Any], _ table: String = "t") throws {
        _ = try queue.write { conn in
            try schema.ensureColumns(for: table, fields: fields, database: conn)
        }
    }
    private func exec(_ sql: String) throws {
        try queue.write { conn in try conn.execute(sql: sql) }
    }

    // MARK: - columns()

    func testColumnsReturnsExistingColumns() throws {
        let cols = try columns(DynamicSchema())
        XCTAssertTrue(cols.contains("id"))
        XCTAssertTrue(cols.contains("name"))
    }

    func testColumnsReturnsCachedResultOnSecondCall() throws {
        let schema = DynamicSchema()
        _ = try columns(schema)
        try exec("DROP TABLE t")
        XCTAssertTrue(try columns(schema).contains("id"), "Second call must return cached result")
    }

    // MARK: - ensureColumns()

    func testEnsureColumnsAddsNewColumn() throws {
        let schema = DynamicSchema()
        try ensure(schema, ["extra": "value"])
        XCTAssertTrue(try columns(schema).contains("extra"))
    }

    /// The declared type of a column, or nil when there is no such column.
    private func declaredType(_ column: String, _ table: String = "t") throws -> String? {
        try queue.write { conn in
            try conn.columns(in: table).first { $0.name == column }?.type
        }
    }

    /// A token count in a TEXT column compares as a string, where '10' < '9'.
    /// Numbers get numeric affinity so an ordering or a threshold over one is
    /// answerable without a CAST at every call site.
    func testEnsureColumnsGivesNumbersNumericAffinity() throws {
        let schema = DynamicSchema()
        try ensure(schema, ["tokens": 45000, "ratio": 0.91, "warm": true, "label": "cold"])
        XCTAssertEqual(try declaredType("tokens"), "INTEGER")
        XCTAssertEqual(try declaredType("ratio"), "REAL")
        XCTAssertEqual(try declaredType("warm"), "INTEGER")
        XCTAssertEqual(try declaredType("label"), "TEXT")
    }

    /// Affinity is inferred once, from the first value seen. SQLite affinity is
    /// advisory, so a later value of another type is still stored rather than
    /// rejected or truncated — the misjudged column costs ordering, not data.
    func testEnsureColumnsKeepsAValueThatContradictsTheInferredAffinity() throws {
        let schema = DynamicSchema()
        try ensure(schema, ["ratio": 1])                     // looks INTEGER
        XCTAssertEqual(try declaredType("ratio"), "INTEGER")
        try ensure(schema, ["ratio": 0.91])                  // no ALTER — already known
        try exec("INSERT INTO t (ratio) VALUES (0.91)")
        let stored: Double? = try queue.read { conn in
            try Double.fetchOne(conn, sql: "SELECT ratio FROM t WHERE ratio IS NOT NULL")
        }
        XCTAssertEqual(stored, 0.91)
    }

    func testEnsureColumnsSkipsNestedObjects() throws {
        let schema = DynamicSchema()
        try ensure(schema, ["nested": ["a": 1], "flat": "ok"])
        let cols = try columns(schema)
        XCTAssertFalse(cols.contains("nested"), "Nested dicts must not become columns")
        XCTAssertTrue(cols.contains("flat"))
    }

    func testEnsureColumnsSkipsArrays() throws {
        let schema = DynamicSchema()
        try ensure(schema, ["arr": [1, 2, 3], "flat": "ok"])
        let cols = try columns(schema)
        XCTAssertFalse(cols.contains("arr"), "Arrays must not become columns")
        XCTAssertTrue(cols.contains("flat"))
    }

    func testEnsureColumnsIsIdempotent() throws {
        let schema = DynamicSchema()
        try ensure(schema, ["extra": "v"])
        XCTAssertNoThrow(try ensure(schema, ["extra": "v"]))
        XCTAssertTrue(try columns(schema).contains("extra"))
    }

    func testEnsureColumnsUpdatesCache() throws {
        let schema = DynamicSchema()
        try ensure(schema, ["new_col": "v"])
        // Recreate the table WITHOUT the new column — the cache should still show it.
        try exec("DROP TABLE t")
        try exec("CREATE TABLE t (id INTEGER PRIMARY KEY)")
        XCTAssertTrue(try columns(schema).contains("new_col"), "Cache should reflect added column")
    }

    /// The affinity bug only reproduces through JSON, which is the only way the
    /// daemon ever receives these values.
    ///
    /// `JSONSerialization` hands back `NSNumber`, and an NSNumber holding
    /// exactly 1.0 answers `is Bool` as readily as `is Double` — so a
    /// type-switch declared `hit_ratio` INTEGER forever whenever the first
    /// session to report it happened to be sitting at 100%. Swift literals
    /// cannot express that: `1.0` written here is a real `Double` and the old
    /// code got it right. Only the real payload shape catches it.
    func testAJSONNumberIsTypedByWhatItHoldsNotByWhetherItLooksBoolean() throws {
        let json = #"{"hit_ratio": 1.0, "misses": 0, "warm": true, "cold": false}"#
        let fields = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )
        try ensure(DynamicSchema(), fields)
        XCTAssertEqual(try declaredType("hit_ratio"), "REAL", "1.0 is a ratio, not a flag")
        XCTAssertEqual(try declaredType("misses"), "INTEGER")
        XCTAssertEqual(try declaredType("warm"), "INTEGER")
        XCTAssertEqual(try declaredType("cold"), "INTEGER")
    }

    // MARK: - Unsafe column names

    /// Payload keys are interpolated into a quoted SQL identifier — an
    /// identifier cannot be bound — so a name needing an escape is refused
    /// rather than escaped. One missing field beats a statement that reparses.
    func testAKeyThatWouldNeedEscapingIsRefusedRatherThanEscaped() {
        XCTAssertFalse(DynamicSchema.isSafeColumnName(#"evil" TEXT); DROP TABLE t; --"#))
        XCTAssertFalse(DynamicSchema.isSafeColumnName(""))
        XCTAssertFalse(DynamicSchema.isSafeColumnName("1_leading_digit"))
        XCTAssertFalse(DynamicSchema.isSafeColumnName("has space"))
        XCTAssertFalse(DynamicSchema.isSafeColumnName("naïve"))
        XCTAssertFalse(DynamicSchema.isSafeColumnName(String(repeating: "a", count: 129)))
        XCTAssertTrue(DynamicSchema.isSafeColumnName("prompt_cache_hit_ratio"))
        XCTAssertTrue(DynamicSchema.isSafeColumnName("_leading_underscore"))
        XCTAssertTrue(DynamicSchema.isSafeColumnName("v2"))
    }

    func testAnUnsafeKeyIsSkippedAndTheRestStillLand() throws {
        let schema = DynamicSchema()
        try ensure(schema, [#"bad"name"#: "v", "good_name": "v"])
        let cols = try columns(schema)
        XCTAssertFalse(cols.contains(#"bad"name"#))
        XCTAssertTrue(cols.contains("good_name"))
    }

    // MARK: - The returned column set

    /// The return value is the contract with `insertDynamic`: it must name what
    /// the table actually has, so a refused key can never reach an INSERT and
    /// fail it with `no such column`.
    func testTheReturnedSetIsWhatTheTableActuallyHas() throws {
        let returned = try queue.write { conn in
            try DynamicSchema().ensureColumns(
                for: "t", fields: [#"bad"name"#: "v", "good_name": "v"], database: conn
            )
        }
        let actual = try queue.read { conn in Set(try conn.columns(in: "t").map(\.name)) }
        XCTAssertEqual(returned, actual)
        XCTAssertFalse(returned.contains(#"bad"name"#))
    }

    /// A table cannot grow without bound: SQLite's own ceiling is 2000, and
    /// hitting it would fail every ALTER from then on, quarantining every event
    /// carrying the unaddable field. The budget turns that into dropped fields.
    func testColumnsStopBeingAddedAtTheBudget() throws {
        var fields: [String: Any] = [:]
        for index in 0..<(DynamicSchema.maxColumns + 64) { fields["c\(index)"] = index }
        let returned = try queue.write { conn in
            try DynamicSchema().ensureColumns(for: "t", fields: fields, database: conn)
        }
        XCTAssertEqual(returned.count, DynamicSchema.maxColumns)
        let actual = try queue.read { conn in Set(try conn.columns(in: "t").map(\.name)) }
        XCTAssertEqual(returned, actual, "the refused columns must not be claimed")
    }

    // MARK: - Failure and rollback

    /// An ALTER can fail benignly (the column already exists — a stale cache)
    /// or fatally (no such table, a full disk). Those used to be treated as one
    /// case: the benign reading was assumed and the key was silently left out.
    func testAnAlterThatFailedForRealPropagates() throws {
        XCTAssertThrowsError(
            try queue.write { conn in
                try DynamicSchema().ensureColumns(
                    for: "no_such_table", fields: ["extra": "v"], database: conn
                )
            }
        )
    }

    func testAnAlterThatFailedBecauseTheColumnExistsIsBenign() throws {
        let schema = DynamicSchema()
        _ = try columns(schema)                       // cache the pre-ALTER shape
        try exec("ALTER TABLE t ADD COLUMN added_behind_the_cache TEXT")
        // The cache still says the column is missing, so ensureColumns tries the
        // ALTER, SQLite refuses it as a duplicate — and that is not an error.
        let returned = try queue.write { conn in
            try schema.ensureColumns(
                for: "t", fields: ["added_behind_the_cache": "v"], database: conn
            )
        }
        XCTAssertTrue(returned.contains("added_behind_the_cache"))
    }

    /// ALTER TABLE is DDL inside the caller's transaction, and SQLite rolls DDL
    /// back with everything else. The cache would otherwise go on claiming a
    /// column that no longer exists — permanently, since every later event
    /// skips the ALTER and INSERTs into it.
    func testARolledBackAlterDoesNotLeaveThatColumnInTheCache() throws {
        let schema = DynamicSchema()
        try queue.writeWithoutTransaction { conn in
            try conn.inTransaction {
                try schema.ensureColumns(for: "t", fields: ["rolled": "v"], database: conn)
                XCTAssertTrue(try conn.columns(in: "t").contains { $0.name == "rolled" })
                return .rollback
            }
        }
        XCTAssertFalse(
            try columns(schema).contains("rolled"),
            "the cache must be re-read after the DDL was rolled back"
        )
    }

    // MARK: - invalidate()

    func testInvalidateClearsCache() throws {
        let schema = DynamicSchema()
        _ = try columns(schema)
        try exec("ALTER TABLE t ADD COLUMN added_after TEXT")
        schema.invalidate(table: "t")
        XCTAssertTrue(try columns(schema).contains("added_after"), "Invalidate must force a re-read")
    }

    func testInvalidateUnknownTableIsNoop() {
        DynamicSchema().invalidate(table: "nonexistent")
    }
}
