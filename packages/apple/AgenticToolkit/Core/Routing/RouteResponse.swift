import Foundation

/// A response as shared routes produce it: no transport, no framework. A daemon's
/// HTTP layer converts it into its own response type.
public struct RouteResponse: Sendable, Equatable {
    public let status: Int
    public let body: Data
    public let contentType: String
    public let headers: [String: String]

    public init(
        status: Int,
        body: Data,
        contentType: String = "application/json",
        headers: [String: String] = [:]
    ) {
        self.status = status
        self.body = body
        self.contentType = contentType
        self.headers = headers
    }

    /// The wire encoder: snake_case keys, ISO-8601 dates, pretty-printed, sorted
    /// keys. A fresh instance per call — `JSONEncoder` is a reference type and
    /// handlers run concurrently.
    public static func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    /// Encodes with ``makeJSONEncoder()``; the body is `{}` if encoding throws.
    public static func json<T: Encodable>(_ value: T, status: Int = 200) -> RouteResponse {
        let body = (try? makeJSONEncoder().encode(value)) ?? Data("{}".utf8)
        return RouteResponse(status: status, body: body)
    }

    private struct ErrorBody: Encodable {
        let error: String
    }

    /// `{"error": message}`, encoded through ``json(_:status:)`` rather than
    /// string-spliced — a message containing a quote, backslash or newline would
    /// otherwise produce invalid JSON.
    public static func error(_ message: String, status: Int) -> RouteResponse {
        json(ErrorBody(error: message), status: status)
    }

    public static func notFound(_ message: String = "Not found") -> RouteResponse {
        error(message, status: 404)
    }

    /// 204 with an empty body.
    public static let noContent = RouteResponse(status: 204, body: Data())
}
