//
//  ProcessExitWatch.swift
//  AgenticToolkit
//

import Foundation

/// Learns that a `Process` has exited the one way that always arrives: a
/// `terminationHandler` installed before launch.
///
/// **`Process.waitUntilExit()` is not that.** On macOS 26.6 it can miss the
/// wake-up for a child that exits within a few milliseconds and park its
/// thread forever — about one call in five against `/usr/bin/true`, about
/// one credential round in a thousand against `security`. The child is gone
/// and reaped by then, so a timeout that watches `isRunning` never fires
/// either. The termination handler is posted by the same reaping and was
/// not seen to miss in 500 runs where `waitUntilExit()` missed 89. One
/// missed wake-up held a credential round open for good and froze every
/// later account switch behind it.
///
/// Create one **before** `run()`: a handler installed after launch can be
/// installed after the exit it was meant to catch. `CommandRunner` is the
/// whole-output form built on this; a caller that owns the process's streams
/// — a pty transcript it scans as it arrives, a stdout passed straight
/// through to its own — watches the exit with this directly.
public final class ProcessExitWatch: @unchecked Sendable {

    /// How long a terminated process is given to die before it is killed.
    ///
    /// A tool that ignores `SIGTERM` is exactly the tool a timeout exists
    /// for, so there has to be a second step; two seconds is long enough for
    /// an honest cleanup handler and short enough that nobody notices.
    public static let terminationGrace: TimeInterval = 2

    private let exited = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var seenExit = false

    /// Installs the handler on `process`, which must not have been launched.
    public init(_ process: Process) {
        precondition(!process.isRunning, "ProcessExitWatch must be installed before run()")
        process.terminationHandler = { [exited] _ in exited.signal() }
    }

    /// Whether the exit has arrived, waiting up to `timeout` for it.
    ///
    /// Once it has, every later call answers `true` at once.
    public func waitForExit(timeout: TimeInterval) -> Bool {
        if hasExited { return true }
        guard exited.wait(timeout: .now() + timeout) == .success else { return false }
        lock.withLock { seenExit = true }
        return true
    }

    /// Ends `process`: `SIGTERM`, a grace, then `SIGKILL` and a second grace.
    ///
    /// `true` when it is gone. `false` is not hypothetical: a process blocked
    /// in an uninterruptible kernel wait — a read against a hung network
    /// mount — neither dies nor reaps, and its `terminationStatus` must not
    /// be read.
    public func stop(_ process: Process) -> Bool {
        if hasExited { return true }
        process.terminate()
        if waitForExit(timeout: Self.terminationGrace) { return true }
        kill(process.processIdentifier, SIGKILL)
        return waitForExit(timeout: Self.terminationGrace)
    }

    private var hasExited: Bool { lock.withLock { seenExit } }
}
