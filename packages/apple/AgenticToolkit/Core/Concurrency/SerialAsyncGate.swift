import AgenticDeveloperToolkit
import Foundation
import OSLog

/// Runs async work one job at a time, in the order the jobs arrived.
///
/// An actor is **not** this. Actors are reentrant: an actor method that awaits
/// lets the next call in at the suspension point, so a body containing a network
/// round trip runs concurrently with the next one — which is exactly the case a
/// gate is wanted for. This keeps a handle on the previous job instead, and each
/// arrival waits for it before starting, so the bodies never overlap however long
/// they suspend for.
///
/// **A job holds the gate for at most `timeout`.** A body that never returns —
/// a round parked on a wait that never ends — would otherwise hold every later
/// job behind it for the rest of a daemon's life. Past the timeout the job is
/// cancelled and given up on: the next job starts, and the stuck caller is not
/// answered until its own body returns, if it ever does. The timeout is the
/// backstop, not the budget; every body has its own, shorter, deadline.
///
/// The actor itself is only there to make the handoff safe; all the waiting
/// happens outside it.
public actor SerialAsyncGate {

    /// Longer than any body's own deadline: the account rounds this gate
    /// serializes bound their requests at well under a minute.
    public static let defaultTimeout: TimeInterval = 120

    /// How long a cancelled job is given to leave before the next starts
    /// without it — a body that honours cancellation leaves in milliseconds.
    public static let grace: TimeInterval = 2

    private let timeout: TimeInterval
    private var tail: Task<Void, Never>?

    public init(timeout: TimeInterval = SerialAsyncGate.defaultTimeout) {
        self.timeout = timeout
    }

    /// Runs `body` after every job handed to this gate before it, and answers
    /// with what it returned.
    public func run<Value: Sendable>(_ body: @escaping @Sendable () async -> Value) async -> Value {
        let previous = tail
        let job = Task {
            await previous?.value
            return await body()
        }
        // Assigned before the `await` below, so a second caller arriving while
        // this one waits chains onto `job` rather than onto `previous`. The
        // tail waits for the job only as long as the timeout allows.
        let timeout = timeout
        tail = Task {
            if await job.finished(within: .seconds(timeout)) { return }
            Self.logger.error(
                "a job ran past \(Int(timeout))s and was cancelled; the next job no longer waits for it")
            _ = await job.finished(within: .seconds(Self.grace))
        }
        return await job.value
    }
}

extension SerialAsyncGate: Loggable {
    public static nonisolated let logger = makeLogger()
}
