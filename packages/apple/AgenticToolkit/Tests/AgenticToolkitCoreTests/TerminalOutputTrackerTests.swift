import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("TerminalOutputTracker")
struct TerminalOutputTrackerTests {

    private func snapshot(
        _ lines: [String], cursor: Int, first: Int = 0, alternate: Bool = false
    ) -> TerminalScreenSnapshot {
        TerminalScreenSnapshot(lines: lines, firstRow: first, cursorRow: cursor, isAlternateScreen: alternate)
    }

    @Test("history from before the start is not reported")
    func startsAtTheCursor() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["old", "%"], cursor: 1))
        #expect(tracker.newOutput(in: snapshot(["old", "%"], cursor: 1)) == nil)
    }

    @Test("a command's echo is left out and its output and next prompt are reported")
    func dropsTheEcho() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["%"], cursor: 0))
        tracker.noteSent("echo hi")
        let output = tracker.newOutput(in: snapshot(["% echo hi", "hi", "%"], cursor: 2))
        #expect(output == "hi\n%")
    }

    @Test("a prompt already shown is not shown again")
    func stripsTheShownPrompt() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["%"], cursor: 0))
        _ = tracker.newOutput(in: snapshot(["%", "a", "%"], cursor: 2))
        tracker.noteSent("ls")
        let output = tracker.newOutput(in: snapshot(["%", "a", "% ls", "file", "%"], cursor: 4))
        #expect(output == "file\n%")
    }

    @Test("rows stay addressed correctly after older lines are trimmed")
    func survivesTrimming() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["x", "%"], cursor: 1))
        // Two lines scrolled off the top: row 1 is now lines[0].
        let output = tracker.newOutput(in: snapshot(["%", "out", "%"], cursor: 3, first: 1))
        #expect(output == "out\n%")
    }

    @Test("nothing is reported from the alternate screen")
    func ignoresAlternateScreen() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["%"], cursor: 0))
        #expect(tracker.newOutput(in: snapshot(["vim stuff"], cursor: 0, alternate: true)) == nil)
    }

    @Test("a cursor moved above where reading stopped restarts at the cursor")
    func recoversFromAClear() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["a", "b", "c", "%"], cursor: 3))
        #expect(tracker.newOutput(in: snapshot(["%", "", "", ""], cursor: 0)) == "%")
    }
}
