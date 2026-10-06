import AppKit
import AgenticToolkitLaunch

/// Runs a command as root through `do shell script … with administrator
/// privileges`.
///
/// macOS's ~5-minute authorization grace belongs to one *script instance*,
/// not to the process: a fresh `NSAppleScript` per command prompts every
/// time. So every command goes through one compiled script, shared for the
/// life of the process, whose handler receives the command as a parameter.
/// Every privileged job in a startup queue then shares a single prompt.
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

    /// The handler every command runs through. Its name is lowercase because
    /// AppleScript stores handler names lowercased, and the subroutine event
    /// must name it exactly.
    static let handlerName = "runasadministrator"
    static let handlerSource = """
        on \(handlerName)(command)
            do shell script command with administrator privileges
        end \(handlerName)
        """

    /// Compiled once, on first use, and reused: reuse is what carries the
    /// authorization grace from one command to the next.
    @MainActor private static var sharedScript: NSAppleScript?

    /// Each argv word single-quoted for the shell. The command reaches
    /// AppleScript as a parameter, never as source, so it needs no
    /// AppleScript-literal escaping.
    ///
    /// Escaping MUST operate on Unicode scalars, never Characters. Swift
    /// compares Characters as grapheme clusters, so a `'` followed by a
    /// combining mark (U+0301) is one Character that never equals `'` and
    /// would go unescaped, while `sh` still sees the bare quote: a root-shell
    /// injection. Scalars have no such blind spot.
    static func shellCommand(for argv: [String]) -> String {
        argv.map { "'" + escapeQuotes($0) + "'" }.joined(separator: " ")
    }

    private static func escapeQuotes(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if scalar == "'" {
                out.append(contentsOf: #"'\''"#.unicodeScalars)
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
        let script = try Self.compiledScript()
        var error: NSDictionary?
        script.executeAppleEvent(Self.handlerEvent(command: Self.shellCommand(for: argv)), error: &error)
        guard let error else { return }
        throw Self.failure(from: error)
    }

    @MainActor
    private static func compiledScript() throws -> NSAppleScript {
        if let sharedScript { return sharedScript }
        guard let script = NSAppleScript(source: handlerSource) else {
            throw Failure.failed(code: -1, message: "Could not prepare the administrator command.")
        }
        var error: NSDictionary?
        guard script.compileAndReturnError(&error) else {
            throw error.map(failure(from:))
                ?? Failure.failed(code: -1, message: "Could not prepare the administrator command.")
        }
        sharedScript = script
        return script
    }

    /// A subroutine event (`ascr`/`psbr`) calling `handlerName` with the
    /// command as its one positional parameter.
    static func handlerEvent(command: String) -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(
            eventClass: fourCharCode("ascr"),
            eventID: fourCharCode("psbr"),
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID))
        event.setParam(NSAppleEventDescriptor(string: handlerName), forKeyword: fourCharCode("snam"))
        let parameters = NSAppleEventDescriptor.list()
        parameters.insert(NSAppleEventDescriptor(string: command), at: 1)
        event.setParam(parameters, forKeyword: fourCharCode("----"))
        return event
    }

    private static func fourCharCode(_ code: String) -> FourCharCode {
        code.unicodeScalars.reduce(0) { ($0 << 8) | FourCharCode($1.value) }
    }

    private static func failure(from error: NSDictionary) -> Failure {
        let code = (error[NSAppleScript.errorNumber] as? Int) ?? -1
        if code == -128 { return .cancelled }
        return .failed(code: code, message: (error[NSAppleScript.errorMessage] as? String) ?? "error \(code)")
    }
}
