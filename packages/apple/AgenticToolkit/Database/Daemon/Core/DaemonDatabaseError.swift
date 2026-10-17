#if canImport(AgenticToolkitCore)
import Foundation

// MARK: - Errors

public enum DaemonDatabaseError: Error, LocalizedError {
    case openFailed(String)
    case prepareFailed(message: String, code: Int32)
    case stepFailed(message: String, code: Int32)

    public var errorDescription: String? {
        switch self {
        case .openFailed(let message):        return "DB open failed: \(message)"
        case .prepareFailed(let message, _):  return "DB prepare failed: \(message)"
        case .stepFailed(let message, _):     return "DB step failed: \(message)"
        }
    }

    /// The raw SQLite result code that produced this error, if any. `nil` for
    /// `.openFailed` (which predates code capture and is never on the ingest
    /// retry path).
    public var sqliteCode: Int32? {
        switch self {
        case .prepareFailed(_, let code), .stepFailed(_, let code): return code
        case .openFailed: return nil
        }
    }

    /// Whether this is a transient error worth retrying rather than quarantining.
    /// Matches SQLITE_BUSY (5), SQLITE_LOCKED (6), SQLITE_IOERR (10) including
    /// their extended forms (low byte preserved, e.g. SQLITE_IOERR_READ = 266).
    public var isTransient: Bool {
        guard let raw = sqliteCode else { return false }
        switch raw & 0xFF {
        case 5, 6, 10: return true
        default: return false
        }
    }
}
#endif
