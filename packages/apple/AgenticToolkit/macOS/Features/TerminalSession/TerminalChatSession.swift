import Combine
import Foundation
import AgenticToolkitCore

/// A `ChatSession` whose other side is a shell: a line sent here is typed into
/// a `TerminalSession`, and what the terminal prints back arrives as a reply.
///
/// Both directions pass through a `TextSubstitutionFilter`, and only whole
/// pieces of text ever do — the line the user finished, the output that has
/// stopped arriving. That is the point of putting a chat in front of the
/// terminal instead of filtering keystrokes: a substitution can't match half a
/// name that hasn't been typed yet, or half a name the shell is partway through
/// printing.
///
/// What is lost in exchange is everything interactive. Tab completion, a line
/// editor, a full-screen program: none of it goes through here, and output
/// drawn on the alternate screen is not reported at all.
@MainActor
public final class TerminalChatSession {

    /// Applied to each line on its way to the terminal (revealing) and to each
    /// reply on its way back (concealing). Takes effect from the next line.
    public var filter: TextSubstitutionFilter

    /// The terminal lines are typed into, or nil when there is none.
    public private(set) weak var terminal: TerminalSession?

    /// How long output has to stop before what arrived counts as one reply.
    /// A shell prints in bursts; without the pause one command's output would
    /// arrive as a dozen fragments.
    private let quietPeriod: RunLoop.SchedulerTimeType.Stride

    private var tracker = TerminalOutputTracker()
    private var outputSubscription: AnyCancellable?
    private var continuation: AsyncStream<ChatEvent>.Continuation?

    public init(
        filter: TextSubstitutionFilter = .identity,
        quietPeriod: RunLoop.SchedulerTimeType.Stride = .milliseconds(300)
    ) {
        self.filter = filter
        self.quietPeriod = quietPeriod
    }

    /// Connects to `terminal`, or disconnects when it is nil. Only output from
    /// this moment on is reported — what was already on screen is history, not
    /// a reply to anything said here.
    public func connect(to terminal: TerminalSession?) {
        guard terminal !== self.terminal || terminal == nil else { return }
        outputSubscription = nil
        self.terminal = terminal
        guard let terminal else { return }

        tracker = TerminalOutputTracker(startingAt: terminal.screenSnapshot())
        outputSubscription = terminal.outputActivity
            .debounce(for: quietPeriod, scheduler: RunLoop.main)
            .sink { [weak self] in self?.reportNewOutput() }
    }

    private func reportNewOutput() {
        guard let terminal, let output = tracker.newOutput(in: terminal.screenSnapshot()) else { return }
        let id = UUID().uuidString
        continuation?.yield(.responseStarted(messageID: id))
        continuation?.yield(.responseDelta(messageID: id, text: filter.concealing(output)))
        continuation?.yield(.responseFinished(messageID: id, stopReason: nil))
    }
}

extension TerminalChatSession: @preconcurrency ChatSession {

    public func events() -> AsyncStream<ChatEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
            // Never `.responding`: a shell has no turns, so the composer is
            // never locked waiting for one to end.
            continuation.yield(.stateChanged(.ready))
        }
    }

    /// Shows `text` as the user wrote it and types its revealed form into the
    /// terminal, followed by Return. A multi-line message goes in as several
    /// lines, the way a paste would.
    public func send(_ text: String) {
        continuation?.yield(.userMessage(ChatMessage(role: .user, text: text)))
        guard let terminal else {
            continuation?.yield(.turnFailed(ChatError(
                message: "Not connected to a terminal.", isRetryable: false)))
            return
        }
        let revealed = filter.revealing(text)
        // The last line is what the shell echoes back onto the prompt row, so
        // it is what the tracker has to recognise and leave out.
        tracker.noteSent(revealed.components(separatedBy: "\n").last ?? revealed)
        terminal.sendInput(revealed.replacingOccurrences(of: "\n", with: "\r") + "\r")
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
