// macOS/Features/MCP/MCPHTTPEndpoint.swift
import Foundation
import FlyingFox
import FlyingSocks
import MCP
import OSLog

/// Serves a `HostMCPServer` over MCP Streamable HTTP on 127.0.0.1.
///
/// FlyingFox owns the socket; the SDK's `StatelessHTTPServerTransport` owns
/// the protocol (Origin/Host, Accept, Content-Type and protocol-version
/// checks included). This actor adds the two things the SDK leaves to the
/// host: the bearer token and the single `POST /mcp` route.
public actor MCPHTTPEndpoint {

    public static let path = "/mcp"
    public static let preferredPort: UInt16 = 51477

    private struct ClosedEarly: Error {}

    private let server: HostMCPServer
    private let token: String
    private let preferred: UInt16
    private let log: Logger
    private var http: HTTPServer?
    private var runTask: Task<Void, Error>?
    private var transport: StatelessHTTPServerTransport?
    public private(set) var port: UInt16?

    public init(server: HostMCPServer, token: String,
                preferredPort: UInt16 = MCPHTTPEndpoint.preferredPort, logger: Logger? = nil) {
        self.server = server
        self.token = token
        self.preferred = preferredPort
        self.log = logger ?? Logger(subsystem: "AgenticToolkit", category: "automation")
    }

    /// Binds the preferred port, or an ephemeral one when it is taken, and
    /// returns the port actually listening.
    public func start() async throws -> UInt16 {
        if port != nil { await stop() }
        let transport = StatelessHTTPServerTransport(logger: nil)
        try await server.serve(over: transport)
        self.transport = transport

        let bound: UInt16
        do {
            do {
                bound = try await listen(on: preferred, transport: transport)
            } catch where preferred != 0 {
                log.info("automation: port \(self.preferred, privacy: .public) is taken; binding an ephemeral port")
                bound = try await listen(on: 0, transport: transport)
            }
        } catch {
            await server.stop()
            self.transport = nil
            throw error
        }
        port = bound
        log.notice("automation: listening on port \(bound, privacy: .public)")
        return bound
    }

    public func stop() async {
        await http?.stop(timeout: 1)
        runTask?.cancel()
        runTask = nil
        http = nil
        transport = nil
        await server.stop()
        port = nil
    }

    // MARK: - Listening

    private func listen(on requested: UInt16, transport: StatelessHTTPServerTransport) async throws -> UInt16 {
        let http = HTTPServer(address: try sockaddr_in.inet(ip4: "127.0.0.1", port: requested))
        let token = self.token
        let log = self.log
        await http.appendRoute(HTTPRoute("POST \(Self.path)")) { request in
            guard Self.isAuthorized(request.headers[.authorization], token: token) else {
                log.info("automation: POST \(Self.path, privacy: .public) 401")
                var response = FlyingFox.HTTPResponse(statusCode: .unauthorized)
                response.headers[HTTPHeader("WWW-Authenticate")] = "Bearer"
                return response
            }
            let body = try await request.bodyData
            var headers: [String: String] = [:]
            for (name, value) in request.headers { headers[name.rawValue] = value }
            let answer = await transport.handleRequest(
                MCP.HTTPRequest(method: "POST", headers: headers, body: body, path: Self.path))
            log.info("automation: POST \(Self.path, privacy: .public) \(answer.statusCode, privacy: .public)")
            return await Self.flyingFoxResponse(from: answer)
        }
        // Anything else: the wrong path is 404, the right path with the
        // wrong method is 405.
        await http.appendRoute(HTTPRoute("*")) { request in
            if request.path == Self.path {
                var response = FlyingFox.HTTPResponse(statusCode: HTTPStatusCode(405, phrase: "Method Not Allowed"))
                response.headers[HTTPHeader("Allow")] = "POST"
                return response
            }
            return FlyingFox.HTTPResponse(statusCode: .notFound)
        }
        let task = Task { try await http.run() }
        // `run()` throws when the bind fails, and `waitUntilListening` would
        // only time out; race them so a taken port fails at once.
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await http.waitUntilListening(timeout: 5) }
                group.addTask {
                    try await task.value
                    throw ClosedEarly()
                }
                try await group.next()
                group.cancelAll()
            }
        } catch {
            task.cancel()
            throw error
        }
        guard let address = await http.listeningAddress else {
            task.cancel()
            throw CocoaError(.fileNoSuchFile)
        }
        let bound: UInt16
        switch address {
        case .ip4(_, let port), .ip6(_, let port): bound = port
        default:
            task.cancel()
            throw CocoaError(.fileNoSuchFile)
        }
        self.http = http
        self.runTask = task
        return bound
    }

    /// `Bearer <token>` compared without an early exit on the first
    /// differing byte.
    private static func isAuthorized(_ header: String?, token: String) -> Bool {
        guard let header else { return false }
        let expected = Array("Bearer \(token)".utf8)
        let actual = Array(header.utf8)
        var difference = expected.count ^ actual.count
        for index in 0..<min(expected.count, actual.count) {
            difference |= Int(expected[index] ^ actual[index])
        }
        return difference == 0
    }

    /// Maps the SDK's response onto FlyingFox's. A `.stream` is collected,
    /// which is fine for a stateless transport that never opens one for
    /// `tools/*`.
    private static func flyingFoxResponse(from answer: MCP.HTTPResponse) async -> FlyingFox.HTTPResponse {
        var body = Data()
        switch answer {
        case .stream(let stream, _):
            do { for try await chunk in stream { body.append(chunk) } } catch {}
        default:
            body = answer.bodyData ?? Data()
        }
        var headers = HTTPHeaders()
        for (name, value) in answer.headers { headers[HTTPHeader(name)] = value }
        return FlyingFox.HTTPResponse(statusCode: HTTPStatusCode(answer.statusCode, phrase: ""),
                                      headers: headers, body: body)
    }
}
