import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase
import SQLite3

/// The script store's business rules: shipped seeding + versioned upgrade (never
/// touching user-modified rows), legacy threshold-intent import, validation, and
/// the built-in delete/reset rules.
final class ScriptStoreTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    private func userScript(id: String = UUID().uuidString, name: String = "Mine") -> OversightScript {
        OversightScript(
            id: id, name: name, enabled: true, builtIn: false, version: 1,
            trigger: ScriptTrigger(
                predicate: .condition(field: .lastEventType, operation: .equals, value: "Stop")
            ),
            response: ScriptResponse(kind: "attention", reasonTemplate: "r", action: .none)
        )
    }

    // MARK: - Shipped seeding + upgrade

    func testSynchronizeSeedsTheCompactScript() {
        let scripts = ScriptStore.scripts(database: database)
        XCTAssertEqual(scripts.map(\.id), ["compact"])
        let compact = scripts[0]
        XCTAssertTrue(compact.builtIn)
        XCTAssertTrue(compact.enabled)
        XCTAssertEqual(
            compact.trigger.predicate,
            .condition(field: .tokensInContext, operation: .greaterOrEqual,
                       value: String(ShippedScripts.compactDefaultTokens))
        )
        XCTAssertEqual(compact.response.action, .injectText("/compact"))
        XCTAssertEqual(compact.trigger.llmConfirmation?.actKeyword, "COMPACT")
    }

    func testLegacyThresholdIntentImportsOnFirstSeed() throws {
        // A user who tuned the legacy pct expressed "flag at 65% used" — the seeded
        // trigger preserves that instead of the token default.
        try database.setSetting("oversight_context_threshold_pct", "65")
        let compact = try XCTUnwrap(ScriptStore.scripts(database: database).first)
        XCTAssertEqual(
            compact.trigger.predicate,
            .condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "65")
        )
    }

    func testDefaultThresholdDoesNotImport() throws {
        try database.setSetting("oversight_context_threshold_pct", "80")
        let compact = try XCTUnwrap(ScriptStore.scripts(database: database).first)
        XCTAssertEqual(
            compact.trigger.predicate,
            .condition(field: .tokensInContext, operation: .greaterOrEqual,
                       value: String(ShippedScripts.compactDefaultTokens))
        )
    }

    func testUpgradeRefreshesUnmodifiedOlderVersion() throws {
        // Store an older unmodified copy of the built-in, as a past daemon would have.
        var old = ShippedScripts.compact()
        old.version = 0
        old.name = "Old Compact"
        try database.upsertOversightScript(old, userModified: false)

        ScriptStore.synchronizeShipped(database: database)
        let stored = try XCTUnwrap(ScriptStore.script(id: "compact", database: database))
        XCTAssertEqual(stored.name, "Compact", "an unmodified older row upgrades wholesale")
        XCTAssertEqual(stored.version, ShippedScripts.compact().version)
    }

    func testUpgradeNeverTouchesUserModifiedRow() throws {
        var mine = ShippedScripts.compact()
        mine.version = 0
        mine.trigger.predicate = .condition(field: .tokensInContext, operation: .greaterOrEqual, value: "120000")
        try database.upsertOversightScript(mine, userModified: true)

        ScriptStore.synchronizeShipped(database: database)
        let stored = try XCTUnwrap(ScriptStore.script(id: "compact", database: database))
        XCTAssertEqual(
            stored.trigger.predicate,
            .condition(field: .tokensInContext, operation: .greaterOrEqual, value: "120000"),
            "a user-modified built-in is theirs — the upgrader must not overwrite it"
        )
    }

    // MARK: - Save

    func testSaveNewUserScript() throws {
        let saved = try ScriptStore.save(userScript(id: "mine", name: "Mine"), database: database)
        XCTAssertFalse(saved.builtIn)
        let row = try XCTUnwrap(database.fetchOversightScriptRow(id: "mine"))
        XCTAssertTrue(row.userModified)
        XCTAssertEqual(row.script.name, "Mine")
    }

    func testSaveCannotPromoteToBuiltIn() throws {
        var sneaky = userScript(id: "sneaky")
        sneaky.builtIn = true
        let saved = try ScriptStore.save(sneaky, database: database)
        XCTAssertFalse(saved.builtIn, "a client can't mint built-ins")
    }

    func testEditingBuiltInStampsUserModified() throws {
        ScriptStore.synchronizeShipped(database: database)
        var compact = try XCTUnwrap(ScriptStore.script(id: "compact", database: database))
        compact.trigger.predicate = .condition(field: .tokensInContext, operation: .greaterOrEqual, value: "90000")
        try ScriptStore.save(compact, database: database)

        let row = try XCTUnwrap(database.fetchOversightScriptRow(id: "compact"))
        XCTAssertTrue(row.userModified)
        XCTAssertTrue(row.script.builtIn, "editing a built-in keeps it built-in")
    }

    // MARK: - Validation

    func testValidationRejectsEmptyGroup() {
        var bad = userScript()
        bad.trigger.predicate = .all([])
        XCTAssertThrowsError(try ScriptStore.save(bad, database: database))
    }

    func testValidationRejectsEmptyInjectText() {
        var bad = userScript()
        bad.response.action = .injectText("   ")
        XCTAssertThrowsError(try ScriptStore.save(bad, database: database))
    }

    func testValidationRejectsNonNumericValueForNumericField() {
        var bad = userScript()
        bad.trigger.predicate = .condition(field: .tokensInContext, operation: .greaterOrEqual, value: "lots")
        XCTAssertThrowsError(try ScriptStore.save(bad, database: database))
    }

    func testValidationRejectsBlankNameAndKind() {
        var noName = userScript()
        noName.name = "  "
        XCTAssertThrowsError(try ScriptStore.save(noName, database: database))
        var noKind = userScript()
        noKind.response.kind = ""
        XCTAssertThrowsError(try ScriptStore.save(noKind, database: database))
    }

    func testValidationRejectsEmptyActKeyword() {
        // An empty act keyword makes the verdict parser read every reply as "act",
        // defeating the WAIT confirmation — reject it at save (the app UI can't be
        // the only guard, since HTTP/XPC reach save directly).
        var bad = userScript()
        bad.trigger.llmConfirmation = LLMConfirmation(systemPrompt: "s", actKeyword: "  ")
        XCTAssertThrowsError(try ScriptStore.save(bad, database: database))
    }

    func testValidationRejectsNonFiniteNumericValue() {
        for value in ["nan", "inf", "infinity"] {
            var bad = userScript()
            bad.trigger.predicate = .condition(
                field: .tokensInContext, operation: .notEquals, value: value
            )
            XCTAssertThrowsError(try ScriptStore.save(bad, database: database),
                                 "\(value) parses as a Double but isn't a finite number")
        }
    }

    // MARK: - Delete / reset

    func testDeleteUserScript() throws {
        try ScriptStore.save(userScript(id: "mine"), database: database)
        try ScriptStore.delete(id: "mine", database: database)
        XCTAssertNil(try database.fetchOversightScriptRow(id: "mine"))
    }

    func testDeleteBuiltInRejected() {
        ScriptStore.synchronizeShipped(database: database)
        XCTAssertThrowsError(try ScriptStore.delete(id: "compact", database: database))
    }

    func testDeleteMissingThrowsNotFound() {
        XCTAssertThrowsError(try ScriptStore.delete(id: "ghost", database: database))
    }

    func testResetRestoresShippedDefinition() throws {
        ScriptStore.synchronizeShipped(database: database)
        var compact = try XCTUnwrap(ScriptStore.script(id: "compact", database: database))
        compact.trigger.predicate = .condition(field: .tokensInContext, operation: .greaterOrEqual, value: "999999")
        try ScriptStore.save(compact, database: database)

        let restored = try ScriptStore.reset(id: "compact", database: database)
        XCTAssertEqual(restored, ShippedScripts.compact())
        let row = try XCTUnwrap(database.fetchOversightScriptRow(id: "compact"))
        XCTAssertFalse(row.userModified, "reset clears user_modified so future upgrades apply")
    }

    func testResetUserScriptRejected() throws {
        try ScriptStore.save(userScript(id: "mine"), database: database)
        XCTAssertThrowsError(try ScriptStore.reset(id: "mine", database: database))
    }

    func testResetIgnoresLegacyThresholdAndRestoresTokenDefault() throws {
        // A tuned legacy pct seeds the compact trigger on first insert, but Reset must
        // restore the canonical shipped default (tokens), not resurrect the pct.
        try database.setSetting("oversight_context_threshold_pct", "65")
        _ = ScriptStore.scripts(database: database)  // first insert imports the pct
        let restored = try ScriptStore.reset(id: "compact", database: database)
        XCTAssertEqual(restored, ShippedScripts.compact())
        XCTAssertEqual(
            restored.trigger.predicate,
            .condition(field: .tokensInContext, operation: .greaterOrEqual,
                       value: String(ShippedScripts.compactDefaultTokens)),
            "reset restores the token default, not the one-time legacy pct import"
        )
    }

    // MARK: - Corrupt rows

    func testUndecodableRowIsSkippedNotFatal() throws {
        try ScriptStore.save(userScript(id: "good", name: "Good"), database: database)
        try plantCorruptRow(id: "broken")
        let scripts = ScriptStore.scripts(database: database)
        XCTAssertTrue(scripts.contains { $0.id == "good" })
        XCTAssertTrue(scripts.contains { $0.id == "compact" }, "sync still seeds")
        XCTAssertFalse(scripts.contains { $0.id == "broken" }, "the corrupt row is skipped, not fatal")
    }

    /// Plant a row whose definition JSON doesn't decode, via raw sqlite (the typed
    /// accessor can't write garbage).
    private func plantCorruptRow(id: String) throws {
        database.waitForPendingWrites()
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tmpPath, &handle), SQLITE_OK)
        defer { sqlite3_close(handle) }
        let sql = """
            INSERT INTO oversight_scripts (id, name, enabled, built_in, user_modified, version, definition)
            VALUES ('\(id)', 'Broken', 1, 0, 1, 1, '{not json')
            """
        XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, nil), SQLITE_OK)
    }
}
