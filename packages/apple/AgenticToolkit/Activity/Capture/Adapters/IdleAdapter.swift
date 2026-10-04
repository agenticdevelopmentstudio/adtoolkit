// CoreGraphics (CGEventSource) idle polling — macOS only (c2). iOS compiles
// `NoOpObservationAdapters.swift` instead.
#if os(macOS)
import CoreGraphics
import Foundation

/// Polls system-wide idle time via `CGEventSource` on a main-run-loop `Timer`.
///
/// `Timer.scheduledTimer(withTimeInterval:repeats:)`'s block parameter is
/// `@Sendable`, but the timer itself always fires on the run loop it was
/// scheduled on (the main run loop here, matching every other adapter and the
/// `UsageCollector` heartbeat timer). Same `MainActor.assumeIsolated` pattern
/// as `UsageCollector.start()`'s heartbeat — see `WindowLifecycleAdapter`
/// for the shared rationale.
// Public, and its `IdleSource` witnesses are public too: `olylod`
// constructs this directly and hands it to `UsageCollector`'s public
// initializer as an `IdleSource` — a public type's public conformance to a
// public protocol requires its witnesses be public as well.
@MainActor
public final class IdleAdapter: IdleSource {
    public var onIdle: (() -> Void)?
    public var onActive: (() -> Void)?
    private var timer: Timer?
    private var isIdle = false
    private let threshold: TimeInterval

    public init(threshold: TimeInterval = 180) { self.threshold = threshold }

    public func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }
    public func stop() { timer?.invalidate(); timer = nil }

    private func tick() {
        // kCGAnyInputEventType is `((CGEventType)(~0))` in CGEventTypes.h, i.e.
        // 0xFFFFFFFF -- the same raw value as the enumerated case
        // kCGEventTapDisabledByUserInput, so CGEventType(rawValue: ~0) resolves
        // to a real case (not nil); the force-unwrap cannot trap.
        let idleFor = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .init(rawValue: ~0)!)
        if idleFor >= threshold, !isIdle { isIdle = true; onIdle?() }
        else if idleFor < threshold, isIdle { isIdle = false; onActive?() }
    }
}
#endif
