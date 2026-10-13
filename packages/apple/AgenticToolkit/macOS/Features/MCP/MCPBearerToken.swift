// macOS/Features/MCP/MCPBearerToken.swift
import Foundation
import Security

/// The shared secret between the app and the processes it hands the MCP URL
/// to. On disk, mode 0600, created on first load.
public enum MCPBearerToken {

    public enum LoadError: Error, LocalizedError {
        case unreadable(URL, Error)
        case unwritable(URL, Error)

        public var errorDescription: String? {
            switch self {
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
    /// created if missing. The file is created with mode 0600 from the first
    /// byte (never briefly wider), and an existing file wider than 0600 is
    /// tightened to 0600 on load; the directory's mode is left alone. An
    /// empty or whitespace-only file counts as no token and is regenerated.
    /// Anything at the path that is not a regular file, a symlink included,
    /// is refused with `LoadError.unreadable`.
    public static func load(from file: URL) throws -> String {
        let manager = FileManager.default
        var status = stat()
        if lstat(file.path, &status) == 0 {
            // A symlink, directory or device at the token path is refused
            // rather than followed: the token would be read from, or written
            // to, wherever the link points.
            guard status.st_mode & S_IFMT == S_IFREG else {
                throw LoadError.unreadable(file, POSIXError(.EFTYPE))
            }
            do {
                try tighten(file)
                let raw = try String(contentsOf: file, encoding: .utf8)
                let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { return text }
            } catch {
                throw LoadError.unreadable(file, error)
            }
        }
        let token = generate()
        do {
            try manager.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try write(Data(token.utf8), to: file)
        } catch {
            throw LoadError.unwritable(file, error)
        }
        return token
    }

    private static func tighten(_ file: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        if let mode = attributes[.posixPermissions] as? Int, mode & 0o077 != 0 {
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        }
    }

    /// Opens with 0600 in the `open(2)` call itself, so there is no window in
    /// which the file is wider, and with `O_NOFOLLOW`, so a symlink planted at
    /// the path after the check in `load` is refused rather than written
    /// through.
    private static func write(_ data: Data, to file: URL) throws {
        let descriptor = open(file.path, O_WRONLY | O_CREAT | O_TRUNC | O_NOFOLLOW, 0o600)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        fchmod(descriptor, 0o600)
        try handle.write(contentsOf: data)
        try handle.close()
    }
}
