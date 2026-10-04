#if os(macOS)
import Foundation
import IOKit.ps

/// A seam so the trigger is testable — IOPowerSources cannot be scripted.
public protocol PowerStatusReading: Sendable {
    func read() -> PowerDetail?
}

public struct SystemPowerStatusReader: PowerStatusReading {
    public init() {}

    public func read() -> PowerDetail? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        // A laptop reports an internal battery whose `PowerSourceState` says
        // which it is running on. A desktop reports NO power sources at all —
        // verified on a Mac Studio, where `IOPSCopyPowerSourcesList` returns an
        // empty list — so the loop below finds nothing. That is not an unknown
        // state: a machine with no battery is on wall power by definition, and
        // returning nil there would make the whole trigger silently dead on
        // every desktop in the fleet.
        //
        // "No sources" and "sources that will not describe themselves" are kept
        // apart deliberately: the first is a desktop, the second is IOKit
        // failing, and only the second is genuinely unknown. Collapsing them
        // would label a broken read as AC.
        guard !sources.isEmpty else {
            return PowerDetail(source: .ac, percent: nil, isCharging: nil)
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(blob, source)?
                .takeUnretainedValue() as? [String: Any] else { continue }
            let state = info[kIOPSPowerSourceStateKey] as? String
            let capacity = info[kIOPSCurrentCapacityKey] as? Int
            let max = info[kIOPSMaxCapacityKey] as? Int
            let percent: Int? = {
                guard let capacity, let max, max > 0 else { return nil }
                return Int((Double(capacity) / Double(max) * 100).rounded())
            }()
            return PowerDetail(
                source: state == kIOPSBatteryPowerValue ? .battery : .ac,
                percent: percent,
                isCharging: info[kIOPSIsChargingKey] as? Bool)
        }
        // Sources existed but none described itself — an IOKit failure, not a
        // desktop. Report unknown rather than guessing AC.
        return nil
    }
}

/// Emits a `power` event whenever the power source, charge or charging state
/// changes — not on every poll.
@MainActor
public final class PowerTrigger: ContextTrigger {
    public let kind: ContextEventKind = .power
    public let requiredPermission: ContextPermission = .none
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    private let interval: TimeInterval
    private let reader: any PowerStatusReading
    private let now: () -> Date
    private var timer: Timer?
    private var isRunning = false
    private var last: PowerDetail?

    public init(interval: TimeInterval = 60,
                reader: any PowerStatusReading = SystemPowerStatusReader(),
                now: @escaping () -> Date = { Date() }) {
        self.interval = interval
        self.reader = reader
        self.now = now
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        last = nil
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        // Emit the starting state at once, so the log always opens with a
        // known power state rather than a gap until the first change.
        tick()
    }

    public func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        last = nil
    }

    /// Public so tests drive the poll deterministically.
    public func tick() {
        guard isRunning, let current = reader.read() else { return }
        guard current != last else { return }
        last = current
        onEvent?(.power(current), now())
    }
}
#endif
