// macOS/Features/MCP/HostMCPServer.swift
import Foundation
import MCP
import OSLog
import AgenticToolkitCore

/// One MCP server for the host app: every registered `ChatToolSource` is
/// advertised under `tools/list`, and `tools/call` is routed to the source
/// that advertises the name. Transport-agnostic — the in-app chat and the
/// HTTP endpoint hand it different transports.
public actor HostMCPServer {

    /// The request header a caller sets to say which pane it speaks from.
    public static let callerHeader = "X-ADKitchen-Pane"

    private struct Registration {
        let source: any ChatToolSource
        let prefix: String
    }

    private let appName: String
    private let appVersion: String
    /// The SDK server for the current connection. One per `serve(over:)`: the
    /// SDK marks a `Server` initialized on its first `initialize` and never
    /// clears that, not even in `stop()`, so a reused one would answer the
    /// next client's `initialize` with "Server is already initialized".
    private var server: Server?
    private var registrations: [Registration] = []
    private let log = Logger(subsystem: "AgenticToolkit", category: "automation")

    public init(appName: String, appVersion: String) {
        self.appName = appName
        self.appVersion = appVersion
    }

    /// Adds a source. `prefix` is put before every tool name it advertises
    /// and stripped again before the call reaches it.
    public func register(_ source: any ChatToolSource, prefix: String? = nil) {
        registrations.append(Registration(source: source, prefix: prefix ?? ""))
    }

    /// Starts serving over `transport` on a fresh SDK server. If one is
    /// already serving, it is stopped first: the SDK's `Server.start` would
    /// otherwise overwrite its connection and receive task without
    /// cancelling the old ones.
    public func serve(over transport: any Transport) async throws {
        if server != nil { await stop() }
        // Not `.strict`: a stateless HTTP caller sends `tools/call` with no
        // `initialize` first, and strict mode would refuse it.
        let fresh = Server(name: appName, version: appVersion,
                           capabilities: .init(tools: .init(listChanged: false)),
                           configuration: .default)
        await installHandlers(on: fresh)
        try await fresh.start(transport: transport)
        server = fresh
    }

    /// Stops serving. Registrations survive a stop, so a later `serve(over:)`
    /// serves the same tools; callers must not re-register.
    public func stop() async {
        await server?.stop()
        server = nil
    }

    // MARK: - Handlers

    private func installHandlers(on server: Server) async {
        await server.withMethodHandler(ListTools.self) { [weak self] _ in
            guard let self else { return .init(tools: []) }
            return .init(tools: await self.listTools())
        }
        await server.withMethodHandler(CallTool.self) { [weak self] params in
            guard let self else { return Self.errorResult("server is gone") }
            let caller = Self.caller(from: Server.currentHandlerContext?.httpContext)
            return await self.call(name: params.name, arguments: params.arguments ?? [:], caller: caller)
        }
    }

    /// The pane id the HTTP request names in `callerHeader`, if any.
    static func caller(from request: HTTPRequest?) -> String? {
        request?.header(callerHeader)
    }

    private func listTools() async -> [MCP.Tool] {
        var tools: [MCP.Tool] = []
        for registration in registrations {
            for definition in await registration.source.toolDefinitions() {
                let schema = (try? JSONDecoder().decode(Value.self, from: definition.parametersJSONSchema))
                    ?? .object(["type": .string("object"), "properties": .object([:])])
                tools.append(MCP.Tool(name: registration.prefix + definition.name,
                                  description: definition.description,
                                  inputSchema: schema))
            }
        }
        return tools
    }

    func call(name: String, arguments: [String: Value], caller: String?) async -> CallTool.Result {
        for registration in registrations {
            guard name.hasPrefix(registration.prefix) else { continue }
            let bare = String(name.dropFirst(registration.prefix.count))
            let names = await registration.source.toolDefinitions().map(\.name)
            guard names.contains(bare) else { continue }
            let json = (try? JSONEncoder().encode(Value.object(arguments))) ?? Data("{}".utf8)
            let result = await registration.source.callTool(name: bare, argumentsJSON: json, caller: caller)
            log.info("tools/call \(name, privacy: .public) \(result.isError ? "error" : "ok", privacy: .public)")
            return Self.result(result.content, isError: result.isError)
        }
        log.info("tools/call \(name, privacy: .public) unknown")
        return Self.errorResult("unknown tool \(name)")
    }

    // MARK: - Results

    /// A `data:image/png;base64,` answer becomes image content; everything
    /// else is text. The tool set renders screenshots as a data URL so a
    /// text-only chat still gets *something*, and this is where MCP gets the
    /// real thing.
    private static func result(_ content: String, isError: Bool) -> CallTool.Result {
        let pngPrefix = "data:image/png;base64,"
        if content.hasPrefix(pngPrefix) {
            let base64 = String(content.dropFirst(pngPrefix.count))
            let image = MCP.Tool.Content.image(data: base64, mimeType: "image/png", annotations: nil, _meta: nil)
            return .init(content: [image], isError: isError)
        }
        return .init(content: [.text(text: content, annotations: nil, _meta: nil)], isError: isError)
    }

    private static func errorResult(_ sentence: String) -> CallTool.Result {
        result(sentence, isError: true)
    }
}
