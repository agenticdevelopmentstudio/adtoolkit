#if os(macOS)
import CoreWLAN
import Foundation
import Network

public struct NetworkPathSnapshot: Sendable, Equatable {
    public let interfaceType: NetworkInterfaceType
    public let isSatisfied: Bool
    public let isExpensive: Bool?
    public let isConstrained: Bool?

    public init(interfaceType: NetworkInterfaceType, isSatisfied: Bool,
                isExpensive: Bool?, isConstrained: Bool?) {
        self.interfaceType = interfaceType; self.isSatisfied = isSatisfied
        self.isExpensive = isExpensive; self.isConstrained = isConstrained
    }
}

@MainActor
public protocol NetworkPathSource: AnyObject {
    var onPath: ((NetworkPathSnapshot) -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
public final class SystemNetworkPathSource: NetworkPathSource {
    public var onPath: ((NetworkPathSnapshot) -> Void)?
    private var monitor: NWPathMonitor?
    public init() {}

    public func start() {
        let m = NWPathMonitor()
        m.pathUpdateHandler = { [weak self] path in
            let snapshot = NetworkPathSnapshot(
                interfaceType: Self.interfaceType(path),
                isSatisfied: path.status == .satisfied,
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained)
            // NWPathMonitor calls back on its own queue; every trigger hands
            // events over on the main actor.
            //
            // `DispatchQueue.main.async`, not an unstructured `Task`: tasks
            // enqueued onto an actor carry no ordering guarantee relative to
            // each other, so two path updates a few milliseconds apart could
            // arrive at the trigger in the order they were *not* observed. The
            // trigger deduplicates against the last detail it saw, so an
            // out-of-order pair leaves `last` holding the older path and the
            // next genuine change to the newer one is then dropped as
            // unchanged. Main-queue dispatch is FIFO, which is the property
            // needed here — the same handover `WindowLifecycleAdapter` uses.
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated { self?.onPath?(snapshot) }
            }
        }
        m.start(queue: DispatchQueue(label: "app.olylo.network-path"))
        monitor = m
    }

    public func stop() {
        monitor?.cancel()
        monitor = nil
    }

    // `nonisolated` because it is called from `pathUpdateHandler`, which
    // NWPathMonitor invokes on its own queue rather than the main actor; the
    // function touches no instance state, so nonisolated is sound.
    private nonisolated static func interfaceType(_ path: NWPath) -> NetworkInterfaceType {
        guard path.status == .satisfied else { return .none }
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        if path.usesInterfaceType(.cellular) { return .cellular }
        return .other
    }
}

public struct WiFiInfo: Sendable, Equatable {
    public let ssid: String?
    public let bssid: String?
    public init(ssid: String?, bssid: String?) { self.ssid = ssid; self.bssid = bssid }
}

public protocol WiFiInfoReading: Sendable {
    func read() -> WiFiInfo
}

public struct SystemWiFiInfoReader: WiFiInfoReading {
    public init() {}
    /// Returns nils rather than failing when Location is not authorized —
    /// macOS answers `nil` for both fields in that case, which is exactly the
    /// "we don't know" the schema records.
    public func read() -> WiFiInfo {
        let interface = CWWiFiClient.shared().interface()
        return WiFiInfo(ssid: interface?.ssid(), bssid: interface?.bssid())
    }
}

/// Emits a `network` event whenever the reachable network changes.
///
/// `requiredPermission` is `.none` even though the SSID needs Location: the
/// interface type and reachability are useful on their own, so a missing
/// Location grant degrades the event rather than suppressing it.
@MainActor
public final class NetworkTrigger: ContextTrigger {
    public let kind: ContextEventKind = .network
    public let requiredPermission: ContextPermission = .none
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    private let path: any NetworkPathSource
    private let wifi: any WiFiInfoReading
    private let now: () -> Date
    private var isRunning = false
    private var last: NetworkDetail?

    public init(path: any NetworkPathSource = SystemNetworkPathSource(),
                wifi: any WiFiInfoReading = SystemWiFiInfoReader(),
                now: @escaping () -> Date = { Date() }) {
        self.path = path
        self.wifi = wifi
        self.now = now
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        last = nil
        path.onPath = { [weak self] snapshot in self?.emit(snapshot) }
        path.start()
    }

    public func stop() {
        isRunning = false
        path.onPath = nil
        path.stop()
        last = nil
    }

    private func emit(_ snapshot: NetworkPathSnapshot) {
        guard isRunning else { return }
        let identity = wifi.read()
        let detail = NetworkDetail(interfaceType: snapshot.interfaceType,
                                   isSatisfied: snapshot.isSatisfied,
                                   ssid: identity.ssid, bssid: identity.bssid,
                                   isExpensive: snapshot.isExpensive,
                                   isConstrained: snapshot.isConstrained)
        // NWPathMonitor re-reports an unchanged path on unrelated interface
        // churn; only actual changes are events.
        guard detail != last else { return }
        last = detail
        onEvent?(.network(detail), now())
    }
}
#endif
