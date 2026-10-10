import Foundation

/// A terminal's rendered text at one moment: scrollback plus screen, a line per
/// row, with escape sequences already resolved into what is drawn.
///
/// Rows are numbered *scroll-invariantly* — counted from the first line the
/// terminal ever had, trimmed or not — so a row number names the same line
/// before and after output scrolls the oldest lines away.
public struct TerminalScreenSnapshot: Sendable, Equatable {
    /// Every line still held, oldest first.
    public let lines: [String]
    /// The row number of `lines[0]`: how many lines have been trimmed off the top.
    public let firstRow: Int
    /// The row the cursor stands on.
    public let cursorRow: Int
    /// A full-screen program (vim, less) has the alternate screen up. Its rows
    /// are a canvas, not a record of output, and they vanish when it exits.
    public let isAlternateScreen: Bool

    public init(lines: [String], firstRow: Int, cursorRow: Int, isAlternateScreen: Bool) {
        self.lines = lines
        self.firstRow = firstRow
        self.cursorRow = cursorRow
        self.isAlternateScreen = isAlternateScreen
    }
}

/// Turns successive snapshots of a terminal into the text it has printed since
/// the last one — what a chat transcript shows as the terminal's reply.
///
/// It reads the *rendered* screen rather than the byte stream, which is what
/// makes this tractable: the terminal has already applied every cursor move,
/// carriage return and colour code, so a row is the text a person would read
/// there. Everything from the last row read up to the cursor's row is new.
///
/// The cursor's own row is usually unfinished — a prompt waiting for input — so
/// it is shown, and remembered, and only what is added to it later is shown
/// again. That keeps a prompt from appearing at the end of one reply and again
/// at the start of the next.
public struct TerminalOutputTracker: Sendable {

    /// The first row not yet read in full — the cursor's row as of the last read.
    private var nextRow: Int?
    /// What of `nextRow` has already been shown.
    private var shownPrefix = ""
    /// The last text sent to the terminal, until its echo has been seen.
    private var pendingEcho: String?

    public init() {}

    /// Reads from `snapshot`'s cursor row onward, so history from before the
    /// chat was connected is not replayed as if it were a reply.
    public init(startingAt snapshot: TerminalScreenSnapshot) {
        nextRow = snapshot.cursorRow
        let index = snapshot.cursorRow - snapshot.firstRow
        if snapshot.lines.indices.contains(index) { shownPrefix = snapshot.lines[index] }
    }

    /// Records a line just sent, so the shell's echo of it — the command
    /// reappearing on the prompt row — is not shown back as output.
    public mutating func noteSent(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingEcho = trimmed.isEmpty ? nil : trimmed
    }

    /// The text printed since the last call, or `nil` for nothing new.
    public mutating func newOutput(in snapshot: TerminalScreenSnapshot) -> String? {
        guard !snapshot.isAlternateScreen, !snapshot.lines.isEmpty else { return nil }

        let lastRow = snapshot.firstRow + snapshot.lines.count - 1
        let cursorRow = min(max(snapshot.cursorRow, snapshot.firstRow), lastRow)
        // A row already trimmed away, or a cursor sent back above where reading
        // stopped (a clear, a reset), leaves nothing to resume from: start again
        // at what is on hand.
        var from = nextRow ?? cursorRow
        if from < snapshot.firstRow || from > cursorRow {
            from = cursorRow
            shownPrefix = ""
        }

        var rows = (from...cursorRow).map { snapshot.lines[$0 - snapshot.firstRow] }
        if !shownPrefix.isEmpty, rows[0].hasPrefix(shownPrefix) {
            rows[0] = String(rows[0].dropFirst(shownPrefix.count))
        }

        nextRow = cursorRow
        shownPrefix = snapshot.lines[cursorRow - snapshot.firstRow]

        if let echo = pendingEcho, let first = rows.first,
           !first.trimmingCharacters(in: .whitespaces).isEmpty {
            // Only the first non-empty row can be the echo: the command lands
            // on the prompt, and everything after it is the command's output.
            if first.trimmingCharacters(in: .whitespaces).lowercased().hasSuffix(echo.lowercased()) {
                rows.removeFirst()
            }
            pendingEcho = nil
        }

        let text = Self.trimmingBlankEdges(rows)
        return text.isEmpty ? nil : text
    }

    /// Joins rows, dropping blank rows at either end and trailing spaces on
    /// each — a terminal row is padded out to the screen's width.
    private static func trimmingBlankEdges(_ rows: [String]) -> String {
        let trimmed = rows.map { line -> String in
            var line = Substring(line)
            while line.last?.isWhitespace == true { line = line.dropLast() }
            return String(line)
        }
        guard let first = trimmed.firstIndex(where: { !$0.isEmpty }),
              let last = trimmed.lastIndex(where: { !$0.isEmpty }) else { return "" }
        return trimmed[first...last].joined(separator: "\n")
    }
}
