import Foundation

/// An ordered list of route handlers. Each handler either claims a request by
/// returning a response or declines it by returning nil.
public struct RouteTable: Sendable {
    public typealias Handler = @Sendable (RouteRequest) async -> RouteResponse?

    private let handlers: [Handler]

    public init(_ handlers: [Handler] = []) {
        self.handlers = handlers
    }

    /// The first handler that returns non-nil wins; nil when none claims the request.
    public func handle(_ request: RouteRequest) async -> RouteResponse? {
        for handler in handlers {
            if let response = await handler(request) { return response }
        }
        return nil
    }

    /// This table's handlers first, then `other`'s.
    public func merging(_ other: RouteTable) -> RouteTable {
        RouteTable(handlers + other.handlers)
    }

    /// A handler that claims exactly `method` + `components` and nothing else.
    public static func exact(
        _ method: String,
        _ components: [String],
        _ respond: @escaping @Sendable (RouteRequest) async -> RouteResponse
    ) -> Handler {
        { request in
            guard request.method == method, request.pathComponents == components else { return nil }
            return await respond(request)
        }
    }
}
