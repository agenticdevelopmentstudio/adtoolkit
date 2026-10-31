import Foundation
import AgenticToolkitCore

extension PartnerToolSource {

    private struct SessionSummary: Encodable {
        var id: String
        var title: String
        var directory: String
        var state: String
        var lastActivity: Date
    }

    static var sessionDefinitions: [ToolDefinition] {
        let session = ToolJSONSchema.string("The session id returned by partner_session_open.")
        let settle = ToolJSONSchema.number("Seconds output must be quiet before the reply is complete.")
        let timeout = ToolJSONSchema.number("Most seconds to wait.")
        return [
            ToolDefinition(
                name: "partner_session_open",
                description: "Opens a terminal tab in a directory, optionally running a first command. Returns its id.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "directory": ToolJSONSchema.string("Absolute working directory."),
                    "title": ToolJSONSchema.string("Tab title; defaults to the directory name."),
                    "command": ToolJSONSchema.string("A command to type once the shell is running.")
                ], required: ["directory"])),
            ToolDefinition(
                name: "partner_session_list",
                description: "Lists the sessions you opened: id, title, directory, state, last activity.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [:])),
            ToolDefinition(
                name: "partner_session_screen",
                description: "Reads the last N lines of a session's screen.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "session": session, "lines": ToolJSONSchema.integer("How many lines; default 40.")
                ], required: ["session"])),
            ToolDefinition(
                name: "partner_session_run",
                description: "Types a command into a session and returns its output once it settles.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "session": session, "command": ToolJSONSchema.string("The command to type."),
                    "settle": settle, "timeout": timeout
                ], required: ["session", "command"])),
            ToolDefinition(
                name: "partner_session_wait",
                description: "Waits for a session's output to settle, for a bounded time.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "session": session, "settle": settle, "timeout": timeout
                ], required: ["session"])),
            ToolDefinition(
                name: "partner_session_interrupt",
                description: "Sends Control-C to a session and returns what printed.",
                parametersJSONSchema: ToolJSONSchema.object(properties: ["session": session],
                                                            required: ["session"])),
            ToolDefinition(
                name: "partner_session_close",
                description: "Closes a session's tab and ends its shell.",
                parametersJSONSchema: ToolJSONSchema.object(properties: ["session": session],
                                                            required: ["session"]))
        ]
    }

    func sessionTool(_ name: String, _ data: Data) async -> (content: String, isError: Bool) {
        let args = Self.arguments(data)
        if name == "partner_session_open" {
            guard let directory = args["directory"] as? String, !directory.isEmpty else {
                return Self.failure("directory is required")
            }
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory), isDirectory.boolValue
            else { return Self.failure("no such directory: \(directory)") }
            let title = args["title"] as? String
            let command = args["command"] as? String
            let id = await MainActor.run { sessions.open(directory: directory, title: title, firstCommand: command).id }
            return Self.encode(["session": id.uuidString])
        }
        if name == "partner_session_list" {
            let list = await MainActor.run {
                sessions.sessions.map {
                    SessionSummary(id: $0.id.uuidString, title: $0.title, directory: $0.directory,
                                   state: $0.state.rawValue, lastActivity: $0.lastActivity)
                }
            }
            return Self.encode(list)
        }
        guard let idText = args["session"] as? String, let id = UUID(uuidString: idText) else {
            return Self.failure("session is required")
        }
        guard let session = await MainActor.run(body: { sessions.session(id: id) }) else {
            return Self.failure("no open session \(idText)")
        }
        let settle = Self.seconds(args["settle"], default: TerminalChatControl.Defaults.settle,
                                  maximum: TerminalChatControl.Defaults.maximumSettle)
        let timeout = Self.seconds(args["timeout"], default: TerminalChatControl.Defaults.timeout,
                                   maximum: TerminalChatControl.Defaults.maximumTimeout)
        switch name {
        case "partner_session_screen":
            let lines = (args["lines"] as? Int) ?? TerminalChatControl.Defaults.lines
            let screen = await MainActor.run { session.chat.screen(lines: max(1, lines)) }
            return screen.map { ($0, false) } ?? Self.failure("session has no terminal")
        case "partner_session_run":
            guard let command = args["command"] as? String else { return Self.failure("command is required") }
            await Self.waitForShell(session)
            let output = await session.chat.run(command, settle: .seconds(settle), timeout: .seconds(timeout))
            return (output, false)
        case "partner_session_wait":
            return (await session.chat.waitForOutput(settle: .seconds(settle), timeout: .seconds(timeout)), false)
        case "partner_session_interrupt":
            return (await session.chat.interruptAndWait(), false)
        case "partner_session_close":
            await MainActor.run { sessions.close(id: id) }
            return ("closed", false)
        default:
            return ("unknown tool \(name)", true)
        }
    }

    private static func seconds(_ value: Any?, default fallback: Double, maximum: Double) -> Double {
        guard let number = (value as? NSNumber)?.doubleValue else { return fallback }
        return min(max(number, 0), maximum)
    }

    /// A shell opened a moment ago may not be running yet; typing before it is would be lost.
    @MainActor
    private static func waitForShell(_ session: PartnerSession) async {
        for _ in 0..<50 where !session.terminal.isRunning {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
