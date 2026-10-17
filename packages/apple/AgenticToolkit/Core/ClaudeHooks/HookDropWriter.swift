import Foundation

/// Where a hook helper writes its drop files, and how it writes them.
///
/// A drop file is the hook helper's fallback transport: when no daemon is
/// listening, the envelope lands in the configuration's drop directory and the
/// daemon scans it in later.
public enum HookDropWriter {

    /// The environment variable that overrides the drop directory for one
    /// configuration: its name, upper-cased, with every non-alphanumeric
    /// character as `_`, then `_DROP_DIR` (`stenographer` reads
    /// `STENOGRAPHER_DROP_DIR`). Tests use it to route output to a temporary
    /// directory without rewiring the installed hooks; production hooks never
    /// set it.
    public static func dropDirectoryVariable(configuration: ClaudeHookConfiguration) -> String {
        let name = configuration.name.uppercased().unicodeScalars.map {
            CharacterSet.alphanumerics.contains($0) && $0.isASCII ? Character($0) : "_"
        }
        return String(name) + "_DROP_DIR"
    }

    /// The directory drop files go to: the configuration's override variable
    /// when it is set and non-empty, else `configuration.dropDirectory`. The
    /// result may still carry a leading `~`; `writeDropFile` expands it.
    public static func dropDirectory(
        configuration: ClaudeHookConfiguration,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String {
        if let override = environment[dropDirectoryVariable(configuration: configuration)],
           !override.isEmpty {
            return override
        }
        return configuration.dropDirectory
    }

    /// Writes the envelope to `<dir>/<ms-ts>-<8hex>.json` atomically: JSON encode,
    /// write to `<final>.tmp`, then `rename(2)` to the final name.
    public static func writeDropFile(envelope: [String: Any], directory: String) throws {
        let expanded = (directory as NSString).expandingTildeInPath
        let dirURL = URL(fileURLWithPath: expanded, isDirectory: true)
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

        let data = try JSONSerialization.data(withJSONObject: envelope, options: [])
        let durationMs = Int(Date().timeIntervalSince1970 * 1000)
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).lowercased()
        let finalURL = dirURL.appendingPathComponent("\(durationMs)-\(suffix).json")
        let tmpURL = dirURL.appendingPathComponent("\(durationMs)-\(suffix).json.tmp")

        try data.write(to: tmpURL, options: .atomic)
        try FileManager.default.moveItem(at: tmpURL, to: finalURL)
    }
}
