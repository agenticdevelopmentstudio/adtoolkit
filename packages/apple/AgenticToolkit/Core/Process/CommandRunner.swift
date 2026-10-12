//
//  CommandRunner.swift
//  AgenticToolkit
//

import Foundation

/// Runs a helper tool to completion and comes back — draining what it writes,
/// and giving up on it if it will not finish.
///
/// **Both of those are the difference between a failure and a hang.** A
/// `Process` whose output goes to a `Pipe` nothing reads stops the moment the
/// kernel's buffer fills, which is 64 KB in, and the caller waiting for it
/// stops with it: two processes, each waiting for the other, forever. And a
/// tool that simply never exits holds the calling thread for as long as it
/// feels like — which for anything handed an archive off the internet is a
/// decision made by whoever wrote the archive.
///
/// So this drains both streams as they are written and waits against a
/// deadline, and a run that reaches the deadline is terminated and reported as
/// timed out rather than thrown away *(fail-fast)*. It is the whole-output,
/// one-shot shape; a tool to hold a conversation with is `SubprocessChannel`.
///
/// `standardOutput` and `standardError` are installed here, so anything a
/// caller set on them is replaced. The exit is learnt from a
/// `ProcessExitWatch`, never from `Process.waitUntilExit()` — see that type
/// for the wake-up it misses.
public enum CommandRunner {

    /// Why a run could not even start, beyond what `Process.run()` throws.
    public enum LaunchError: Error, LocalizedError, Sendable {

        /// `fcntl(F_SETNOSIGPIPE)` on the stdin pipe failed, with `errno`.
        case cannotGuardStandardInput(errno: Int32)

        public var errorDescription: String? {
            switch self {
            case .cannotGuardStandardInput(let code):
                return "Couldn't guard the child's stdin against SIGPIPE: \(String(cString: strerror(code)))"
            }
        }
    }

    /// What one run amounted to.
    public struct Outcome: Sendable, Equatable {

        /// The process's exit status. Meaningless when `timedOut` — the
        /// process was signalled, so the status describes this code's
        /// impatience rather than the tool's opinion.
        ///
        /// `neverExited` when the process outlived even `SIGKILL`, which is
        /// not hypothetical: a process blocked in an uninterruptible kernel
        /// wait — the classic one being a read against a hung network mount —
        /// cannot be killed and does not reap.
        public let status: Int32

        public let standardOutput: Data
        public let standardError: Data

        /// The run did not finish inside its timeout and was terminated.
        public let timedOut: Bool

        /// A `Watchdog` said stop, and the run was terminated for that reason
        /// rather than for the clock. Kept apart from `timedOut` because the
        /// two report differently: a timeout says how long the caller waited,
        /// an abort says which limit the caller set was reached.
        public let aborted: Bool

        /// `standardError` as trimmed text — what a tool's complaint reads
        /// like when it is put in front of a person.
        public var diagnostics: String {
            (String(bytes: standardError, encoding: .utf8) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        public init(
            status: Int32,
            standardOutput: Data,
            standardError: Data,
            timedOut: Bool,
            aborted: Bool = false
        ) {
            self.status = status
            self.standardOutput = standardOutput
            self.standardError = standardError
            self.timedOut = timedOut
            self.aborted = aborted
        }
    }

    /// A condition polled while the process runs; the first `true` ends the run
    /// the same way the deadline does.
    ///
    /// **Why the runner and not the caller.** Terminating the process is
    /// already this type's job, in two steps with a grace period, and it reads
    /// `terminationStatus` only once it knows the process is gone — a caller
    /// that reached around it to call `terminate()` from a timer of its own
    /// would be a second thread in that sequence, racing a status read that
    /// raises an uncatchable Objective-C exception if it loses.
    ///
    /// A poll rather than a callback because what it is for is watching
    /// something the process does not report: bytes appearing on disk, a
    /// directory growing. Nothing tells you about those; you go and look.
    public struct Watchdog: Sendable {

        /// How often to look. The run is ended within one interval of the
        /// condition becoming true, so this is the resolution of whatever
        /// limit `shouldAbort` enforces — it should be small against that
        /// limit, not against the timeout.
        public let interval: TimeInterval

        /// Called on the waiting thread, never concurrently with itself.
        public let shouldAbort: @Sendable () -> Bool

        public init(interval: TimeInterval, shouldAbort: @escaping @Sendable () -> Bool) {
            self.interval = interval
            self.shouldAbort = shouldAbort
        }
    }

    /// How long the drains and the stdin writer are given to finish once the
    /// process is gone — waits on an EOF or an EPIPE that has already been
    /// posted, bounded anyway in case a grandchild inherited a descriptor.
    private static let settleGrace: TimeInterval = ProcessExitWatch.terminationGrace

    /// `Outcome.status` for a process that never exited at all.
    ///
    /// Distinct from any real exit status, which is 0...255 for an ordinary
    /// exit, and from a signalled one. It is only ever seen alongside
    /// `timedOut`, where the status already means nothing.
    public static let neverExited: Int32 = -1

    /// Runs `process`, returning once it has exited or `timeout` has passed.
    ///
    /// Throws only what `Process.run()` throws — a tool that is not there, or
    /// one this process is not allowed to execute — or a `LaunchError`. A
    /// tool that ran and failed is not an error here; it is an `Outcome` with
    /// a non-zero `status`, because what a failing helper wrote is usually
    /// the whole answer.
    ///
    /// `input`, when given, is the whole of the child's stdin: it is written
    /// after launch, concurrently with the drains, and stdin is closed behind
    /// it — so it may be any size, and a child that decides to prompt sees
    /// EOF and gives up rather than block on a terminal that isn't there. It
    /// is how a secret reaches `security -i` without ever appearing in an
    /// argv that `ps` can show. `Data()` is just that EOF. `nil` leaves stdin
    /// inherited, as `Process` does. A child that exits without reading its
    /// input is fine: the writer gets `EPIPE`, not `SIGPIPE`, and the run
    /// reports the exit as usual.
    public static func runToCompletion(
        _ process: Process,
        input: Data? = nil,
        timeout: TimeInterval,
        watchdog: Watchdog? = nil
    ) throws -> Outcome {
        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        let stdin = try input.map { _ in try guardedStandardInput(for: process) }

        let collected = Collector()
        let outputDrained = drain(output, into: collected, as: .standardOutput)
        let errorsDrained = drain(errors, into: collected, as: .standardError)

        let watch = ProcessExitWatch(process)
        do {
            try process.run()
        } catch {
            output.fileHandleForReading.readabilityHandler = nil
            errors.fileHandleForReading.readabilityHandler = nil
            process.terminationHandler = nil
            throw error
        }
        let inputWritten = stdin.map { feed($0, with: input ?? Data()) }

        var timedOut = false
        var aborted = false
        var didExit = true
        if let watchdog {
            let deadline = Date().addingTimeInterval(timeout)
            while true {
                let remaining = deadline.timeIntervalSinceNow
                guard remaining > 0 else {
                    timedOut = true
                    break
                }
                // The shorter of the two, so neither the poll interval
                // overshoots the deadline nor the deadline delays a poll.
                if watch.waitForExit(timeout: min(watchdog.interval, remaining)) {
                    break
                }
                if watchdog.shouldAbort() {
                    aborted = true
                    break
                }
            }
        } else if !watch.waitForExit(timeout: timeout) {
            timedOut = true
        }

        if timedOut || aborted {
            didExit = watch.stop(process)
        }
        // Both write ends are closed once the process is gone, so these are
        // waits on an EOF that has already been posted; the writer, likewise,
        // has either finished or been handed EPIPE by the dead read end.
        _ = outputDrained.wait(timeout: .now() + settleGrace)
        _ = errorsDrained.wait(timeout: .now() + settleGrace)
        _ = inputWritten?.wait(timeout: .now() + settleGrace)
        output.fileHandleForReading.readabilityHandler = nil
        errors.fileHandleForReading.readabilityHandler = nil

        // **Only when it actually exited.** `Process.terminationStatus` is
        // documented to raise `NSInvalidArgumentException` on a process that
        // is still running, and an Objective-C exception is not catchable from
        // Swift — it is a crash, in the one path that exists to handle a tool
        // behaving badly. Surviving `SIGKILL` sounds impossible and is not:
        // a process stuck in an uninterruptible kernel wait, which is what a
        // read against a wedged network mount produces, neither dies nor
        // reaps. The timeout path is exactly where that shows up, so the
        // guard belongs exactly here *(fail-fast, not fail-crash)*.
        return Outcome(
            status: didExit ? process.terminationStatus : Self.neverExited,
            standardOutput: collected.data(for: .standardOutput),
            standardError: collected.data(for: .standardError),
            timedOut: timedOut,
            aborted: aborted)
    }

    // MARK: - Private

    private enum Stream {
        case standardOutput
        case standardError
    }

    /// A stdin pipe for `process` whose write end cannot raise `SIGPIPE`.
    ///
    /// Per-descriptor (`F_SETNOSIGPIPE`), as `SubprocessChannel` does it,
    /// rather than a process-wide `signal()` that would change every other
    /// write in the host. With the flag set, writing to a pipe whose reader
    /// has exited is an `EPIPE` error from `FileHandle`, which `feed` swallows
    /// — a child that quit before reading its input is a child that quit, and
    /// the run reports that exit.
    private static func guardedStandardInput(for process: Process) throws -> Pipe {
        let pipe = Pipe()
        if fcntl(pipe.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1) == -1 {
            throw LaunchError.cannotGuardStandardInput(errno: errno)
        }
        process.standardInput = pipe
        return pipe
    }

    /// Writes `input` to the child through `pipe` and closes stdin behind it,
    /// off the waiting thread; signals the returned semaphore when done.
    ///
    /// Concurrent with the drains for the same reason they are concurrent
    /// with the child: a pipe is a 64 KB kernel buffer, and a child that
    /// answers as it reads would fill stdout while this thread was still
    /// blocked filling stdin. The parent's copy of the read end is closed
    /// first so the pipe dies with the child, which is what turns a write to
    /// a departed reader into `EPIPE` instead of a wait that never ends.
    private static func feed(_ pipe: Pipe, with input: Data) -> DispatchSemaphore {
        let written = DispatchSemaphore(value: 0)
        try? pipe.fileHandleForReading.close()
        DispatchQueue.global(qos: .default).async {
            let writer = pipe.fileHandleForWriting
            if !input.isEmpty { try? writer.write(contentsOf: input) }
            try? writer.close()
            written.signal()
        }
        return written
    }

    /// Reads `pipe` on Foundation's reader queue until EOF, appending into
    /// `collected`, and signals the returned semaphore when EOF arrives.
    ///
    /// Draining *while* the tool writes is the point: a read that waits for
    /// the process to exit first is the deadlock this type exists to avoid.
    private static func drain(
        _ pipe: Pipe,
        into collected: Collector,
        as stream: Stream
    ) -> DispatchSemaphore {
        let finished = DispatchSemaphore(value: 0)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else {
                handle.readabilityHandler = nil
                finished.signal()
                return
            }
            collected.append(chunk, to: stream)
        }
        return finished
    }

    /// The two buffers, behind one lock.
    ///
    /// Foundation delivers both streams on its own queue, so every append here
    /// is off the calling thread and the two can arrive at once.
    private final class Collector: @unchecked Sendable {

        private let lock = NSLock()
        private var buffers: [Stream: Data] = [:]

        func append(_ chunk: Data, to stream: Stream) {
            lock.withLock { buffers[stream, default: Data()].append(chunk) }
        }

        func data(for stream: Stream) -> Data {
            lock.withLock { buffers[stream] ?? Data() }
        }
    }
}
