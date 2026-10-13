// macOS/Features/MCP/MCPBearerToken.swift
import Foundation
import Security

/// The shared secret between the app and the processes it hands the MCP URL
/// to. On disk, mode 0600, created on first load.
public enum MCPBearerToken {

    public enum LoadError: Error, LocalizedError {
        case randomFailed(OSStatus)
        case unreadable(URL, Error)
        case unwritable(URL, Error)

        public var errorDescription: String? {
            switch self {
            case .randomFailed(let status): return "could not generate a token (SecRandomCopyBytes \(status))"
            case .unreadable(let url, let error): return "could not read \(url.path): \(error.localizedDescription)"
            case .unwritable(let url, let error): return "could not write \(url.path): \(error.localizedDescription)"
            }
        }
    }

    /// 32 random bytes as 64 hex characters.
    public static func generate() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed: \(status)")
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Reads the token in `file`, or creates one there. The directory is
    /// created if missing; the file is written with mode 0600.
    public static func load(from file: URL) throws -> String {
        let manager = FileManager.default
        if manager.fileExists(atPath: file.path) {
            do {
                let text = try String(contentsOf: file, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { return text }
            } catch {
                throw LoadError.unreadable(file, error)
            }
        }
        let token = generate()
        do {
            try manager.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(token.utf8).write(to: file, options: .atomic)
            try manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        } catch {
            throw LoadError.unwritable(file, error)
        }
        return token
    }
}
