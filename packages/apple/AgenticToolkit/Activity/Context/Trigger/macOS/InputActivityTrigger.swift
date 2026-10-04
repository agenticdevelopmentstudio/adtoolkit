#if os(macOS)
import Foundation
import CoreGraphics

/// One reading of the system's input statistics.
public struct InputSample: Sendable, Equatable {
    public let secondsSinceKey: Double?
    public let secondsSinceMouseMove: Double?
    public let secondsSinceClick: Double?
    public let secondsSinceScroll: Double?
    /// Monotonic lifetime counters — meaningful only as differences.
    public let keyCount: Int64?
    public let mouseCount: Int64?

    public init(secondsSinceKey: Double?, secondsSinceMouseMove: Double?,
                secondsSinceClick: Double?, secondsSinceScroll: Double?,
                keyCount: Int64?, mouseCount: Int64?) {
        self.secondsSinceKey = secondsSinceKey
        self.secondsSinceMouseMove = secondsSinceMouseMove
        self.secondsSinceClick = secondsSinceClick
        self.secondsSinceScroll = secondsSinceScroll
        self.keyCount = keyCount
        self.mouseCount = mouseCount
    }
}

/// The seam that keeps `InputActivityTrigger` testable — the real one talks to
/// CoreGraphics, which cannot be made to report a scripted idle time.
@MainActor
public protocol InputStatisticsSource: AnyObject {
    func sample() -> InputSample
}

/// A trigger that can say, on demand, whether the user is present now — so a
/// consumer started mid-absence does not assume presence until the first tick.
/// `nil` means it cannot tell.
@MainActor
public protocol PresenceSampling: AnyObject {
    func samplePresence() -> Bool?
}

@MainActor
public final class SystemInputStatisticsSource: InputStatisticsSource {
    public init() {}

    public func sample() -> InputSample {
        let state = CGEventSourceStateID.combinedSessionState
        return InputSample(
            secondsSinceKey: CGEventSource.secondsSinceLastEventType(state, eventType: .keyDown),
            secondsSinceMouseMove: CGEventSource.secondsSinceLastEventType(state, eventType: .mouseMoved),
            secondsSinceClick: CGEventSource.secondsSinceLastEventType(state, eventType: .leftMouseDown),
            secondsSinceScroll: CGEventSource.secondsSinceLastEventType(state, eventType: .scrollWheel),
            keyCount: Int64(CGEventSource.counterForEventType(state, eventType: .keyDown)),
            mouseCount: Int64(CGEventSource.counterForEventType(state, eventType: .mouseMoved)))
    }
}

/// Reports when the user leaves this machine and when they come back.
///
/// Statistics only: how long since the last key/mouse/scroll event and how many
/// have occurred — never which keys. It therefore needs no Accessibility grant
/// and no event tap, which is why it is the one trigger that can run with no
/// permission at all.
///
/// **A keep-alive, not a log.** The timer is how inactivity is *detected*; it
/// is not what gets recorded. Only two moments are worth writing down — input
/// stopping and input resuming — and everything between them is the absence
/// those two rows already describe between them. The first shipped version
/// emitted on every tick regardless, which put 11,731 rows into four days of
/// database to say that nothing had changed.
///
/// **Both transitions are timestamped at the moment they happened, not at the
/// tick that noticed.** The statistics report seconds-since-last-event, so a
/// tick at 10:05 that finds five minutes of silence knows input stopped at
/// 10:00 and dates the row there. That is what makes an `inactive` row's
/// duration — it runs to the `active` row that ends it — the *true* length of
/// the absence rather than the absence minus one threshold, which is the
/// error `TimelineBuilder` used to document and accept. It also means rows can
/// reach the store slightly out of timestamp order; the store pages by `rowid`
/// and ``TimelineBuilder`` sorts by time, which is where that is reconciled.
@MainActor
public final class InputActivityTrigger: ContextTrigger, PresenceSampling {
    public let kind: ContextEventKind = .input
    public let requiredPermission: ContextPermission = .none
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    /// Seconds of silence after which the user counts as gone.
    ///
    /// Settable while running, because it is a user setting the daemon obeys
    /// (`SettingsStore.inactivityThresholdSeconds`) and changing it must not
    /// require restarting the trigger — restarting it would mean touching the
    /// user's opt-in to change a number. It takes effect at the next tick; an
    /// absence already in progress keeps being measured against whichever
    /// threshold was in force when it was noticed.
    public var idleThreshold: TimeInterval

    private let interval: TimeInterval
    private let source: any InputStatisticsSource
    private let now: () -> Date
    private var timer: Timer?
    private var isRunning = false

    /// The last reading that was actually *written*, and when. The counters
    /// are lifetime totals, so a delta only means anything against the
    /// previous row — not against the previous tick, most of which write
    /// nothing at all.
    private var lastEmitted: (sample: InputSample, at: Date)?

    /// Whether the user was at the machine as of the last tick. `nil` before
    /// the first tick of a run, which is what makes that tick report the state
    /// it finds rather than wait for a change that may be hours away.
    private var wasActive: Bool?

    /// When input last stopped, so the resumption can measure the whole
    /// absence rather than the part of it the poll interval happened to see.
    private var inactiveSince: Date?

    public init(interval: TimeInterval = 30,
                idleThreshold: TimeInterval = TimeInterval(InactivityThreshold.defaultSeconds),
                source: any InputStatisticsSource = SystemInputStatisticsSource(),
                now: @escaping () -> Date = { Date() }) {
        self.interval = interval
        self.idleThreshold = idleThreshold
        self.source = source
        self.now = now
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        lastEmitted = nil
        wasActive = nil
        inactiveSince = nil
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // .common so ticks keep arriving while a menu or window drag has the
        // run loop in a tracking mode — exactly when the user IS active.
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    public func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        lastEmitted = nil
        wasActive = nil
        inactiveSince = nil
    }

    /// Takes one reading and emits an event only if presence changed. Public
    /// so tests drive the trigger deterministically instead of waiting on
    /// wall-clock timer fire.
    public func tick() {
        guard isRunning else { return }
        let at = now()
        let sample = source.sample()
        let silence = Self.silence(in: sample)
        let isActive = silence < idleThreshold

        // A first tick has no transition to report, so it reports the state it
        // found. Without it, a daemon started while the user was already away
        // records nothing until they come back, and the timeline cannot tell
        // an idle machine from one that was switched off.
        guard let previouslyActive = wasActive else {
            wasActive = isActive
            if isActive {
                emit(.active, at: at, sample: sample, idleSeconds: nil)
            } else {
                // Dated `at`, not backdated the way a witnessed transition is:
                // the silence may predate this run by hours, and a row placed
                // before the trigger started would claim to have watched
                // something nobody watched. `idleSeconds` reports how long it
                // had already been quiet, which is the honest form of the same
                // fact and the one a reader can tell apart from a measurement.
                inactiveSince = at
                emit(.inactive, at: at, sample: sample, idleSeconds: silence)
            }
            return
        }
        guard previouslyActive != isActive else { return }
        wasActive = isActive

        if isActive {
            // Backdated to the first new keystroke, which the statistics give
            // directly: `silence` on this tick is small — at most one poll
            // interval — and subtracting it lands on the resumption.
            let resumedAt = at.addingTimeInterval(-silence)
            let absence = inactiveSince.map { max(0, resumedAt.timeIntervalSince($0)) }
            inactiveSince = nil
            emit(.active, at: resumedAt, sample: sample, idleSeconds: absence)
        } else {
            let stoppedAt = at.addingTimeInterval(-silence)
            inactiveSince = stoppedAt
            emit(.inactive, at: stoppedAt, sample: sample, idleSeconds: nil)
        }
    }

    /// Whether the user is at the machine right now, read straight from the
    /// source against the current threshold — without waiting for a tick and
    /// without emitting anything.
    public func samplePresence() -> Bool? {
        Self.silence(in: source.sample()) < idleThreshold
    }

    /// How long the machine has been quiet: the *most recent* of the four
    /// event classes, because any one of them means somebody is there.
    /// Readings the system did not supply are ignored rather than counted as
    /// silence — a missing figure is not evidence of absence.
    ///
    /// All four missing means the trigger has no evidence either way. It
    /// answers "infinitely quiet", so the user reads as away: a source that
    /// tells us nothing must not be able to assert that somebody is present.
    private static func silence(in sample: InputSample) -> TimeInterval {
        let readings = [sample.secondsSinceKey, sample.secondsSinceMouseMove,
                        sample.secondsSinceClick, sample.secondsSinceScroll].compactMap { $0 }
        return readings.min() ?? .greatestFiniteMagnitude
    }

    private func emit(_ change: InputChange, at: Date, sample: InputSample, idleSeconds: Double?) {
        var keyDelta: Int64?
        var mouseDelta: Int64?
        var intervalMs: Int64?
        if let previous = lastEmitted {
            keyDelta = Self.delta(sample.keyCount, previous.sample.keyCount)
            mouseDelta = Self.delta(sample.mouseCount, previous.sample.mouseCount)
            intervalMs = Int64((at.timeIntervalSince(previous.at) * 1000).rounded())
        }
        lastEmitted = (sample, at)

        onEvent?(.input(InputDetail(
            change: change,
            idleSeconds: idleSeconds,
            secondsSinceKey: sample.secondsSinceKey,
            secondsSinceMouseMove: sample.secondsSinceMouseMove,
            secondsSinceClick: sample.secondsSinceClick,
            secondsSinceScroll: sample.secondsSinceScroll,
            keyCountDelta: keyDelta, mouseCountDelta: mouseDelta,
            intervalMs: intervalMs)), at)
    }

    /// Clamped at zero: the counters reset when the window server restarts, and
    /// a negative delta would read as impossible activity.
    private static func delta(_ current: Int64?, _ previous: Int64?) -> Int64? {
        guard let current, let previous else { return nil }
        return max(0, current - previous)
    }
}
#endif
