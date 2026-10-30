import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("Partner process configuration") struct PartnerProcessConfigurationTests {
    @Test func argumentsForFirstStartAndResume() {
        var config = PartnerProcessConfiguration(
            executable: "/x/claude", sessionID: UUID(), resume: false, model: "", permissionMode: "dontAsk",
            allowedTools: ["mcp__adkitchen"], mcpConfigPath: "/m.json", systemPromptPath: "/p.md",
            workingDirectory: "/w")
        #expect(config.arguments.contains("--session-id") && !config.arguments.contains("--resume"))
        #expect(!config.arguments.contains("--model"))
        config.resume = true; config.model = "opus"
        #expect(config.arguments.contains("--resume") && config.arguments.contains("--model"))
        #expect(config.arguments.contains("--strict-mcp-config") && config.arguments.contains("--replay-user-messages"))
    }
    @Test func mcpConfigWritesHeadersAndMode0600() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try PartnerMCPConfig.write(port: 51477, token: "tok", callerID: "c1", to: url)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        #expect((attrs[.posixPermissions] as? Int) == 0o600)
        let text = String(bytes: try Data(contentsOf: url), encoding: .utf8) ?? ""
        #expect(text.contains("\"X-ADKitchen-Pane\":\"c1\"") || text.contains("\"X-ADKitchen-Pane\" : \"c1\""))
        #expect(text.contains("http://127.0.0.1:51477/mcp"))
    }
    @Test func pathsDeriveFromHomeAndToken() {
        let paths = PartnerPaths(home: URL(fileURLWithPath: "/h"), token: "tok")
        #expect(paths.mcpConfig.path == "/h/.tok/partner/mcp.json")
        #expect(paths.skillFile(jobID: "x").path == "/h/.claude/skills/adkitchen-partner-x/SKILL.md")
    }
}
