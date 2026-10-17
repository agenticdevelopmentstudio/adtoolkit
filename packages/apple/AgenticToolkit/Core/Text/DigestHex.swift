import CryptoKit
import Foundation

extension Digest {
    /// Lowercase hex rendering of the digest's bytes — the one place the daemon
    /// turns hash bytes into the hex strings it stores (`transcript_lines.line_hash`,
    /// `ConfigChange.file_sha256`).
    public var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
