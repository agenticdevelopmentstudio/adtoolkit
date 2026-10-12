import Combine
import Foundation
import AgenticToolkitCore

/// A `ChatSession` whose other side is a shell: a line sent here is typed into
/// a `TerminalSession`, and what the terminal prints back arrives as a reply.
///
/// The chat changes nothing on the way in or out: it types what was written
/// and reports what the screen shows. A terminal that keeps its contents
/// private does so itself, so its screen — and so every reply read off it —
/// is already what the user is meant to see.
///
/// What is lost against typing into the terminal is everything interactive. Tab completion, a line
/// editor, a full-screen program: none of it goes through here, and output
/// drawn on the alternate screen is not reported at all.
@MainActor
public final class TerminalChatSession {

    /// The terminal lines are typed into, or nil when there is none.
    public private(set) weak var terminal: TerminalSession?

    /// How long output has to stop before what arrived counts as one reply.
    /// A shell prints in bursts; without the pause one command's output would
    /// arrive as a dozen fragments.
    private let quietPeriod: Duration
    /// The longest output waits to be reported while it keeps coming, so a
    /// stream that never pauses — `yes`, `tail -f`, a chatty build — still
    /// reaches the transcript and whoever is waiting on it.
    private let maximumLatency: Duration
    private var quietTask: Task<Void, Never>?
    private var latencyTask: Task<Void, Never>?

    private var tracker = TerminalOutputTracker()
    private var outputSubscription: AnyCancellable?
    private var continuation: AsyncStream<ChatEvent>.Continuation?
    /// Events from before anything listened — a connection made before the
    /// transcript subscribed — handed over when it does.
    private var unsentEvents: [ChatEvent] = []

    /// The caller waiting on output — see ``run(_:settle:timeout:)``.
    private var currentWait: OutputWait?
    /// Replies no caller was waiting for, kept until one asks — so output a
    /// slow command prints after its wait gave up is not lost to the next.
    private var unclaimedOutput: [String] = []

    public init(quietPeriod: Duration = .milliseconds(300), maximumLatency: Duration = .seconds(1)) {
        self.quietPeriod = quietPeriod
        self.maximumLatency = maximumLatency
    }

    /// Connects to `terminal`, or disconnects when it is nil. What the
    /// terminal has already printed — its startup text, and the prompt it is
    /// waiting at — arrives at once as the first reply, so the chat opens on
    /// what the terminal shows rather than on nothing.
    public func connect(to terminal: TerminalSession?) {
        guard terminal !== self.terminal || terminal == nil else { return }
        outputSubscription = nil
        cancelReportTimers()
        self.terminal = terminal
        guard let terminal else { return }

        tracker = TerminalOutputTracker(fromTopOf: terminal.screenSnapshot())
        outputSubscription = terminal.outputActivity
            .sink { [weak self] in self?.outputArrived() }
        reportNewOutput(claimable: false)
    }

    /// Reports once output has been quiet for ``quietPeriod``, or once it has
    /// waited ``maximumLatency``, whichever comes first.
    private func outputArrived() {
        quietTask?.cancel()
        quietTask = Task { [weak self, quietPeriod] in
            try? await Task.sleep(for: quietPeriod)
            guard !Task.isCancelled else { return }
            self?.flushOutput()
        }
        guard latencyTask == nil else { return }
        latencyTask = Task { [weak self, maximumLatency] in
            try? await Task.sleep(for: maximumLatency)
            guard !Task.isCancelled else { return }
            self?.flushOutput()
        }
    }

    private func flushOutput() {
        cancelReportTimers()
        reportNewOutput()
    }

    private func cancelReportTimers() {
        quietTask?.cancel()
        quietTask = nil
        latencyTask?.cancel()
        latencyTask = nil
    }

    /// - Parameter claimable: Whether the output can be a reply a caller of
    ///   ``run(_:settle:timeout:)`` is waiting for. What was on screen before
    ///   connecting never is.
    private func reportNewOutput(claimable: Bool = true) {
        guard let terminal, let output = tracker.newOutput(in: terminal.screenSnapshot()) else { return }
        let id = UUID().uuidString
        yield(.responseStarted(messageID: id))
        yield(.responseDelta(messageID: id, text: output))
        yield(.responseFinished(messageID: id, stopReason: nil))
        guard claimable else { return }
        if let currentWait {
            currentWait.received(output)
        } else {
            unclaimedOutput.append(output)
        }
    }

    // MARK: - Driven by another agent

    /// Sends `text` exactly as ``send(_:)`` does — it shows in the transcript
    /// as typed — and returns what the terminal printed in reply.
    ///
    /// For a caller that is not a person reading the transcript: a persona
    /// chat whose tool types into this one. The reply is everything reported
    /// until output has been quiet for `settle`; a command still printing at
    /// `timeout` returns what it had, marked as still running, and the rest is
    /// kept for ``waitForOutput(settle:timeout:)``.
    public func run(
        _ text: String,
        settle: Duration = .milliseconds(1500),
        timeout: Duration = .seconds(60)
    ) async -> String {
        guard terminal != nil else { return Self.notConnected }
        let wait = beginWait(settle: settle, timeout: timeout)
        send(text)
        return await wait.result()
    }

    /// Output reported since the last caller stopped listening, plus whatever
    /// arrives until it has been quiet for `settle` — for a command that
    /// outlasted ``run(_:settle:timeout:)``.
    public func waitForOutput(
        settle: Duration = .milliseconds(1500),
        timeout: Duration = .seconds(30)
    ) async -> String {
        guard terminal != nil else { return Self.notConnected }
        return await beginWait(settle: settle, timeout: timeout).result()
    }

    /// Control-C, then whatever the terminal printed in response.
    public func interruptAndWait(
        settle: Duration = .milliseconds(1000),
        timeout: Duration = .seconds(10)
    ) async -> String {
        guard terminal != nil else { return Self.notConnected }
        let wait = beginWait(settle: settle, timeout: timeout)
        interrupt()
        return await wait.result()
    }

    /// The last `lines` lines on the terminal's screen — what is there now,
    /// prompt included, rather than a reply to anything. Nil when
    /// there is no terminal.
    public func screen(lines: Int = 40) -> String? {
        guard let terminal else { return nil }
        var rows = terminal.screenSnapshot().lines
        while rows.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { rows.removeLast() }
        return rows.suffix(max(lines, 1)).joined(separator: "\n")
    }

    private static let notConnected = "The Terminal Chat is not connected to a terminal."

    private func yield(_ event: ChatEvent) {
        if let continuation { continuation.yield(event) } else { unsentEvents.append(event) }
    }

    /// One caller at a time: a new wait ends the previous one with what it
    /// had, and starts from the output nobody claimed.
    private func beginWait(settle: Duration, timeout: Duration) -> OutputWait {
        currentWait?.finish()
        let wait = OutputWait(settle: settle, timeout: timeout) { [weak self] finished in
            if self?.currentWait === finished { self?.currentWait = nil }
        }
        for text in unclaimedOutput { wait.received(text) }
        unclaimedOutput.removeAll()
        currentWait = wait
        return wait
    }
}

/// Collects replies until they stop coming, then hands them to whoever is
/// awaiting ``result()``.
@MainActor
private final class OutputWait {
    private var output: [String] = []
    private var finished: String?
    private var waiters: [CheckedContinuation<String, Never>] = []
    private var settleTask: Task<Void, Never>?
    private var deadlineTask: Task<Void, Never>?
    private let settle: Duration
    private let onFinish: (OutputWait) -> Void

    /// - Parameter settle: Held to half of `timeout`, so output that stops
    ///   early is always judged finished before the deadline judges it still
    ///   running — a settle as long as the timeout would lose every race.
    init(settle: Duration, timeout: Duration, onFinish: @escaping (OutputWait) -> Void) {
        self.settle = min(settle, timeout / 2)
        self.onFinish = onFinish
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            self?.finish(stillRunning: true)
        }
    }

    func received(_ text: String) {
        guard finished == nil else { return }
        output.append(text)
        settleTask?.cancel()
        settleTask = Task { [weak self, settle] in
            try? await Task.sleep(for: settle)
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    func finish(stillRunning: Bool = false) {
        guard finished == nil else { return }
        settleTask?.cancel()
        deadlineTask?.cancel()
        var text = output.joined(separator: "\n")
        if text.isEmpty { text = "(no output)" }
        if stillRunning {
            text += "\n[still running — wait for more output, or interrupt it]"
        }
        finished = text
        for waiter in waiters { waiter.resume(returning: text) }
        waiters.removeAll()
        onFinish(self)
    }

    func result() async -> String {
        if let finished { return finished }
        return await withCheckedContinuation { waiters.append($0) }
    }
}

extension TerminalChatSession: @preconcurrency ChatSession {

    public func events() -> AsyncStream<ChatEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
            // Never `.responding`: a shell has no turns, so the composer is
            // never locked waiting for one to end.
            continuation.yield(.stateChanged(.ready))
            for event in self.unsentEvents { continuation.yield(event) }
            self.unsentEvents.removeAll()
        }
    }

    /// Shows `text` as the user wrote it and types it into the terminal,
    /// followed by Return. A multi-line message goes in as several
    /// lines, the way a paste would.
    public func send(_ text: String) {
        continuation?.yield(.userMessage(ChatMessage(role: .user, text: text)))
        guard let terminal else {
            continuation?.yield(.turnFailed(ChatError(
                message: "Not connected to a terminal.", isRetryable: false)))
            return
        }
        // The last line is what the shell echoes back onto the prompt row, so
        // it is what the tracker has to recognise and leave out — as the
        // terminal shows it, which a private terminal may have changed.
        let echoed = terminal.presentable(text)
        tracker.noteSent(echoed.components(separatedBy: "\n").last ?? echoed)
        terminal.sendInput(text.replacingOccurrences(of: "\n", with: "\r") + "\r")
    }

    /// Control-C, which is what interrupting a terminal means.
    public func interrupt() {
        terminal?.sendInput("\u{03}")
    }

    public func close() {
        connect(to: nil)
        continuation?.finish()
        continuation = nil
    }
}
