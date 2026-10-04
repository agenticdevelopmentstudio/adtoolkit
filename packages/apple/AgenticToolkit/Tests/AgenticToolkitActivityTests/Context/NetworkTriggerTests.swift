#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

@MainActor
private final class FakePathSource: NetworkPathSource {
    var onPath: ((NetworkPathSnapshot) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func emit(_ s: NetworkPathSnapshot) { onPath?(s) }
}

private struct ScriptedWiFi: WiFiInfoReading {
    let info: WiFiInfo
    func read() -> WiFiInfo { info }
}

/// A Wi-Fi reader whose answer can change between reads — the roaming case,
/// where the path never moves but the network underneath it does.
private struct MutableWiFi: WiFiInfoReading {
    /// `@unchecked Sendable` earned by a lock — the same idiom as
    /// `MutableFakePermissionGate` in `ContextFakes.swift`, and for the same
    /// reason: `WiFiInfoReading` requires `Sendable`, and a bare mutable box
    /// would be an assertion rather than a guarantee. `read()` is called from
    /// whatever context the trigger's path callback runs on, while the test
    /// body writes `info` between reads.
    final class Box: @unchecked Sendable {
        private let lock = NSLock()
        private var stored = WiFiInfo(ssid: nil, bssid: nil)
        var info: WiFiInfo {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }
    let box: Box
    func read() -> WiFiInfo { box.info }
}

@MainActor
final class NetworkTriggerTests: XCTestCase {
    private func makeTrigger(wifi: WiFiInfo = WiFiInfo(ssid: nil, bssid: nil))
    -> (NetworkTrigger, FakePathSource, () -> [NetworkDetail]) {
        let path = FakePathSource()
        let t = NetworkTrigger(path: path, wifi: ScriptedWiFi(info: wifi),
                               now: { Date(timeIntervalSince1970: 2_500) })
        let rec = Recorder()
        t.onEvent = { d, _ in if case .network(let n) = d { rec.details.append(n) } }
        return (t, path, { rec.details })
    }

    private final class Recorder { var details: [NetworkDetail] = [] }

    func testDeclaresItsKindAndNeedsNoPermissionOfItsOwn() {
        let (t, _, _) = makeTrigger()
        XCTAssertEqual(t.kind, ContextEventKind.network)
        // The SSID needs Location, but the interface type does not — gating the
        // whole trigger on Location would lose the connectivity signal too.
        XCTAssertEqual(t.requiredPermission, ContextPermission.none)
    }

    func testCombinesThePathWithTheWiFiIdentity() throws {
        let (t, path, details) = makeTrigger(wifi: WiFiInfo(ssid: "home", bssid: "aa:bb:cc"))
        try t.start()
        path.emit(NetworkPathSnapshot(interfaceType: .wifi, isSatisfied: true,
                                      isExpensive: false, isConstrained: false))
        XCTAssertEqual(details().count, 1)
        XCTAssertEqual(details()[0].interfaceType, .wifi)
        XCTAssertTrue(details()[0].isSatisfied)
        XCTAssertEqual(details()[0].ssid, "home")
        XCTAssertEqual(details()[0].bssid, "aa:bb:cc")
        XCTAssertEqual(details()[0].isExpensive, false)
    }

    func testReportsANilSSIDRatherThanDroppingTheEventWhenWiFiIsUnreadable() throws {
        // Location not granted, or an Ethernet-only Mac.
        let (t, path, details) = makeTrigger(wifi: WiFiInfo(ssid: nil, bssid: nil))
        try t.start()
        path.emit(NetworkPathSnapshot(interfaceType: .ethernet, isSatisfied: true,
                                      isExpensive: nil, isConstrained: nil))
        XCTAssertEqual(details().count, 1)
        XCTAssertNil(details()[0].ssid)
        XCTAssertEqual(details()[0].interfaceType, .ethernet)
    }

    func testDoesNotRepeatAnUnchangedNetwork() throws {
        let (t, path, details) = makeTrigger(wifi: WiFiInfo(ssid: "home", bssid: "aa"))
        try t.start()
        let snapshot = NetworkPathSnapshot(interfaceType: .wifi, isSatisfied: true,
                                           isExpensive: false, isConstrained: false)
        path.emit(snapshot)
        path.emit(snapshot)
        XCTAssertEqual(details().count, 1, "NWPathMonitor re-reports the same path freely")
    }

    func testReportsMovingBetweenNetworksOnTheSameInterface() throws {
        // The dedup memo has to compare the WHOLE detail, not just the
        // interface type. Walking from the home Wi-Fi to a cafe's leaves the
        // path identical — same `.wifi`, same reachability — and only the SSID
        // moves. That transition is the single most valuable event this trigger
        // produces (it is what "abc network means home" is built on), so a memo
        // keyed on the interface type alone would silently swallow it.
        let box = MutableWiFi.Box()
        box.info = WiFiInfo(ssid: "home", bssid: "aa:bb:cc")
        let path = FakePathSource()
        let t = NetworkTrigger(path: path, wifi: MutableWiFi(box: box),
                               now: { Date(timeIntervalSince1970: 2_500) })
        let rec = Recorder()
        t.onEvent = { d, _ in if case .network(let n) = d { rec.details.append(n) } }

        try t.start()
        let unchangedPath = NetworkPathSnapshot(interfaceType: .wifi, isSatisfied: true,
                                                isExpensive: false, isConstrained: false)
        path.emit(unchangedPath)
        box.info = WiFiInfo(ssid: "cafe", bssid: "dd:ee:ff")
        path.emit(unchangedPath)

        XCTAssertEqual(rec.details.count, 2, "an SSID change is a network change")
        XCTAssertEqual(rec.details.map(\.ssid), ["home", "cafe"])
        XCTAssertEqual(rec.details.map(\.bssid), ["aa:bb:cc", "dd:ee:ff"])
        XCTAssertEqual(rec.details.map(\.interfaceType), [.wifi, .wifi])
    }

    func testReportsGoingOffline() throws {
        let (t, path, details) = makeTrigger()
        try t.start()
        path.emit(NetworkPathSnapshot(interfaceType: .wifi, isSatisfied: true,
                                      isExpensive: false, isConstrained: false))
        path.emit(NetworkPathSnapshot(interfaceType: .none, isSatisfied: false,
                                      isExpensive: nil, isConstrained: nil))
        XCTAssertEqual(details().count, 2)
        XCTAssertFalse(details()[1].isSatisfied)
        XCTAssertEqual(details()[1].interfaceType, .none)
    }

    func testStartsAndStopsTheUnderlyingMonitor() throws {
        let (t, path, details) = makeTrigger()
        try t.start()
        XCTAssertEqual(path.startCount, 1)
        t.stop()
        XCTAssertEqual(path.stopCount, 1)
        path.emit(NetworkPathSnapshot(interfaceType: .wifi, isSatisfied: true,
                                      isExpensive: nil, isConstrained: nil))
        XCTAssertEqual(details().count, 0)
    }

    /// A snapshot already on its way when the owner switched the trigger off.
    ///
    /// `stop()` clears `path.onPath`, which is why the assertion above cannot
    /// see the trigger's own `isRunning` guard at all: the fake has nothing
    /// left to call. `NWPathMonitor` is not so tidy — it hands the handler to
    /// its own queue and `cancel()` does not recall a delivery already in
    /// flight, so a closure captured before the stop still runs after it.
    /// Holding that closure is what reproduces the real race, and the guard
    /// is the only thing standing between it and a row written for a trigger
    /// the owner has turned off.
    func testASnapshotAlreadyInFlightWhenStoppedWritesNothing() throws {
        let (t, path, details) = makeTrigger()
        try t.start()
        let inFlight = try XCTUnwrap(path.onPath, "start() must have subscribed")

        t.stop()
        inFlight(NetworkPathSnapshot(interfaceType: .wifi, isSatisfied: true,
                                     isExpensive: nil, isConstrained: nil))

        XCTAssertEqual(details().count, 0)
    }
}
#endif
