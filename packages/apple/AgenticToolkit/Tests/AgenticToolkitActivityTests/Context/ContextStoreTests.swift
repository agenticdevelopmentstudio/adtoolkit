#if os(macOS)
import XCTest
import GRDB
import AgenticToolkitDatabase
@testable import AgenticToolkitActivity

final class ContextStoreTests: XCTestCase {
    private var dir: URL!
    private var db: BoundedDatabase!
    private var store: ContextStore!
    private let machineID = UUID()

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-ctxstore-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        db = try BoundedDatabase(path: dir.appendingPathComponent("test.sqlite").path)
        store = ContextStore(database: db)
        try store.runMigrations()
        try store.upsertMachine(
            MachineDescriptor(id: machineID, platform: .macOS, nativeID: "NATIVE",
                              nativeIDKind: .ioPlatformUUID, hostname: "h", model: "m",
                              osVersion: "26.0"),
            seenAt: Date(timeIntervalSince1970: 1_000))
    }

    override func tearDownWithError() throws {
        store = nil; db = nil
        try? FileManager.default.removeItem(at: dir)
    }

    private func event(_ detail: ContextEventDetail,
                       at t: TimeInterval = 2_000) -> ContextEvent {
        ContextEvent(machineID: machineID, occurredAt: Date(timeIntervalSince1970: t),
                     detail: detail)
    }

    func testMigrationCreatesEveryTable() throws {
        try db.read { db in
            for table in ["machine", "machine_link", "context_event"] {
                XCTAssertTrue(try db.tableExists(table), "missing \(table)")
            }
            for kind in ContextEventKind.allCases {
                XCTAssertTrue(try db.tableExists(kind.detailTable), "missing \(kind.detailTable)")
            }
        }
    }

    func testMigrationIsIdempotent() throws {
        try store.runMigrations()   // must not throw on a second run
        XCTAssertEqual(try store.eventCount(kind: nil), 0)
    }

    func testUpsertMachineKeepsFirstSeenAndAdvancesLastSeen() throws {
        try store.upsertMachine(
            MachineDescriptor(id: machineID, platform: .macOS, nativeID: "NATIVE",
                              nativeIDKind: .ioPlatformUUID, hostname: "h2", model: "m",
                              osVersion: "26.1"),
            seenAt: Date(timeIntervalSince1970: 5_000))
        try db.read { db in
            let row = try Row.fetchOne(db, sql: "SELECT * FROM machine WHERE id = ?",
                                       arguments: [machineID.uuidString])
            XCTAssertNotNil(row)
            XCTAssertEqual(row?["first_seen_at"] as String?, "1970-01-01T00:16:40.000Z")
            XCTAssertEqual(row?["last_seen_at"] as String?, "1970-01-01T01:23:20.000Z")
            XCTAssertEqual(row?["hostname"] as String?, "h2", "mutable facts refresh")
            XCTAssertEqual(row?["os_version"] as String?, "26.1")
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM machine"), 1)
        }
    }

    func testUpsertMachineLastSeenAtIsMonotonic() throws {
        // setUp already seeded last_seen_at = 1_000 for machineID.
        try store.upsertMachine(
            MachineDescriptor(id: machineID, platform: .macOS, nativeID: "NATIVE",
                              nativeIDKind: .ioPlatformUUID, hostname: "h3", model: "m",
                              osVersion: "26.2"),
            seenAt: Date(timeIntervalSince1970: 9_000))
        // Replayed/out-of-order call with an OLDER seenAt than the 9_000 just recorded.
        try store.upsertMachine(
            MachineDescriptor(id: machineID, platform: .macOS, nativeID: "NATIVE",
                              nativeIDKind: .ioPlatformUUID, hostname: "h4", model: "m",
                              osVersion: "26.3"),
            seenAt: Date(timeIntervalSince1970: 500))
        try db.read { db in
            let row = try Row.fetchOne(db, sql: "SELECT * FROM machine WHERE id = ?",
                                       arguments: [machineID.uuidString])
            XCTAssertEqual(row?["last_seen_at"] as String?, "1970-01-01T02:30:00.000Z",
                           "an older seenAt must not walk last_seen_at backward")
            XCTAssertEqual(row?["hostname"] as String?, "h4", "mutable facts still refresh")
        }
    }

    func testInsertWritesHeaderAndDetailForEveryKind() throws {
        let details: [ContextEventDetail] = [
            .appFocus(AppFocusDetail(bundleID: "com.apple.dt.Xcode", appName: "Xcode", pid: 42,
                                     executablePath: "/x", windowID: 9, windowTitle: "main.swift",
                                     documentPath: "/tmp/main.swift", documentSize: 1234,
                                     documentModifiedAt: Date(timeIntervalSince1970: 3_000),
                                     documentType: "public.swift-source")),
            .window(WindowDetail(change: .titleChanged, bundleID: "b", appName: "A", pid: 1,
                                 windowID: 3, windowTitle: "T")),
            .network(NetworkDetail(interfaceType: .wifi, isSatisfied: true, ssid: "home",
                                   bssid: "aa:bb", isExpensive: false, isConstrained: nil)),
            .location(LocationDetail(latitude: 47.6, longitude: -122.3, horizontalAccuracy: 5,
                                     altitude: 40, verticalAccuracy: 3, speed: 0, course: -1)),
            .input(InputDetail(change: .sample, secondsSinceKey: 1.5, secondsSinceMouseMove: 0.2,
                               secondsSinceClick: 9, secondsSinceScroll: nil,
                               keyCountDelta: 12, mouseCountDelta: 300, intervalMs: 5_000)),
            .session(SessionDetail(change: .unlock)),
            .power(PowerDetail(source: .battery, percent: 88, isCharging: false)),
            .appLifecycle(AppLifecycleDetail(change: .terminated, bundleID: "com.apple.dt.Xcode",
                                             appName: "Xcode", pid: 501)),
        ]
        for d in details { try store.insert(event(d)) }

        XCTAssertEqual(try store.eventCount(kind: nil), details.count)
        for kind in ContextEventKind.allCases {
            XCTAssertEqual(try store.eventCount(kind: kind), 1, "no header for \(kind)")
            try db.read { db in
                XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(kind.detailTable)"),
                               1, "no detail row for \(kind)")
            }
        }
    }

    func testAppFocusDetailRoundTripsEveryColumn() throws {
        try store.insert(event(.appFocus(AppFocusDetail(
            bundleID: "com.apple.dt.Xcode", appName: "Xcode", pid: 42, executablePath: "/x",
            windowID: 9, windowTitle: "main.swift", documentPath: "/tmp/main.swift",
            documentSize: 1234, documentModifiedAt: Date(timeIntervalSince1970: 3_000),
            documentType: "public.swift-source", url: "https://example.org/page"))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_app_focus"))
            XCTAssertEqual(row["bundle_id"] as String?, "com.apple.dt.Xcode")
            XCTAssertEqual(row["app_name"] as String?, "Xcode")
            XCTAssertEqual(row["pid"] as Int?, 42)
            XCTAssertEqual(row["executable_path"] as String?, "/x")
            XCTAssertEqual(row["window_id"] as Int?, 9)
            XCTAssertEqual(row["window_title"] as String?, "main.swift")
            XCTAssertEqual(row["document_path"] as String?, "/tmp/main.swift")
            XCTAssertEqual(row["document_size"] as Int64?, 1234)
            XCTAssertEqual(row["document_modified_at"] as String?, "1970-01-01T00:50:00.000Z")
            XCTAssertEqual(row["document_type"] as String?, "public.swift-source")
            XCTAssertEqual(row["url"] as String?, "https://example.org/page")
        }
    }

    func testWindowDetailRoundTripsEveryColumn() throws {
        try store.insert(event(.window(WindowDetail(
            change: .destroyed, bundleID: "com.olylo.window", appName: "WindowApp", pid: 77,
            windowID: 501, windowTitle: "Doc Window"))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_window"))
            XCTAssertEqual(row["change"] as String?, "destroyed")
            XCTAssertEqual(row["bundle_id"] as String?, "com.olylo.window")
            XCTAssertEqual(row["app_name"] as String?, "WindowApp")
            XCTAssertEqual(row["pid"] as Int?, 77)
            XCTAssertEqual(row["window_id"] as Int?, 501)
            XCTAssertEqual(row["window_title"] as String?, "Doc Window")
        }
    }

    func testNetworkDetailRoundTripsEveryColumn() throws {
        try store.insert(event(.network(NetworkDetail(
            interfaceType: .cellular, isSatisfied: true, ssid: "round-trip-net",
            bssid: "11:22:33:44:55:66", isExpensive: false, isConstrained: true))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_network"))
            XCTAssertEqual(row["interface_type"] as String?, "cellular")
            XCTAssertEqual(row["is_satisfied"] as Int?, 1)
            XCTAssertEqual(row["ssid"] as String?, "round-trip-net")
            XCTAssertEqual(row["bssid"] as String?, "11:22:33:44:55:66")
            XCTAssertEqual(row["is_expensive"] as Int?, 0)
            XCTAssertEqual(row["is_constrained"] as Int?, 1)
        }
    }

    func testLocationDetailRoundTripsEveryColumn() throws {
        try store.insert(event(.location(LocationDetail(
            latitude: 10.1, longitude: 20.2, horizontalAccuracy: 3.3, altitude: 40.4,
            verticalAccuracy: 5.5, speed: 6.6, course: 70.7))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_location"))
            XCTAssertEqual(row["latitude"] as Double?, 10.1)
            XCTAssertEqual(row["longitude"] as Double?, 20.2)
            XCTAssertEqual(row["horizontal_accuracy"] as Double?, 3.3)
            XCTAssertEqual(row["altitude"] as Double?, 40.4)
            XCTAssertEqual(row["vertical_accuracy"] as Double?, 5.5)
            XCTAssertEqual(row["speed"] as Double?, 6.6)
            XCTAssertEqual(row["course"] as Double?, 70.7)
        }
    }

    func testInputDetailRoundTripsEveryColumn() throws {
        try store.insert(event(.input(InputDetail(
            change: .active, idleSeconds: 240,
            secondsSinceKey: 1.1, secondsSinceMouseMove: 2.2, secondsSinceClick: 3.3,
            secondsSinceScroll: 4.4, keyCountDelta: 11, mouseCountDelta: 22, intervalMs: 3_333))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_input"))
            XCTAssertEqual(row["change"] as String?, "active")
            XCTAssertEqual(row["idle_seconds"] as Double?, 240)
            XCTAssertEqual(row["seconds_since_key"] as Double?, 1.1)
            XCTAssertEqual(row["seconds_since_mouse_move"] as Double?, 2.2)
            XCTAssertEqual(row["seconds_since_click"] as Double?, 3.3)
            XCTAssertEqual(row["seconds_since_scroll"] as Double?, 4.4)
            XCTAssertEqual(row["key_count_delta"] as Int64?, 11)
            XCTAssertEqual(row["mouse_count_delta"] as Int64?, 22)
            XCTAssertEqual(row["interval_ms"] as Int64?, 3_333)
        }
    }

    func testSessionDetailRoundTripsEveryColumn() throws {
        try store.insert(event(.session(SessionDetail(change: .wake))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_session"))
            XCTAssertEqual(row["change"] as String?, "wake")
        }
    }

    func testPowerDetailRoundTripsEveryColumn() throws {
        try store.insert(event(.power(PowerDetail(source: .ac, percent: 73, isCharging: true))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_power"))
            XCTAssertEqual(row["source"] as String?, "ac")
            XCTAssertEqual(row["percent"] as Int?, 73)
            XCTAssertEqual(row["is_charging"] as Int?, 1)
        }
    }

    func testTimestampsAreISO8601UTCStrings() throws {
        try store.insert(event(.session(SessionDetail(change: .lock)), at: 1_700_000_000))
        try db.read { db in
            XCTAssertEqual(try String.fetchOne(db, sql: "SELECT occurred_at FROM context_event"),
                           "2023-11-14T22:13:20.000Z")
        }
    }

    /// M-3: without fractional seconds, two events milliseconds apart share a
    /// byte-identical `occurred_at` and their order is unrecoverable.
    func testTimestampsCarryFractionalSecondsSoSameSecondEventsStillOrder() throws {
        try store.insert(event(.session(SessionDetail(change: .lock)), at: 1_700_000_000.25))
        try store.insert(event(.session(SessionDetail(change: .active)), at: 1_700_000_000.75))
        try db.read { db in
            let stamps = try String.fetchAll(
                db, sql: "SELECT occurred_at FROM context_event ORDER BY occurred_at")
            XCTAssertEqual(stamps, ["2023-11-14T22:13:20.250Z", "2023-11-14T22:13:20.750Z"])
        }
    }

    /// M-3: the tie-break for events that genuinely share a timestamp is
    /// SQLite's implicit `rowid` — `context_event` is an ordinary rowid table
    /// and `id` is a random UUID, so `ORDER BY occurred_at, rowid` is the
    /// documented recovery and no sequence column is needed.
    func testSameInstantEventsStayOrderedByRowID() throws {
        let first = event(.session(SessionDetail(change: .lock)), at: 1_700_000_000)
        let second = event(.session(SessionDetail(change: .active)), at: 1_700_000_000)
        try store.insert(first)
        try store.insert(second)
        try db.read { db in
            let ids = try String.fetchAll(
                db, sql: "SELECT id FROM context_event ORDER BY occurred_at, rowid")
            XCTAssertEqual(ids, [first.id.uuidString, second.id.uuidString])
        }
    }

    func testBoolsArePersistedAsZeroOrOne() throws {
        try store.insert(event(.network(NetworkDetail(interfaceType: .wifi, isSatisfied: true,
                                                      ssid: nil, bssid: nil, isExpensive: false,
                                                      isConstrained: nil))))
        try db.read { db in
            let row = try XCTUnwrap(Row.fetchOne(db, sql: "SELECT * FROM context_event_network"))
            XCTAssertEqual(row["is_satisfied"] as Int?, 1)
            XCTAssertEqual(row["is_expensive"] as Int?, 0)
            XCTAssertNil(row["is_constrained"] as Int?)
        }
    }

    func testInsertingAnEventForAnUnknownMachineFails() throws {
        // The foreign key is what guarantees every event is attributable to a
        // device — without enforcement a fleet sync silently orphans rows.
        XCTAssertThrowsError(try store.insert(
            ContextEvent(machineID: UUID(), occurredAt: Date(),
                         detail: .session(SessionDetail(change: .lock)))))
    }

    func testLinkMachinesRecordsTheJoinWithoutTouchingEvents() throws {
        let other = UUID()
        try store.upsertMachine(
            MachineDescriptor(id: other, platform: .iOS, nativeID: "IDFV", nativeIDKind: .idfv,
                              hostname: nil, model: "iPhone", osVersion: "26.0"),
            seenAt: Date(timeIntervalSince1970: 1_000))
        try store.insert(event(.session(SessionDetail(change: .lock))))
        try store.linkMachines(machineID, other, at: Date(timeIntervalSince1970: 9_000),
                               note: "same person")
        try db.read { db in
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM machine_link"), 1)
            XCTAssertEqual(try String.fetchOne(db, sql: "SELECT machine_id FROM context_event"),
                           machineID.uuidString, "linking must never rewrite event rows")
        }
    }

    func testInsertRollsBackOnDuplicateIDLeavingNoOrphanDetailRow() throws {
        let original = event(.session(SessionDetail(change: .lock)))
        try store.insert(original)

        // Reuses `original.id` with a DIFFERENT kind, so a stray write into
        // context_event_power (rather than a clean rejection before any detail
        // write) would prove the header/detail writes are not one transaction.
        let duplicate = ContextEvent(id: original.id, machineID: machineID,
                                     occurredAt: Date(timeIntervalSince1970: 3_000),
                                     detail: .power(PowerDetail(source: .ac, percent: 50,
                                                                isCharging: true)))
        XCTAssertThrowsError(try store.insert(duplicate))

        XCTAssertEqual(try store.eventCount(kind: nil), 1, "the failed insert must not add a row")
        try db.read { db in
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM context_event_session"), 1)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM context_event_power"), 0,
                           "no orphan detail row for the rejected insert")
        }
    }
}
#endif
