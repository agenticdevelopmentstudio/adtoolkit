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

    /// How long Check Again waits. The daemon answers only after its live
    /// Accessibility check, and without the grant that check stalls on tccd
    /// for about ten seconds — a shorter wait drops the "denied" it is about to
    /// send and shows "Unknown" instead (review F24).
    public static var recheckTimeout: TimeInterval { 15 }

    public func recheckPermissions() async -> WorkTrackingStatus? {
        await status { try await self.transport.callData(timeout: Self.recheckTimeout, retries: 0) {
            $0.workTrackingRecheckPermissions(reply: $1)
        } }
    }

    /// nil when the daemon is unreachable or replied
    /// ``WorkTrackingWire/readFailedRow`` — a failed read is never "none".
    public func spans(since: String?, limit: Int) async -> [ActivitySpanDTO]? {
        guard let rows = try? await transport.callDecodingArray(
            WorkTrackingListRow<ActivitySpanDTO>.self, timeout: nil, retries: 0, {
                $0.workTrackingSpans(since: since, limit: limit, reply: $1)
            }) else { return nil }
        var spans: [ActivitySpanDTO] = []
        for row in rows {
            guard case .value(let span) = row else { return nil }
            spans.append(span)
        }
        return spans
    }

    /// Empty data (the daemon's "failed") or an unreadable body is nil.
    private func status(_ call: () async throws -> Data) async -> WorkTrackingStatus? {
        guard let data = try? await call(), !data.isEmpty else { return nil }
        return try? Self.makeReplyDecoder().decode(WorkTrackingStatus.self, from: data)
    }
}

/// One element of a work-tracking list reply: a row, or
/// `WorkTrackingWire.readFailedRow`.
enum WorkTrackingListRow<T: Decodable>: Decodable {
    case value(T)
    case readFailed

    /// The reply decoder reads snake case, so the sentinel's key arrives
    /// camel-cased.
    private enum Key: String, CodingKey { case workTrackingReadFailed }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: Key.self),
           (try? container.decode(Bool.self, forKey: .workTrackingReadFailed)) == true {
            self = .readFailed
        } else {
            self = .value(try T(from: decoder))
        }
    }
}
