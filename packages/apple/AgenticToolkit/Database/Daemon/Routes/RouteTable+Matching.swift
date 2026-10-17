#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

extension RouteTable {

    /// A handler that claims `method` plus every path whose components satisfy
    /// `matches`, and hands the components to `respond` so it need not split the
    /// path again.
    static func route(
        _ method: String,
        where matches: @escaping @Sendable ([String]) -> Bool,
        _ respond: @escaping @Sendable (RouteRequest, [String]) async -> RouteResponse
    ) -> Handler {
        { request in
            guard request.method == method else { return nil }
            let components = request.pathComponents
            guard matches(components) else { return nil }
            return await respond(request, components)
        }
    }
}

extension RouteResponse {

    /// A 500 carrying the error's description: how every handler reports a store
    /// that threw.
    static func failure(_ error: Error) -> RouteResponse {
        .error(error.localizedDescription, status: 500)
    }
}
#endif
