import Foundation
@testable import AgenticToolkitActivity

@MainActor
final class FakeContextTrigger: ContextTrigger {
    let kind: ContextEventKind
    let requiredPermission: ContextPermission
    var onEvent: ((ContextEventDetail, Date) -> Void)?

    private(set) var startCount = 0
    private(set) var stopCount = 0
    var startError: Error?

    /// When set, `start()` emits this event synchronously before returning —
    /// what `PowerTrigger` and `AppFocusTrigger` actually do, and what no fake
    /// did before I-1 (which is why the whole suite was green while every
    /// such opening event was being dropped).
    var emitsDuringStart: Date?

    init(kind: ContextEventKind, requiredPermission: ContextPermission = .none) {
        self.kind = kind
        self.requiredPermission = requiredPermission
    }

    func start() throws {
        if let startError { throw startError }
        startCount += 1
        if let when = emitsDuringStart { emit(at: when) }
    }
    func stop() { stopCount += 1 }

    /// Emits a detail matching `kind`, so a test never has to hand-build one.
    func emit(at when: Date = Date(timeIntervalSince1970: 4_000)) {
        onEvent?(Self.detail(for: kind), when)
    }

    static func detail(for kind: ContextEventKind) -> ContextEventDetail {
        switch kind {
        case .appFocus:
            return .appFocus(AppFocusDetail(bundleID: "b", appName: "A", pid: 1,
                                            executablePath: nil, windowID: nil, windowTitle: nil,
                                            documentPath: nil, documentSize: nil,
                                            documentModifiedAt: nil, documentType: nil))
        case .window:
            return .window(WindowDetail(change: .created, bundleID: "b", appName: "A",
                                        pid: 1, windowID: 2, windowTitle: nil))
        case .network:
            return .network(NetworkDetail(interfaceType: .wifi, isSatisfied: true, ssid: nil,
                                          bssid: nil, isExpensive: nil, isConstrained: nil))
        case .location:
            return .location(LocationDetail(latitude: 1, longitude: 2, horizontalAccuracy: nil,
                                            altitude: nil, verticalAccuracy: nil, speed: nil,
                                            course: nil))
        case .input:
            return .input(InputDetail(change: .sample,
                                      secondsSinceKey: nil, secondsSinceMouseMove: nil,
                                      secondsSinceClick: nil, secondsSinceScroll: nil,
                                      keyCountDelta: nil, mouseCountDelta: nil, intervalMs: nil))
        case .session:
            return .session(SessionDetail(change: .active))
        case .power:
            return .power(PowerDetail(source: .ac, percent: nil, isCharging: nil))
        case .appLifecycle:
            return .appLifecycle(AppLifecycleDetail(
                change: .launched, bundleID: "com.example.app",
                appName: "Example", pid: 1234))
        }
    }
}

/// Answers a fixed status per permission; `nil` entries answer `.granted`.
struct FakePermissionGate: ContextPermissionGate {
    let statuses: [ContextPermission: ContextPermissionState]
    func status(_ permission: ContextPermission) async -> ContextPermissionState {
        statuses[permission] ?? .granted
    }
}

/// Like `FakePermissionGate`, but its answers can change between calls, so a
/// test can simulate a permission being revoked mid-run (`refresh()`).
/// `@unchecked Sendable` guarded by a lock — same idiom as `ResultCollector`
/// in `SettingsStoreTests.swift` — because `ContextPermissionGate` requires
/// `Sendable` and this fake is mutated from test code across an `await`.
final class MutableFakePermissionGate: ContextPermissionGate, @unchecked Sendable {
    private let lock = NSLock()
    private var statuses: [ContextPermission: ContextPermissionState]
    private var grantsOnRequest: [ContextPermission: ContextPermissionState] = [:]
    private var requested: [ContextPermission] = []

    init(statuses: [ContextPermission: ContextPermissionState] = [:]) {
        self.statuses = statuses
    }

    func set(_ permission: ContextPermission, _ state: ContextPermissionState) {
        lock.withLock { statuses[permission] = state }
    }

    /// Makes `request(permission)` move the stored status to `state`, the way
    /// a user answering the real system prompt does. Without this, `request`
    /// only reports the status already there.
    func answersRequest(_ permission: ContextPermission, with state: ContextPermissionState) {
        lock.withLock { grantsOnRequest[permission] = state }
    }

    /// Every permission `request` was actually called for, in order — how a
    /// test proves the daemon did NOT ask the OS for something no opted-in
    /// trigger needs (I-4).
    var requestedPermissions: [ContextPermission] { lock.withLock { requested } }

    func status(_ permission: ContextPermission) async -> ContextPermissionState {
        lock.withLock { statuses[permission] ?? .granted }
    }

    func request(_ permission: ContextPermission) async -> ContextPermissionState {
        lock.withLock {
            requested.append(permission)
            if let answer = grantsOnRequest[permission] { statuses[permission] = answer }
            return statuses[permission] ?? .granted
        }
    }
}

/// A gate that parks inside `status(_:)` until the test answers it.
///
/// `ContextCollector.startIfAllowed` suspends at `await gate.status(...)`, and
/// that suspension releases the main actor. This fake makes that window
/// controllable, so a test can run main-actor work inside it — a settings
/// panel writing `setEnabled(kind, false)` while the collector is mid-start,
/// which is the race that let a trigger begin recording after its owner had
/// switched it off.
///
/// An `actor` rather than a lock-guarded class: the state here is only ever
/// touched through `await`, so isolation is structural and no escape hatch is
/// needed.
actor SuspendingPermissionGate: ContextPermissionGate {
    private var answerContinuation: CheckedContinuation<ContextPermissionState, Never>?
    private var arrivalContinuation: CheckedContinuation<Void, Never>?
    private var isParked = false

    func status(_ permission: ContextPermission) async -> ContextPermissionState {
        await withCheckedContinuation { (continuation: CheckedContinuation<ContextPermissionState, Never>) in
            answerContinuation = continuation
            isParked = true
            arrivalContinuation?.resume()
            arrivalContinuation = nil
        }
    }

    /// Returns once a `status(_:)` call is parked and waiting for an answer.
    func waitUntilAsked() async {
        guard !isParked else { return }
        await withCheckedContinuation { arrivalContinuation = $0 }
    }

    /// Answers the parked `status(_:)` call, letting the collector resume.
    func answer(_ state: ContextPermissionState) {
        isParked = false
        answerContinuation?.resume(returning: state)
        answerContinuation = nil
    }
}
