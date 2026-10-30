import Foundation

/// How the partner's long-running `claude` process is launched.
public struct PartnerProcessConfiguration: Sendable, Equatable {
    public var executable: String
    public var sessionID: UUID
    public var resume: Bool
    public var model: String
    public var permissionMode: String
    public var allowedTools: [String]
    public var mcpConfigPath: String
    public var systemPromptPath: String
    public var workingDirectory: String

    public init(executable: String, sessionID: UUID, resume: Bool, model: String, permissionMode: String,
                allowedTools: [String], mcpConfigPath: String, systemPromptPath: String,
                workingDirectory: String) {
        self.executable = executable
        self.sessionID = sessionID
        self.resume = resume
        self.model = model
        self.permissionMode = permissionMode
        self.allowedTools = allowedTools
        self.mcpConfigPath = mcpConfigPath
        self.systemPromptPath = systemPromptPath
        self.workingDirectory = workingDirectory
    }

    /// `--verbose` is required by `-p` with stream-json output.
    public var arguments: [String] {
        var args = ["-p", "--verbose", "--input-format", "stream-json", "--output-format", "stream-json",
                    "--replay-user-messages", resume ? "--resume" : "--session-id",
                    sessionID.uuidString.lowercased(),
                    "--permission-mode", permissionMode, "--mcp-config", mcpConfigPath, "--strict-mcp-config",
                    "--append-system-prompt-file", systemPromptPath]
        if !model.isEmpty { args += ["--model", model] }
        if !allowedTools.isEmpty { args += ["--allowedTools"] + allowedTools }
        return args
    }
}
