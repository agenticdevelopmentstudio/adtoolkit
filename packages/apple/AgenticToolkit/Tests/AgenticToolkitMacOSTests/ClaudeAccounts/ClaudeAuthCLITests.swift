@testable import AgenticToolkitMacOS
import Foundation
import XCTest

/// `ClaudeAuthCLI` spawns a script-installed `claude` (`#!/usr/bin/env node`)
/// from an app with a bare PATH; the child must find the `node` beside it.
final class ClaudeAuthCLITests: XCTestCase {
    func testChildPathLeadsWithTheExecutablesOwnDirectory() throws {
        let env = ClaudeAuthCLI.childEnvironment(executable: "/Users/jane/.nvm/versions/node/v22.3.0/bin/claude")
        let path = try XCTUnwrap(env["PATH"])
        XCTAssertTrue(path.hasPrefix("/Users/jane/.nvm/versions/node/v22.3.0/bin:"))
    }

    func testChildEnvironmentStillStripsAccountPins() {
        let env = ClaudeAuthCLI.childEnvironment(executable: "/usr/local/bin/claude")
        XCTAssertEqual(env["AGENTIC_TOOLKIT_HEADLESS"], "1")
        XCTAssertNil(env["CLAUDE_CODE_OAUTH_TOKEN"])
        XCTAssertNil(env["ANTHROPIC_API_KEY"])
    }
}
