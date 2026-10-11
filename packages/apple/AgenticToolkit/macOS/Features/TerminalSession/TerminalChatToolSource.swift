import Foundation
import AgenticToolkitCore

/// The tools a persona uses to work a terminal — through a Terminal Chat
/// rather than the terminal itself. Connected to a private terminal, the
/// persona only ever sees that terminal's privacy words, never the real ones.
///
/// The Terminal Chat is looked up on every call, not held, so connecting one
/// after the persona chat opened — or closing it — takes effect on the next
/// tool call.
public final class TerminalChatToolSource: ChatToolSource, @unchecked Sendable {

    public enum ToolName {
        public static let run = "run_terminal_command"
        public static let wait = "wait_for_terminal_output"
        public static let interrupt = "interrupt_terminal"
    }

    /// Answers the Terminal Chat to talk to, or nil when there is none —
    /// read on the main actor, where panes live.
    private let resolve: @MainActor @Sendable () -> TerminalChatSession?

    public init(resolve: @escaping @MainActor @Sendable () -> TerminalChatSession?) {
        self.resolve = resolve
    }

    public func toolDefinitions() async -> [ToolDefinition] {
        [
            ToolDefinition(
                name: ToolName.run,
                description: """
                Type a command into the user's terminal and press Return, exactly as if the user \
                typed it, then return what the terminal printed until it went quiet. The output \
                includes the shell prompt that follows it. Some names in the output are \
                pseudonyms; use them as given — they are translated on the way in.
                """,
                parametersJSONSchema: Self.schema(properties: [
                    "command": ["type": "string", "description": "The command line to run."]
                ], required: ["command"])
            ),
            ToolDefinition(
                name: ToolName.wait,
                description: """
                Wait for more output from a command that was still running when \
                run_terminal_command returned, and return it.
                """,
                parametersJSONSchema: Self.schema(properties: [:], required: [])
            ),
            ToolDefinition(
                name: ToolName.interrupt,
                description: "Send Control-C to the terminal to stop the running command, and return what it printed.",
                parametersJSONSchema: Self.schema(properties: [:], required: [])
            )
        ]
    }

    public func callTool(name: String, argumentsJSON: Data) async -> (content: String, isError: Bool) {
        guard let terminalChat = await resolve() else {
            return ("No Terminal Chat is connected. Ask the user to add a Terminal Chat pane to this tab "
                    + "and turn on Connect to Terminal Chat in this pane's Settings.", true)
        }
        switch name {
        case ToolName.run:
            let arguments = (try? JSONSerialization.jsonObject(with: argumentsJSON)) as? [String: Any]
            guard let command = arguments?["command"] as? String, !command.isEmpty else {
                return ("run_terminal_command needs a non-empty \"command\".", true)
            }
            return (await terminalChat.run(command), false)
        case ToolName.wait:
            return (await terminalChat.waitForOutput(), false)
        case ToolName.interrupt:
            return (await terminalChat.interruptAndWait(), false)
        default:
            return ("Unknown tool: \(name)", true)
        }
    }

    private static func schema(properties: [String: [String: String]], required: [String]) -> Data {
        let object: [String: Any] = ["type": "object", "properties": properties, "required": required]
        return (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
    }
}
