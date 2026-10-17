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
/// checks included). This actor adds the things the SDK leaves to the host:
/// the bearer token, the single `POST /mcp` route, and a unique JSON-RPC id
/// per request (the stateless transport keys its bookkeeping by id alone, so
/// two callers who both send `"id": 1` would otherwise collide).
///
/// Because the id a request runs under is not the id its caller sent, the
/// endpoint also owns cancellation: a caller's `notifications/cancelled` names
/// the caller's id and is pointed at ours, and FlyingFox's request timeout,
/// which on its own cancels nothing but the HTTP handler, is turned into the
/// same cancellation, so the tool call stops when the client is told it did.
public actor MCPHTTPEndpoint {

    public static let path = "/mcp"
    public static let preferredPort: UInt16 = 51477

    /// A navigation or wait can legitimately run for a while; FlyingFox wraps
    /// the whole handler in this timeout (its default is 15 s).
    public static let requestTimeout: TimeInterval = 120

    public enum StartError: Error {
        /// `start()` was called while another `start()` was still binding, or
        /// while a `stop()` was still tearing down.
        case alreadyStarting
        /// `stop()` arrived while `start()` was binding; everything was torn down.
        case stoppedWhileStarting
    }

    private enum Phase { case idle, starting, running, stopping }

    private struct ClosedEarly: Error {}

    private let server: HostMCPServer
    private let token: String
    private let preferred: UInt16
    private let requestTimeout: TimeInterval
    private let log: Logger
    private let inFlight = InFlightRequests()
    private var phase = Phase.idle
    private var stopRequested = false
    private var http: HTTPServer?
    private var runTask: Task<Void, Never>?
    private var transport: StatelessHTTPServerTransport?
    public private(set) var port: UInt16?

    public init(server: HostMCPServer, token: String,
                preferredPort: UInt16 = MCPHTTPEndpoint.preferredPort,
                requestTimeout: TimeInterval = MCPHTTPEndpoint.requestTimeout, logger: Logger? = nil) {
        self.server = server
        self.token = token
        self.preferred = preferredPort
        self.requestTimeout = requestTimeout
        self.log = logger ?? Logger(subsystem: "AgenticToolkit", category: "automation")
    }

    /// Binds the preferred port, or an ephemeral one when it is taken, and
    /// returns the port actually listening. Already running: returns the
    /// port it is on. Called while another `start()` is binding: throws
    /// `StartError.alreadyStarting`.
    public func start() async throws -> UInt16 {
        switch phase {
        case .running:
            if let port { return port }
        case .starting, .stopping:
            throw StartError.alreadyStarting
        case .idle:
            break
        }
        phase = .starting
        stopRequested = false
        let bound: UInt16
        do {
            let transport = StatelessHTTPServerTransport(logger: nil)
            try await server.serve(over: transport)
            try checkNotStopped()
            self.transport = transport
            do {
                bound = try await listen(on: preferred, transport: transport)
            } catch where preferred != 0 && !stopRequested {
                log.info("automation: port \(self.preferred, privacy: .public) is taken; binding an ephemeral port")
                bound = try await listen(on: 0, transport: transport)
            }
            try checkNotStopped()
        } catch {
            await tearDown()
            phase = .idle
            stopRequested = false
            throw error
        }
        port = bound
        phase = .running
        log.notice("automation: listening on port \(bound, privacy: .public)")
        return bound
    }

    /// Stops listening. Called while `start()` is binding, it records the
    /// request and `start()` tears down what it built and throws.
    public func stop() async {
        switch phase {
        case .starting:
            stopRequested = true
            return
        case .stopping:
            return
        case .idle, .running:
            break
        }
        // The phase flips and tearDown() moves everything out before its first
        // await, so a `start()` arriving meanwhile can neither see the closing
        // port nor bind a second server.
        phase = .stopping
        await tearDown()
        phase = .idle
    }

    private func checkNotStopped() throws {
        if stopRequested { throw StartError.stoppedWhileStarting }
    }

    private func tearDown() async {
        let closingHTTP = http
        let closingTask = runTask
        http = nil
        runTask = nil
        transport = nil
        port = nil
        await closingHTTP?.stop(timeout: 1)
        closingTask?.cancel()
        await server.stop()
    }

    // MARK: - Listening

    private func listen(on requested: UInt16, transport: StatelessHTTPServerTransport) async throws -> UInt16 {
        let http = HTTPServer(address: try sockaddr_in.inet(ip4: "127.0.0.1", port: requested),
                              timeout: requestTimeout)
        let token = self.token
        let log = self.log
        let inFlight = self.inFlight
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
            let caller = request.headers[HTTPHeader(HostMCPServer.callerHeader)]

            if let cancellation = Self.cancellation(in: body) {
                // The caller names the id it sent; the SDK knows the request
                // by ours. An id not in flight (already answered, or another
                // caller's) passes through and the SDK ignores it, as the spec
                // asks.
                let key = Self.inFlightKey(caller: caller, originalIDJSON: cancellation.originalIDJSON)
                let unique = await inFlight.uniqueID(for: key)
                let answer = await transport.handleRequest(MCP.HTTPRequest(
                    method: "POST", headers: headers, body: unique.map(cancellation.naming) ?? body, path: Self.path))
                if let unique { await Self.release(unique, on: transport, reason: "cancelled by the caller") }
                log.info("automation: cancel \(Self.path, privacy: .public) \(answer.statusCode, privacy: .public)")
                return await Self.flyingFoxResponse(
                    from: answer, restoring: IDRewrite(body: body, uniqueID: nil, originalIDJSON: nil))
            }

            let rewrite = Self.rewriteID(in: body)
            let key = rewrite.originalIDJSON.map { Self.inFlightKey(caller: caller, originalIDJSON: $0) }
            if let key, let unique = rewrite.uniqueID { await inFlight.begin(key, uniqueID: unique) }
            // FlyingFox's timeout cancels this handler's task and nothing
            // else: the SDK's handler task would run the tool call to its
            // end, and the transport's waiter for it would never be released.
            // The cancellation is forwarded into the SDK instead, the same
            // way a caller's own would be.
            let answer = await withTaskCancellationHandler {
                await transport.handleRequest(
                    MCP.HTTPRequest(method: "POST", headers: headers, body: rewrite.body, path: Self.path))
            } onCancel: {
                guard let unique = rewrite.uniqueID else { return }
                Task { [headers] in
                    await Self.cancel(unique, on: transport, headers: headers, reason: "the HTTP request timed out")
                }
            }
            if let key, let unique = rewrite.uniqueID { await inFlight.end(key, uniqueID: unique) }
            log.info("automation: POST \(Self.path, privacy: .public) \(answer.statusCode, privacy: .public)")
            return await Self.flyingFoxResponse(from: answer, restoring: rewrite)
        }
        // Anything else: the wrong path is 404, the right path with the
        // wrong method is 405.
        await http.appendRoute(HTTPRoute("*")) { request in
            if request.path == Self.path {
                var response = FlyingFox.HTTPResponse(statusCode: .methodNotAllowed)
                response.headers[HTTPHeader("Allow")] = "POST"
                return response
            }
            return FlyingFox.HTTPResponse(statusCode: .notFound)
        }
        // `run()` throws when the bind fails, and `waitUntilListening` would
        // only time out. The run task reports its end through a stream, which
        // (unlike `Task.value`) the race below can cancel.
        let (ended, endedContinuation) = AsyncThrowingStream<Void, Error>.makeStream()
        let task = Task {
            do {
                try await http.run()
                endedContinuation.finish()
            } catch {
                endedContinuation.finish(throwing: error)
            }
        }
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await http.waitUntilListening(timeout: 5) }
                group.addTask {
                    for try await _ in ended {}
                    // Cancelled because the other child won: not a failure.
                    if Task.isCancelled { return }
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

    // MARK: - JSON-RPC id rewriting

    /// A request body with its `id` replaced by a unique string, plus what is
    /// needed to put the caller's own id back into the answer.
    struct IDRewrite: Sendable {
        let body: Data
        let uniqueID: String?
        /// The original id, JSON-encoded as the sole element of an array.
        let originalIDJSON: Data?
    }

    /// A body that is a single JSON object with an `id` gets a fresh id; any
    /// other body (array, no id, unparseable) passes through unchanged.
    static func rewriteID(in body: Data) -> IDRewrite {
        guard var object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              let original = object["id"], isRewritable(original),
              let originalJSON = try? JSONSerialization.data(withJSONObject: [original]) else {
            return IDRewrite(body: body, uniqueID: nil, originalIDJSON: nil)
        }
        let unique = UUID().uuidString
        object["id"] = unique
        guard let rewritten = try? JSONSerialization.data(withJSONObject: object) else {
            return IDRewrite(body: body, uniqueID: nil, originalIDJSON: nil)
        }
        return IDRewrite(body: rewritten, uniqueID: unique, originalIDJSON: originalJSON)
    }

    /// Only a string or an integer is a JSON-RPC id the SDK tracks; null (which
    /// the SDK reads as "no id", a notification), booleans and fractions pass
    /// through untouched.
    private static func isRewritable(_ id: Any) -> Bool {
        if id is String { return true }
        guard let number = id as? NSNumber, CFGetTypeID(number) == CFNumberGetTypeID() else { return false }
        return !CFNumberIsFloatType(number)
    }

    /// Puts the caller's id back into a response body that carries ours.
    static func restoreID(in body: Data, using rewrite: IDRewrite) -> Data {
        guard let unique = rewrite.uniqueID, let originalJSON = rewrite.originalIDJSON,
              var object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              object["id"] as? String == unique,
              let original = (try? JSONSerialization.jsonObject(with: originalJSON)) as? [Any],
              let first = original.first,
              object.updateValue(first, forKey: "id") != nil,
              let restored = try? JSONSerialization.data(withJSONObject: object) else {
            return body
        }
        return restored
    }

    // MARK: - Cancellation

    /// The requests in flight, keyed by caller and the id the caller sent, so
    /// a `notifications/cancelled` naming that id finds the id the SDK knows
    /// the request by. A caller that reuses an id while the first request is
    /// still in flight has already broken JSON-RPC; the later one wins.
    actor InFlightRequests {
        private var uniqueIDs: [String: String] = [:]

        func begin(_ key: String, uniqueID: String) { uniqueIDs[key] = uniqueID }

        /// Forgets the entry only if it is still this request's, so a later
        /// request under a reused key is not forgotten by the earlier one.
        func end(_ key: String, uniqueID: String) {
            if uniqueIDs[key] == uniqueID { uniqueIDs.removeValue(forKey: key) }
        }

        func uniqueID(for key: String) -> String? { uniqueIDs[key] }
    }

    static func inFlightKey(caller: String?, originalIDJSON: Data) -> String {
        (caller ?? "") + "\u{1F}" + (String(bytes: originalIDJSON, encoding: .utf8) ?? "")
    }

    /// A `notifications/cancelled` body whose `params.requestId` is an id the
    /// endpoint may have rewritten.
    struct Cancellation: Sendable {
        let body: Data
        /// The named id, JSON-encoded as the sole element of an array.
        let originalIDJSON: Data

        /// The same notification naming `uniqueID` instead.
        func naming(_ uniqueID: String) -> Data {
            guard var object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
                  var params = object["params"] as? [String: Any] else { return body }
            params["requestId"] = uniqueID
            object["params"] = params
            return (try? JSONSerialization.data(withJSONObject: object)) ?? body
        }
    }

    /// Recognises a cancellation notification: no (rewritable) id of its own,
    /// the cancellation method, and a string or integer `requestId`.
    static func cancellation(in body: Data) -> Cancellation? {
        guard let object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
              !(object["id"].map(isRewritable) ?? false),
              object["method"] as? String == CancelledNotification.name,
              let params = object["params"] as? [String: Any],
              let requestID = params["requestId"], isRewritable(requestID),
              let json = try? JSONSerialization.data(withJSONObject: [requestID]) else { return nil }
        return Cancellation(body: body, originalIDJSON: json)
    }

    /// Cancels the request the SDK knows as `uniqueID`: a cancellation
    /// notification into the transport, which the SDK answers by cancelling
    /// its handler task, then `release`.
    static func cancel(_ uniqueID: String, on transport: StatelessHTTPServerTransport,
                       headers: [String: String], reason: String) async {
        let notification: [String: Any] = [
            "jsonrpc": "2.0", "method": CancelledNotification.name,
            "params": ["requestId": uniqueID, "reason": reason]
        ]
        if let body = try? JSONSerialization.data(withJSONObject: notification) {
            _ = await transport.handleRequest(MCP.HTTPRequest(method: "POST", headers: headers, body: body, path: path))
        }
        await release(uniqueID, on: transport, reason: reason)
    }

    /// Answers the HTTP call waiting on `uniqueID` with an error. The SDK sends
    /// no response for a cancelled request, as the spec says, but over
    /// stateless HTTP a request with no response is a connection held open to
    /// FlyingFox's timeout and a transport waiter never released. Arriving
    /// after a real response, this finds no waiter and the transport drops it.
    static func release(_ uniqueID: String, on transport: StatelessHTTPServerTransport, reason: String) async {
        let response: [String: Any] = [
            "jsonrpc": "2.0", "id": uniqueID,
            // -32800 is the code the LSP gives a cancelled request; JSON-RPC
            // reserves none and MCP defines none.
            "error": ["code": -32800, "message": "request cancelled: \(reason)"]
        ]
        if let body = try? JSONSerialization.data(withJSONObject: response) {
            try? await transport.send(body)
        }
    }

    // MARK: - Response mapping

    private static func statusCode(_ code: Int) -> HTTPStatusCode {
        switch code {
        case 200: return .ok
        case 202: return .accepted
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 405: return .methodNotAllowed
        case 406: return .notAcceptable
        case 421: return .misdirectedRequest
        case 500: return .internalServerError
        default: return HTTPStatusCode(code, phrase: "")
        }
    }

    /// Maps the SDK's response onto FlyingFox's. A `.stream` is collected,
    /// which is fine for a stateless transport that never opens one for
    /// `tools/*`; a stream that fails midway becomes an empty 500 rather than
    /// a truncated 200.
    private static func flyingFoxResponse(from answer: MCP.HTTPResponse,
                                          restoring rewrite: IDRewrite) async -> FlyingFox.HTTPResponse {
        var body = Data()
        switch answer {
        case .stream(let stream, _):
            do {
                for try await chunk in stream { body.append(chunk) }
            } catch {
                return FlyingFox.HTTPResponse(statusCode: .internalServerError)
            }
        default:
            body = answer.bodyData ?? Data()
        }
        body = restoreID(in: body, using: rewrite)
        var headers = HTTPHeaders()
        for (name, value) in answer.headers { headers[HTTPHeader(name)] = value }
        return FlyingFox.HTTPResponse(statusCode: statusCode(answer.statusCode), headers: headers, body: body)
    }
}
