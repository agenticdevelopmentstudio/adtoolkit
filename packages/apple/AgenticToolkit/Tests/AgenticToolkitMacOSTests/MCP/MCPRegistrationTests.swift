import XCTest
@testable import AgenticToolkitMacOS

final class MCPRegistrationTests: XCTestCase {

    private func config(_ json: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("claude-\(UUID().uuidString).json")
        try json.write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testClaudeCommandNamesTheServerTheURLTheTokenAndThePaneHeader() {
        let command = MCPRegistration.claudeCommand(port: 51477, token: "abc")
        XCTAssertEqual(command,
            "claude mcp add --transport http --scope user adkitchen "
            + "'${ADKITCHEN_MCP_URL:-http://127.0.0.1:51477/mcp}' "
            + "--header 'Authorization: Bearer ${ADKITCHEN_MCP_TOKEN:-abc}' "
            + "--header 'X-ADKitchen-Pane: ${ADKITCHEN_PANE_ID:-}'")
    }

    func testRegisteredWhenTheServerPointsAtThisPort() throws {
        let url = try config(#"{"mcpServers":{"adkitchen":{"type":"http","url":"http://127.0.0.1:51477/mcp"}}}"#)
        XCTAssertTrue(MCPRegistration.isRegistered(claudeConfig: url, port: 51477))
    }

    func testRegisteredWhenTheURLIsTheEnvironmentForm() throws {
        let url = try config(
            #"{"mcpServers":{"adkitchen":{"type":"http","#
            + #""url":"${ADKITCHEN_MCP_URL:-http://127.0.0.1:51477/mcp}"}}}"#)
        XCTAssertTrue(MCPRegistration.isRegistered(claudeConfig: url, port: 51477))
    }

    func testNotRegisteredWhenTheServerIsMissing() throws {
        let url = try config(#"{"mcpServers":{"other":{"type":"http","url":"http://127.0.0.1:51477/mcp"}}}"#)
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: url, port: 51477))
    }

    func testNotRegisteredWhenThePortDiffers() throws {
        let url = try config(#"{"mcpServers":{"adkitchen":{"type":"http","url":"http://127.0.0.1:51000/mcp"}}}"#)
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: url, port: 51477))
    }

    func testNotRegisteredWhenTheFileIsMissingOrNotJSON() throws {
        let missing = URL(fileURLWithPath: "/nonexistent/.claude.json")
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: missing, port: 51477))
        let url = try config("not json")
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: url, port: 51477))
    }
}
