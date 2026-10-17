#if canImport(AgenticToolkitCore)
import Foundation

/// Computes the human-readable detail string for stream / event display.
/// Called by `ingestEvent` at ingestion time so the detail is precomputed
/// and stored in event_log.detail — clients never reparse raw JSON.
public func computeDetail(eventType: String, hookData: [String: Any]) -> String {
    switch eventType {
    case "SessionStart":
        let cwd   = hookData["cwd"]   as? String ?? ""
        let model = hookData["model"] as? String ?? ""
        let project = URL(fileURLWithPath: cwd).lastPathComponent
        return [project, model].filter { !$0.isEmpty }.joined(separator: "  ")

    case "PreToolUse", "PostToolUse":
        let tool  = hookData["tool_name"]  as? String        ?? ""
        let input = hookData["tool_input"] as? [String: Any] ?? [:]
        let extra = eventToolInputSummary(tool: tool, input: input)
        return extra.isEmpty ? tool : "\(tool)  \(extra)"

    case "PostToolUseFailure":
        let tool  = hookData["tool_name"] as? String ?? ""
        let error = hookData["error"]     as? String ?? ""
        let parts = [tool, truncate(error, 60)].filter { !$0.isEmpty }
        return parts.joined(separator: "  ")

    case "UserPromptSubmit":
        return truncate(hookData["prompt"] as? String ?? "", 80)

    case "Stop", "SessionEnd":
        let cwd = hookData["cwd"] as? String ?? ""
        return URL(fileURLWithPath: cwd).lastPathComponent

    case "SubagentStart":
        return hookData["agent_type"] as? String ?? ""

    case "SubagentStop":
        let agentType = hookData["agent_type"] as? String ?? ""
        let cwd       = hookData["cwd"]        as? String ?? ""
        let project   = URL(fileURLWithPath: cwd).lastPathComponent
        return [agentType, project].filter { !$0.isEmpty }.joined(separator: "  ")

    case "Notification":
        let msg = (hookData["message"] as? String)
            ?? (hookData["title"] as? String)
            ?? ""
        return truncate(msg, 80)

    case "PermissionRequest", "PermissionDenied":
        return hookData["tool_name"] as? String ?? ""

    case "StopFailure":
        return truncate(hookData["error"] as? String ?? "", 80)

    case "TaskCreated", "TaskCompleted":
        return truncate(hookData["task_subject"] as? String ?? "", 80)

    case "PreCompact", "PostCompact":
        return hookData["trigger"] as? String ?? ""

    case "Elicitation":
        let server = hookData["mcp_server_name"] as? String ?? ""
        let msg    = truncate(hookData["message"] as? String ?? "", 60)
        return [server, msg].filter { !$0.isEmpty }.joined(separator: "  ")

    case "ElicitationResult":
        let server = hookData["mcp_server_name"] as? String ?? ""
        let action = hookData["action"]          as? String ?? ""
        return [server, action].filter { !$0.isEmpty }.joined(separator: "  ")

    case "ConfigChange":
        return hookData["source"] as? String ?? ""

    case "InstructionsLoaded":
        let file = hookData["file_path"] as? String ?? ""
        return URL(fileURLWithPath: file).lastPathComponent

    case "WorktreeCreate":
        return hookData["name"] as? String ?? ""

    case "WorktreeRemove":
        let path = hookData["worktree_path"] as? String ?? ""
        return URL(fileURLWithPath: path).lastPathComponent

    case "CwdChanged":
        let newCwd = hookData["new_cwd"] as? String ?? ""
        return URL(fileURLWithPath: newCwd).lastPathComponent

    case "FileChanged":
        let file = hookData["file_path"] as? String ?? ""
        return URL(fileURLWithPath: file).lastPathComponent

    case "Setup":
        return hookData["trigger"] as? String ?? ""

    case "TeammateIdle":
        return hookData["teammate_name"] as? String ?? ""

    default:
        return ""
    }
}

// MARK: - Tool input summary

/// Extracts the most relevant single-line summary from a tool's input dict.
public func eventToolInputSummary(tool: String, input: [String: Any]) -> String {
    switch tool {
    case "Read":
        return (input["file_path"] as? String).map { filename($0) } ?? ""
    case "Edit", "Write", "NotebookEdit", "NotebookRead":
        return (input["file_path"] as? String).map { filename($0) } ?? ""
    case "Bash":
        return truncate(input["command"] as? String ?? "", 60)
    case "Glob":
        return input["pattern"] as? String ?? ""
    case "Grep":
        let pattern = input["pattern"] as? String ?? ""
        let path    = (input["path"] as? String).map { "  \(filename($0))" } ?? ""
        return "\(pattern)\(path)"
    case "WebFetch", "WebSearch":
        return truncate(input["url"] as? String ?? input["query"] as? String ?? "", 60)
    case "Agent":
        return truncate(input["description"] as? String ?? "", 60)
    default:
        return ""
    }
}

// MARK: - Private helpers

private func filename(_ path: String) -> String {
    URL(fileURLWithPath: path).lastPathComponent
}

private func truncate(_ text: String, _ max: Int) -> String {
    guard text.count > max else { return text }
    return String(text.prefix(max - 1)) + "…"
}
#endif
