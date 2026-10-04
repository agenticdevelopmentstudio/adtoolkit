#if os(macOS)
import XCTest
import GRDB
import AgenticToolkitDatabase
@testable import AgenticToolkitActivity

/// The migrations the product actually ships, against a database that already
/// holds rows. `SchemaMigratorTests` proves the migrator; this proves the
/// registry — specifically that an upgrade does not leave old rows in a state
/// the reader has to guess about.
final class OlyloSchemaTests: XCTestCase {
    private var dir: URL!
    private var db: BoundedDatabase!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-schema-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        db = try BoundedDatabase(path: dir.appendingPathComponent("test.sqlite").path)
    }

    override func tearDownWithError() throws {
        db = nil
        try? FileManager.default.removeItem(at: dir)
    }

    func testVersionsAreUniqueAndContiguous() throws {
        let versions = OlyloSchema.migrations.map(\.version).sorted()
        XCTAssertEqual(Set(versions).count, versions.count, "two migrations share a version")
        XCTAssertEqual(versions, Array(1...versions.count),
                       "a gap in the version space means a database can record a version "
                       + "that nothing ever applies")
    }

    func testMigratingIsIdempotent() throws {
        try OlyloSchema.migrate(db)
        try OlyloSchema.migrate(db)
        XCTAssertEqual(try SchemaMigrator(database: db).appliedVersions(),
                       Set(OlyloSchema.migrations.map(\.version)))
    }

    // MARK: - 7. Input events became transitions

    /// Rows written before migration 7 are periodic samples, and the backfill
    /// is what says so. Left NULL they would be indistinguishable from a
    /// transition whose kind was lost, and `ContextStore+Read` would have to
    /// guess which — a guess that decides whether the timeline reads the row
    /// as presence or as an absence.
    func testMigrationSevenBackfillsExistingInputRowsAsSamples() throws {
        try migrate(throughVersion: 6)

        let machine = UUID().uuidString
        let event = UUID().uuidString
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO machine (id, platform, first_seen_at, last_seen_at)
                VALUES (?, 'macos', '2026-08-01T00:00:00.000Z', '2026-08-01T00:00:00.000Z')
                """, arguments: [machine])
            try db.execute(sql: """
                INSERT INTO context_event (id, machine_id, occurred_at, kind)
                VALUES (?, ?, '2026-08-01T09:00:00.000Z', 'input')
                """, arguments: [event, machine])
            try db.execute(sql: """
                INSERT INTO context_event_input
                  (event_id, seconds_since_key, key_count_delta, interval_ms)
                VALUES (?, 1.5, 12, 30000)
                """, arguments: [event])
        }

        // Stops at 7 rather than migrating in full: migration 9 replays the
        // samples into transitions, so a full run would delete the row this
        // test is about before it could be read.
        try migrate(throughVersion: 7)

        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_input"))
            XCTAssertEqual(row["change"] as String?, "sample",
                           "every pre-migration row is a periodic reading")
            XCTAssertNil(row["idle_seconds"] as Double?,
                         "nothing measured an absence for these rows")
            XCTAssertEqual(row["key_count_delta"] as Int64?, 12,
                           "the backfill must not disturb what the row already carried")
        }
    }

    func testMigrationSevenLeavesNewRowsSayingWhatTheyAre() throws {
        // The column takes no DEFAULT, so a later insert that forgot to name
        // it would write NULL rather than silently claiming to be a sample.
        try OlyloSchema.migrate(db)
        let store = ContextStore(database: db)
        let machineID = UUID()
        try store.upsertMachine(
            MachineDescriptor(id: machineID, platform: .macOS, nativeID: "NATIVE",
                              nativeIDKind: .ioPlatformUUID, hostname: "h", model: "m",
                              osVersion: "26.0"),
            seenAt: Date(timeIntervalSince1970: 1_000))
        try store.insert(ContextEvent(
            machineID: machineID,
            occurredAt: Date(timeIntervalSince1970: 2_000),
            detail: .input(InputDetail(
                change: .inactive, idleSeconds: nil,
                secondsSinceKey: 240, secondsSinceMouseMove: 240,
                secondsSinceClick: nil, secondsSinceScroll: nil,
                keyCountDelta: 0, mouseCountDelta: 0, intervalMs: 30_000))))

        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_input"))
            XCTAssertEqual(row["change"] as String?, "inactive")
        }
    }

    // MARK: - 8. A browser's address is not a document path

    /// The rows already in this database put Brave and Chrome URLs in
    /// `document_path`, because `kAXDocumentAttribute` answers with both and
    /// nothing split them. Left where they are, every "what files did I open"
    /// query answers with web pages.
    func testMigrationEightMovesRecordedURLsOutOfTheDocumentPathColumn() throws {
        try migrate(throughVersion: 7)

        let machine = UUID().uuidString
        let page = UUID().uuidString
        let file = UUID().uuidString
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO machine (id, platform, first_seen_at, last_seen_at)
                VALUES (?, 'macos', '2026-08-01T00:00:00.000Z', '2026-08-01T00:00:00.000Z')
                """, arguments: [machine])
            for (id, path) in [(page, "https://example.org/overview"),
                               (file, "/Users/me/notes.md")] {
                try db.execute(sql: """
                    INSERT INTO context_event (id, machine_id, occurred_at, kind)
                    VALUES (?, ?, '2026-08-01T09:00:00.000Z', 'app_focus')
                    """, arguments: [id, machine])
                try db.execute(sql: """
                    INSERT INTO context_event_app_focus
                      (event_id, bundle_id, app_name, pid, document_path)
                    VALUES (?, 'x', 'X', 1, ?)
                    """, arguments: [id, path])
            }
        }

        try OlyloSchema.migrate(db)

        try db.read { db in
            let moved = try XCTUnwrap(Row.fetchOne(
                db, sql: "SELECT * FROM context_event_app_focus WHERE event_id = ?",
                arguments: [page]))
            XCTAssertEqual(moved["url"] as String?, "https://example.org/overview")
            XCTAssertNil(moved["document_path"] as String?,
                         "a page is not a file, and leaving it in both columns "
                         + "would double-count it")

            let untouched = try XCTUnwrap(Row.fetchOne(
                db, sql: "SELECT * FROM context_event_app_focus WHERE event_id = ?",
                arguments: [file]))
            XCTAssertEqual(untouched["document_path"] as String?, "/Users/me/notes.md")
            XCTAssertNil(untouched["url"] as String?)
        }
    }

    // MARK: - 9. The periodic input samples become the transitions they imply

    /// The load-bearing test for migration 9. The samples below are one
    /// coherent story — the user typed at +58s, then stopped, and came back at
    /// +297s — told thirty seconds at a time by eleven rows. The migration has
    /// to recover the story and throw away the telling.
    func testMigrationNineReplaysSamplesAsTheTransitionsTheyImply() throws {
        try migrate(throughVersion: 8)
        let machine = try insertMachine()
        // (seconds after 09:00:00, seconds of silence at that tick). Silence
        // counts down to 2 at +60 because that is when the last key was
        // pressed, then climbs untouched — which is what makes +58 the moment
        // input stopped and 09:04:57 the moment it resumed.
        try insertSamples(machine: machine, [
            (0, 5), (30, 35), (60, 2), (90, 32), (120, 62), (150, 92),
            (180, 122), (210, 152), (240, 182), (270, 212), (300, 3),
        ])

        try OlyloSchema.migrate(db)

        let rows = try inputRows()
        XCTAssertEqual(rows.count, 3, "eleven samples describe three moments")

        XCTAssertEqual(rows[0]["change"] as String?, "active")
        XCTAssertEqual(rows[0]["occurred_at"] as String?, "2026-08-01T09:00:00.000Z",
                       "a run's first row reports the state it found, where it found it: "
                       + "the silence may predate the run, and backdating would claim to "
                       + "have watched something nobody watched")
        XCTAssertNil(rows[0]["idle_seconds"] as Double?)
        XCTAssertNil(rows[0]["interval_ms"] as Int64?,
                     "nothing was emitted before it to measure an interval against")

        XCTAssertEqual(rows[1]["change"] as String?, "inactive")
        XCTAssertEqual(rows[1]["occurred_at"] as String?, "2026-08-01T09:00:58.000Z",
                       "input stopped when the last key was pressed, not when the tick "
                       + "three minutes later noticed")
        XCTAssertNil(rows[1]["idle_seconds"] as Double?,
                     "an absence that has just begun has no length yet")

        XCTAssertEqual(rows[2]["change"] as String?, "active")
        XCTAssertEqual(rows[2]["occurred_at"] as String?, "2026-08-01T09:04:57.000Z")
        XCTAssertEqual(try XCTUnwrap(rows[2]["idle_seconds"] as Double?), 239, accuracy: 0.001,
                       "the whole absence, from the moment input stopped to the moment "
                       + "it resumed — not the absence minus one poll interval")
    }

    /// A sample's counter delta is measured against the previous *tick*; a
    /// transition's is measured against the previous *emitted row*. The
    /// migration recovers the second from the first by summing, which works
    /// because consecutive differences telescope — and is worth a test because
    /// dropping the counters instead would have been the easy thing to do.
    func testMigrationNineSumsTheCountersBetweenTheRowsItKeeps() throws {
        try migrate(throughVersion: 8)
        let machine = try insertMachine()
        try insertSamples(machine: machine, [
            (0, 5), (30, 35), (60, 2), (90, 32), (120, 62), (150, 92),
            (180, 122), (210, 152), (240, 182), (270, 212), (300, 3),
        ], keyDelta: 1)

        try OlyloSchema.migrate(db)

        let rows = try inputRows()
        XCTAssertEqual(rows[1]["key_count_delta"] as Int64?, 8,
                       "the eight ticks between the first row and this one")
        XCTAssertEqual(rows[2]["key_count_delta"] as Int64?, 2,
                       "and the two between this one and the last")
    }

    /// `interval_ms IS NULL` is the only marker of where one daemon run ended
    /// and the next began — the trigger clears `lastEmitted` in `start()`, so
    /// every run's first row has no interval and every later row has one. A
    /// run that begins with the user already gone reports that, dated where it
    /// was noticed and carrying how long it had already been quiet.
    func testMigrationNineStartsAFreshReckoningAtEachRun() throws {
        try migrate(throughVersion: 8)
        let machine = try insertMachine()
        try insertSamples(machine: machine, [(0, 5), (30, 35)])
        try insertSamples(machine: machine, [(400, 500), (430, 530)])

        try OlyloSchema.migrate(db)

        let rows = try inputRows()
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[1]["change"] as String?, "inactive")
        XCTAssertEqual(rows[1]["occurred_at"] as String?, "2026-08-01T09:06:40.000Z",
                       "not backdated 500 seconds into a run that had not started")
        XCTAssertEqual(try XCTUnwrap(rows[1]["idle_seconds"] as Double?), 500, accuracy: 0.001,
                       "how long it had already been quiet is the honest form of the "
                       + "same fact, and one a reader can tell from a measurement")
    }

    /// The migration is scoped to `sample`. A transition already written by
    /// the current trigger — and this database has one — must come through
    /// untouched, including its timestamp.
    func testMigrationNineLeavesRowsThatAreAlreadyTransitionsAlone() throws {
        try migrate(throughVersion: 8)
        let machine = try insertMachine()
        let event = UUID().uuidString
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO context_event (id, machine_id, occurred_at, kind)
                VALUES (?, ?, '2026-08-01T09:00:00.000Z', 'input')
                """, arguments: [event, machine])
            try db.execute(sql: """
                INSERT INTO context_event_input
                  (event_id, seconds_since_key, change, idle_seconds, interval_ms)
                VALUES (?, 900.0, 'active', 900.0, 30000)
                """, arguments: [event])
        }

        try OlyloSchema.migrate(db)

        let rows = try inputRows()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["change"] as String?, "active")
        XCTAssertEqual(rows[0]["occurred_at"] as String?, "2026-08-01T09:00:00.000Z")
        XCTAssertEqual(rows[0]["idle_seconds"] as Double?, 900)
    }

    /// The threshold is the machine's own setting rather than a constant, so
    /// that reconstructed history and newly recorded rows describe presence by
    /// the same rule. At a twenty-second threshold the same samples say the
    /// user left far sooner.
    func testMigrationNineObeysThisMachinesInactivityThreshold() throws {
        try migrate(throughVersion: 8)
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO settings (key, value)
                VALUES ('trigger.input.inactivity_seconds', '20')
                """)
        }
        let machine = try insertMachine()
        try insertSamples(machine: machine, [(0, 5), (30, 25), (60, 3)])

        try OlyloSchema.migrate(db)

        let rows = try inputRows()
        XCTAssertEqual(rows.count, 3, "25 seconds of quiet is an absence at this threshold")
        XCTAssertEqual(rows[1]["change"] as String?, "inactive")
    }

    // MARK: - 10. Location rows that describe one spot become one row

    func testMigrationTenKeepsOneRowPerPlaceAndDropsTheRestasJitter() throws {
        try migrate(throughVersion: 9)
        let machine = try insertMachine()
        // Boston, then two fixes a few tens of metres away — inside one
        // accuracy radius, and inside the 100m filter CoreLocation now
        // applies — then a genuine move, then jitter around that.
        try insertLocations(machine: machine, [
            (0, 42.3601, -71.0589),
            (60, 42.36028, -71.0589),
            (120, 42.36046, -71.0589),
            (180, 42.4051, -71.0589),
            (240, 42.40528, -71.0589),
        ])

        try OlyloSchema.migrate(db)

        let rows = try locationRows()
        XCTAssertEqual(rows.count, 2, "two places, however many fixes described them")
        XCTAssertEqual(rows[0]["occurred_at"] as String?, "2026-08-01T09:00:00.000Z")
        XCTAssertEqual(rows[1]["occurred_at"] as String?, "2026-08-01T09:03:00.000Z")
    }

    /// Distance is measured from the last fix *kept*, which is what
    /// `distanceFilter` measures from — not from the previous fix. A slow
    /// drift of 60m a minute never clears the filter one step at a time, and
    /// must not be allowed to sneak past it one step at a time either.
    func testMigrationTenMeasuresFromTheLastFixItKept() throws {
        try migrate(throughVersion: 9)
        let machine = try insertMachine()
        try insertLocations(machine: machine, [
            (0, 42.3601, -71.0589),
            (60, 42.36064, -71.0589),   // 60m from the first
            (120, 42.36118, -71.0589),  // 60m further, 120m from the first
        ])

        try OlyloSchema.migrate(db)

        XCTAssertEqual(try locationRows().count, 2,
                       "the third fix is 120m from the one that was kept, so it is a move")
    }

    /// A database holding two machines' events is what `machine_link` exists
    /// for. Walked as one series, the second machine's first fix reads as a
    /// journey and the first machine's next fix reads as the return trip.
    func testMigrationTenWalksEachMachineSeparately() throws {
        try migrate(throughVersion: 9)
        let here = try insertMachine()
        let there = try insertMachine()
        try insertLocations(machine: here,  [(0, 42.3601, -71.0589)])
        try insertLocations(machine: there, [(60, 37.7749, -122.4194)])
        try insertLocations(machine: here,  [(120, 42.36018, -71.0589)])

        try OlyloSchema.migrate(db)

        let rows = try locationRows()
        XCTAssertEqual(rows.count, 2,
                       "one row for each machine's place; the third fix is this "
                       + "machine's own desk, not a flight back from San Francisco")
    }

    // MARK: - Fixtures

    private func insertMachine() throws -> String {
        let machine = UUID().uuidString
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO machine (id, platform, first_seen_at, last_seen_at)
                VALUES (?, 'macos', '2026-08-01T00:00:00.000Z', '2026-08-01T00:00:00.000Z')
                """, arguments: [machine])
        }
        return machine
    }

    /// One daemon run's worth of pre-migration input rows, thirty seconds
    /// apart: `(seconds after 09:00:00, seconds of silence at that tick)`. The
    /// first row of each call gets no `interval_ms`, which is exactly how the
    /// old trigger marked the first tick of a run and is the only thing the
    /// migration has to find run boundaries with.
    private func insertSamples(machine: String, _ samples: [(Int, Double)],
                               keyDelta: Int64 = 0) throws {
        try db.write { db in
            for (index, sample) in samples.enumerated() {
                let event = UUID().uuidString
                try db.execute(sql: """
                    INSERT INTO context_event (id, machine_id, occurred_at, kind)
                    VALUES (?, ?, ?, 'input')
                    """, arguments: [event, machine, Self.timestamp(offset: sample.0)])
                try db.execute(sql: """
                    INSERT INTO context_event_input
                      (event_id, seconds_since_key, seconds_since_mouse_move,
                       key_count_delta, interval_ms, change)
                    VALUES (?, ?, ?, ?, ?, 'sample')
                    """, arguments: [event, sample.1, sample.1 + 60,
                                     index == 0 ? nil : keyDelta,
                                     index == 0 ? nil : 30_000])
            }
        }
    }

    private func insertLocations(machine: String,
                                 _ fixes: [(Int, Double, Double)]) throws {
        try db.write { db in
            for fix in fixes {
                let event = UUID().uuidString
                try db.execute(sql: """
                    INSERT INTO context_event (id, machine_id, occurred_at, kind)
                    VALUES (?, ?, ?, 'location')
                    """, arguments: [event, machine, Self.timestamp(offset: fix.0)])
                try db.execute(sql: """
                    INSERT INTO context_event_location (event_id, latitude, longitude)
                    VALUES (?, ?, ?)
                    """, arguments: [event, fix.1, fix.2])
            }
        }
    }

    private func inputRows() throws -> [Row] {
        try rows(ofKind: "input", joining: "context_event_input")
    }

    private func locationRows() throws -> [Row] {
        try rows(ofKind: "location", joining: "context_event_location")
    }

    private func rows(ofKind kind: String, joining table: String) throws -> [Row] {
        try db.read { db in
            try Row.fetchAll(db, sql: """
                SELECT e.occurred_at, d.* FROM context_event e
                  JOIN \(table) d ON d.event_id = e.id
                 WHERE e.kind = ?
                 ORDER BY e.occurred_at, e.id
                """, arguments: [kind])
        }
    }

    private static func timestamp(offset seconds: Int) -> String {
        let minute = 9 * 60 + seconds / 60
        return String(format: "2026-08-01T%02d:%02d:%02d.000Z",
                      minute / 60, minute % 60, seconds % 60)
    }

    /// Applies only the migrations up to `version`, so a test can build the
    /// database an older build left behind.
    private func migrate(throughVersion version: Int) throws {
        try SchemaMigrator(database: db)
            .migrate(OlyloSchema.migrations.filter { $0.version <= version })
    }
}
#endif
