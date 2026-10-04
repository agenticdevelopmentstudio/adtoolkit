import AppKit
import AgenticToolkitLaunch

/// Runs a command as root through `do shell script … with administrator
/// privileges`. macOS caches that authorization for ~5 minutes per process,
/// so every privileged job in one startup queue shares a single prompt.
public struct AppleScriptPrivilegedRunner: PrivilegedRunner {
    public enum Failure: Error, Equatable, LocalizedError {
        case cancelled
        case failed(code: Int, message: String)

        public var errorDescription: String? {
            switch self {
            case .cancelled: return "The password prompt was cancelled."
            case .failed(_, let message): return message
            }
        }
    }

    public init() {}

    /// Each argv word single-quoted for the shell, then the whole command
    /// escaped for an AppleScript string literal (backslash, then quote).
    ///
    /// Escaping MUST operate on Unicode scalars, never Characters. Swift
    /// compares Characters as grapheme clusters, so a `'` followed by a
    /// combining mark (U+0301) is one Character that never equals `'` and
    /// would go unescaped, while `sh` still sees the bare quote: a root-shell
    /// injection. Scalars have no such blind spot.
    static func script(for argv: [String]) -> String {
        let shell = argv.map { "'" + escape($0, ["'": #"'\''"#]) + "'" }
            .joined(separator: " ")
        let literal = escape(shell, ["\\": #"\\"#, "\"": #"\""#])
        return "do shell script \"\(literal)\" with administrator privileges"
    }

    /// Replaces each scalar found in `map`; every other scalar passes through.
    private static func escape(_ text: String, _ map: [Unicode.Scalar: String]) -> String {
        var out = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if let replacement = map[scalar] {
                out.append(contentsOf: replacement.unicodeScalars)
            } else {
                out.append(scalar)
            }
        }
        return String(out)
    }

    @MainActor
    public func run(_ argv: [String]) async throws {
        guard !argv.isEmpty else {
            throw Failure.failed(code: -1, message: "No command given.")
        }
        guard !argv.contains(where: { $0.unicodeScalars.contains("\u{0}") }) else {
            throw Failure.failed(code: -1, message: "A command argument contains a NUL character.")
        }
        guard let script = NSAppleScript(source: Self.script(for: argv)) else {
            throw Failure.failed(code: -1, message: "Could not prepare the administrator command.")
        }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        guard let error else { return }
        let code = (error[NSAppleScript.errorNumber] as? Int) ?? -1
        if code == -128 { throw Failure.cancelled }
        throw Failure.failed(code: code, message: (error[NSAppleScript.errorMessage] as? String) ?? "error \(code)")
    }
}
