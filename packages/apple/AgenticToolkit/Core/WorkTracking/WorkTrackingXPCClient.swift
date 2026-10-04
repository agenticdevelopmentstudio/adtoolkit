import Foundation

/// Everything an app can ask of work tracking. Reads and writes answer nil
/// when the daemon was unreachable, refused, or its reply couldn't be read.
public protocol WorkTrackingService: Sendable {
    func setPreferences(_ preferences: WorkTrackingPreferences) async -> WorkTrackingStatus?
    func status() async -> WorkTrackingStatus?
    func recheckPermissions() async -> WorkTrackingStatus?
    func spans(since: String?, limit: Int) async -> [ActivitySpanDTO]?
}

/// The calls ``WorkTrackingXPCClient`` makes, in the shape DaemonKit's
/// `XPCClient<any WorkTrackingXPCProtocol>` already has.
public protocol WorkTrackingXPCTransport: Sendable {
    typealias Proxy = any WorkTrackingXPCProtocol

    func callData(
        timeout: TimeInterval??, retries: Int,
        _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable (Data) -> Void) -> Void
    ) async throws -> Data

    func callDecodingArray<T: Decodable>(
        _ type: T.Type, timeout: TimeInterval??, retries: Int,
        _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable ([Data]) -> Void) -> Void
    ) async throws -> [T]
}

/// ``WorkTrackingService`` over XPC to a daemon that exports
/// ``WorkTrackingXPCProtocol``.
public final class WorkTrackingXPCClient<Transport: WorkTrackingXPCTransport>: WorkTrackingService {

    /// The one JSON reading of a work-tracking reply: snake case, ISO-8601.
    public static func makeReplyDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public let transport: Transport

    public init(transport: Transport) {
        self.transport = transport
    }

    public func setPreferences(_ preferences: WorkTrackingPreferences) async -> WorkTrackingStatus? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let body = try? encoder.encode(preferences) else { return nil }
        return await status { try await self.transport.callData(timeout: 5, retries: 0) {
            $0.workTrackingSetPreferences(body, reply: $1)
        } }
    }

    public func status() async -> WorkTrackingStatus? {
        await status { try await self.transport.callData(timeout: nil, retries: 0) {
            $0.workTrackingStatus(reply: $1)
        } }
    }

    public func recheckPermissions() async -> WorkTrackingStatus? {
        await status { try await self.transport.callData(timeout: 5, retries: 0) {
            $0.workTrackingRecheckPermissions(reply: $1)
        } }
    }

    public func spans(since: String?, limit: Int) async -> [ActivitySpanDTO]? {
        try? await transport.callDecodingArray(ActivitySpanDTO.self, timeout: nil, retries: 0) {
            $0.workTrackingSpans(since: since, limit: limit, reply: $1)
        }
    }

    /// Empty data (the daemon's "failed") or an unreadable body is nil.
    private func status(_ call: () async throws -> Data) async -> WorkTrackingStatus? {
        guard let data = try? await call(), !data.isEmpty else { return nil }
        return try? Self.makeReplyDecoder().decode(WorkTrackingStatus.self, from: data)
    }
}
