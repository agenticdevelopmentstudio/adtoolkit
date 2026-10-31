import Foundation

/// Output captured from real claude, kept verbatim in `Fixtures/`. Shared with the macOS test bundle.
final class ClaudeStreamFixtures {
    /// stdout of `claude -p --resume <unknown id> --input-format stream-json --output-format stream-json
    /// --verbose`: one error `result` line, after which claude exits 1.
    static func unknownSessionResultLine() throws -> Data {
        try data("claude-resume-unknown-session", "json").trimmingTrailingNewline()
    }

    /// stderr of the same run.
    static func unknownSessionStderr() throws -> String {
        String(bytes: try data("claude-resume-unknown-session-stderr", "txt"), encoding: .utf8) ?? ""
    }

    private static func data(_ name: String, _ ext: String) throws -> Data {
        guard let url = Bundle(for: ClaudeStreamFixtures.self).url(forResource: name, withExtension: ext) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).\(ext)"])
        }
        return try Data(contentsOf: url)
    }
}

private extension Data {
    func trimmingTrailingNewline() -> Data {
        var data = self
        while data.last == 0x0A || data.last == 0x0D { data.removeLast() }
        return data
    }
}
