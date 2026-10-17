import Foundation

/// The daemon a launch job manages: its launchd job, plist, HTTP port and
/// stop marker. Pure values, so one set of jobs serves any daemon.
public struct DaemonTarget: Sendable, Equatable {
    /// How progress text and job titles name the daemon ("Starting the \(name) daemon").
    public var name: String
    public var label: String
    public var plistURL: URL
    public var httpPort: Int
    public var stopMarkerURL: URL
    /// Earlier labels whose jobs may still be shutting down; a restart waits for
    /// them to leave instead of killing a daemon that cannot yet be replaced.
    public var supersededLabels: [String]

    public init(name: String, label: String, plistURL: URL, httpPort: Int, stopMarkerURL: URL,
                supersededLabels: [String] = []) {
        self.name = name
        self.label = label
        self.plistURL = plistURL
        self.httpPort = httpPort
        self.stopMarkerURL = stopMarkerURL
        self.supersededLabels = supersededLabels
    }
}

/// A deadline-bounded poll of a daemon, shared by the launch's waits for it so
/// they bound time, not attempts, the same way.
public struct DaemonPoll: Sendable {
    public var interval: Duration
    public var sleep: @Sendable (Duration) async throws -> Void
    public var now: @Sendable () -> ContinuousClock.Instant

    public init(interval: Duration = .milliseconds(500),
                sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
                now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }) {
        self.interval = interval
        self.sleep = sleep
        self.now = now
    }

    /// Asks at least once, then again every `interval` until `done` or the
    /// deadline, and returns the last answer. A sleep that throws (the launch
    /// was cancelled) ends the poll at once. `waiting` runs once, before the
    /// first sleep, so a caller can say what the pause is for.
    public func ask<Answer: Sendable>(_ ask: @Sendable () async -> Answer, until done: (Answer) -> Bool,
                                      deadline: ContinuousClock.Instant,
                                      waiting: () async -> Void = {}) async -> Answer {
        var answer = await ask()
        var noted = false
        while !done(answer), now() < deadline {
            if !noted {
                await waiting()
                noted = true
            }
            guard (try? await sleep(interval)) != nil else { break }
            answer = await ask()
        }
        return answer
    }
}
