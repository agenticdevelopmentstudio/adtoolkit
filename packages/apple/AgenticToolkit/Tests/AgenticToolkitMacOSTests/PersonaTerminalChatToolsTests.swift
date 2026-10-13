import XCTest
import AIPluginKit
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class PersonaTerminalChatToolsTests: XCTestCase {

    private final class RecordingSource: ChatToolSource, @unchecked Sendable {
        var callers: [String?] = []
        func toolDefinitions() async -> [ToolDefinition] {
            [ToolDefinition(name: "browser_list", description: "lists",
                            parametersJSONSchema: ToolJSONSchema.object(properties: [:]))]
        }
        func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
            callers.append(caller)
            return ("[]", false)
        }
    }

    func testThePersonaChatOffersBrowserToolsAndNamesItsPane() async {
        let source = RecordingSource()
        let paneID = UUID()
        let controller = PersonaTerminalChatViewController(
            stateStore: EphemeralPaneStateStore(),
            pluginManager: AIPluginManager(searchPaths: [], appName: "PersonaTerminalChatToolsTests"),
            browserTools: source,
            paneID: paneID)
        let session = controller.session
        let names = await session?.toolSource?.toolDefinitions().map(\.name) ?? []
        XCTAssertTrue(names.contains("browser_list"))
        _ = await session?.toolSource?.callTool(
            name: "browser_list", argumentsJSON: Data("{}".utf8), caller: session?.toolCaller)
        XCTAssertEqual(source.callers, [paneID.uuidString])
    }
}
