import XCTest
@testable import AgenticToolkitMacOS

final class TerminalShellEnvironmentTests: XCTestCase {

    func testExtraKeysAreAppended() {
        let env = TerminalSession.shellEnvironment(base: ["TERM=xterm-256color"], extra: ["ADKITCHEN_PANE_ID": "abc"])
        XCTAssertEqual(env, ["TERM=xterm-256color", "ADKITCHEN_PANE_ID=abc"])
    }

    func testExistingKeyIsReplacedInPlace() {
        let env = TerminalSession.shellEnvironment(base: ["A=1", "TERM=dumb", "B=2"], extra: ["TERM": "xterm-256color"])
        XCTAssertEqual(env, ["A=1", "TERM=xterm-256color", "B=2"])
    }

    func testExtraKeysAreAppendedInSortedOrder() {
        let env = TerminalSession.shellEnvironment(base: [], extra: ["Z": "1", "A": "2"])
        XCTAssertEqual(env, ["A=2", "Z=1"])
    }

    func testAPrefixIsNotAMatch() {
        // "ADKITCHEN_PANE" must not be mistaken for "ADKITCHEN_PANE_ID".
        let env = TerminalSession.shellEnvironment(base: ["ADKITCHEN_PANE_ID=old"], extra: ["ADKITCHEN_PANE": "x"])
        XCTAssertEqual(env, ["ADKITCHEN_PANE_ID=old", "ADKITCHEN_PANE=x"])
    }

    @MainActor
    func testManagerHandsItsEnvironmentToEverySession() {
        let manager = TerminalSessionManager(workingDirectory: nil, environment: ["ADKITCHEN_PROJECT": "p"])
        let session = manager.addSession()
        XCTAssertEqual(session.environment, ["ADKITCHEN_PROJECT": "p"])
    }
}
