import AppKit
import SwiftTerm
import AgenticToolkitCore

/// A terminal view that runs behind privacy words: every byte on its way to
/// the shell is revealed, and every byte the shell prints is concealed before
/// SwiftTerm parses it.
///
/// The two choke points are SwiftTerm's own. `send(source:data:)` carries
/// everything that reaches the process — keystrokes, pastes, the terminal's
/// replies to queries, and `TerminalSession.sendInput` — and `dataReceived`
/// carries everything that comes back. Concealing *before* the parser means
/// the buffer, the scrollback, the title and the reported directory all hold
/// the alias, so nothing that reads the terminal afterwards can find the real
/// text in it.
///
/// Input that could still become an alias is held until it diverges or
/// completes, because sending half an alias and the rest later would send the
/// alias itself. Output is held the same way, then flushed after a moment of
/// quiet so a prompt ending in a word's prefix still appears.
///
/// Nothing in it is an accessibility element: a screen reader and an AX client
/// see an empty space where the terminal is.
@MainActor
final class PrivateTerminalView: ThemedTerminalView {

    /// The words both streams pass through. Replacing them flushes what each
    /// stream was holding under the old words first, so nothing is lost.
    var substitutions: TextSubstitutionFilter = .identity {
        didSet {
            guard substitutions != oldValue else { return }
            let pendingInput = input.flush()
            let pendingOutput = output.flush()
            input = StreamingTextSubstitution(filter: substitutions, direction: .revealing)
            output = StreamingTextSubstitution(filter: substitutions, direction: .concealing)
            if !pendingInput.isEmpty { super.send(source: self, data: pendingInput[...]) }
            if !pendingOutput.isEmpty { super.dataReceived(slice: pendingOutput[...]) }
        }
    }

    private var input = StreamingTextSubstitution(filter: .identity, direction: .revealing)
    private var output = StreamingTextSubstitution(filter: .identity, direction: .concealing)
    private var outputFlushTimer: Timer?

    /// How long output may sit held before it is shown as it stands.
    private static let outputQuiet: TimeInterval = 0.15

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        let revealed = input.feed(data)
        guard !revealed.isEmpty else { return }
        super.send(source: source, data: revealed[...])
    }

    override func dataReceived(slice: ArraySlice<UInt8>) {
        let concealed = output.feed(slice)
        if !concealed.isEmpty { super.dataReceived(slice: concealed[...]) }
        scheduleOutputFlush()
    }

    private func scheduleOutputFlush() {
        outputFlushTimer?.invalidate()
        outputFlushTimer = nil
        guard output.isHolding else { return }
        outputFlushTimer = Timer.scheduledTimer(withTimeInterval: Self.outputQuiet, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.flushOutput() }
        }
    }

    private func flushOutput() {
        outputFlushTimer = nil
        let held = output.flush()
        if !held.isEmpty { super.dataReceived(slice: held[...]) }
    }

    // MARK: - Accessibility

    override func isAccessibilityElement() -> Bool { false }
    override func accessibilityChildren() -> [Any]? { [] }
    override func accessibilityRole() -> NSAccessibility.Role? { nil }
    override func accessibilityValue() -> Any? { nil }
    override func accessibilitySelectedText() -> String? { nil }
}
