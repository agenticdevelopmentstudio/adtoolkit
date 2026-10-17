import Foundation

/// Where a daemon publishes what it has ingested, so the code that ingests does
/// not know whether subscribers are reached over SSE, XPC, both or neither.
///
/// The encoding is not the sink's concern: ingestion encodes once (see
/// ``SessionEventEncoding``) and hands every sink the same bytes, so two daemons
/// publish identical payloads whatever their transports.
public protocol SessionEventSink: Sendable {
    /// One ingested hook event, already encoded as the wire JSON the daemon publishes
    /// (snake_case, ISO-8601 dates, sorted keys). `sessionId` lets a transport filter
    /// subscribers to one session.
    func broadcast(eventType: String, payload: Data, sessionId: String?)
    /// A session's liveness changed outside any hook event (liveness task, reopen probe).
    /// The payload a transport publishes is `{"session_id": …, "status": …}`, encoded
    /// by ``SessionEventEncoding/encodeSessionStatus(sessionId:status:)``.
    func broadcastSessionStatus(sessionId: String, status: SessionStatus)
}

/// The one encoding of what a ``SessionEventSink`` publishes.
public enum SessionEventEncoding {
    /// JSON for a broadcast payload (snake_case + ISO-8601 + sorted keys), encoded
    /// once and fed to every transport.
    public static func encode<T: Encodable>(_ value: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(value)
    }

    /// The `{session_id, status}` payload of a session status change.
    public static func encodeSessionStatus(sessionId: String, status: SessionStatus) -> Data? {
        struct StatusPayload: Encodable, Sendable {
            let sessionId: String
            let status: String
            enum CodingKeys: String, CodingKey {
                case sessionId = "session_id"
                case status
            }
        }
        return encode(StatusPayload(sessionId: sessionId, status: status.rawValue))
    }
}
