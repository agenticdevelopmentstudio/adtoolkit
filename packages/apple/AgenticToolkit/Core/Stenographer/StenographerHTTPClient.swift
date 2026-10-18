import Foundation

/// ``StenographerDaemonService`` over the daemon's loopback HTTP API.
///
/// Same routes `steno` uses: everything is JSON in `StenographerWire` spelling
/// (snake_case, ISO-8601). A failed connection, a non-2xx reply or a body that
/// does not decode all read as "unreachable" (nil / false); the one exception is
/// a 404 on a single session, which is a real answer ("no such session").
///
/// Reconnect: the daemon has no push channel to a client that is not an XPC
/// subscriber, so this polls `/health` and treats an `uptime` that went *down*
/// as a restart, firing every registered handler once.
public final class StenographerHTTPClient: StenographerDaemonService, @unchecked Sendable {

    public static var defaultBaseURL: URL {
        if let raw = ProcessInfo.processInfo.environment["STENOGRAPHER_URL"], let url = URL(string: raw) {
            return url
        }
        return URL(string: StenographerIdentifiers.httpBaseURL)!
    }

    private let baseURL: URL
    private let session: URLSession
    private let healthPollInterval: TimeInterval
    private let encoder = StenographerWire.encoder()
    private let decoder = StenographerWire.decoder()

    private let lock = NSLock()
    private var reconnectHandlers: [@Sendable () -> Void] = []
    private var lastUptime: TimeInterval?
    private var healthTask: Task<Void, Never>?

    public init(
        baseURL: URL = StenographerHTTPClient.defaultBaseURL,
        session: URLSession = .shared,
        healthPollInterval: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.session = session
        self.healthPollInterval = healthPollInterval
    }

    deinit { lock.withLock { healthTask }?.cancel() }

    // MARK: - Reads

    public func health() async -> HealthDTO? { await get("/health") }

    public func sessions(
        status: String?, project: String?, sinceHours: Int, includeCounts: Bool
    ) async -> [SessionDTO]? {
        var items: [URLQueryItem] = []
        if let status { items.append(URLQueryItem(name: "status", value: status)) }
        if let project { items.append(URLQueryItem(name: "project", value: project)) }
        if sinceHours > 0 { items.append(URLQueryItem(name: "since_hours", value: String(sinceHours))) }
        if !includeCounts { items.append(URLQueryItem(name: "counts", value: "false")) }
        return await get("/sessions", query: items)
    }

    public func session(id: String, includeCounts: Bool) async -> SessionDTO?? {
        let query = includeCounts ? [] : [URLQueryItem(name: "counts", value: "false")]
        guard let reply = await request(method: "GET", path: "/sessions/\(id)", query: query, body: nil) else {
            return nil
        }
        if reply.status == 404 { return .some(nil) }
        guard (200..<300).contains(reply.status),
              let detail = try? decoder.decode(SessionDetailDTO.self, from: reply.body) else { return nil }
        return .some(detail.session)
    }

    public func summarize(sessionId: String) async throws {
        let path = "/sessions/\(sessionId)/summarize"
        guard let reply = await request(method: "POST", path: path, query: [], body: Data()) else {
            throw URLError(.cannotConnectToHost)
        }
        guard (200..<300).contains(reply.status) else {
            throw SummarizeDaemonFailure(reason: errorMessage(reply.body) ?? "HTTP \(reply.status)")
        }
    }

    public func conversations(
        limit: Int, includeWorkOutput: Bool, before: String?, sessionId: String?
    ) async -> [ConversationEntryDTO]? {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if includeWorkOutput { items.append(URLQueryItem(name: "work", value: "true")) }
        if let before { items.append(URLQueryItem(name: "before", value: before)) }
        if let sessionId { items.append(URLQueryItem(name: "session_id", value: sessionId)) }
        return await get("/conversations", query: items)
    }

    public func oversightFindings(status: String?) async -> [OversightFindingDTO]? {
        await get("/oversight/findings", query: status.map { [URLQueryItem(name: "status", value: $0)] } ?? [])
    }

    public func oversightActionTarget(findingId: Int) async -> OversightActionTargetDTO? {
        await get("/oversight/findings/\(findingId)/action")
    }

    public func actOnOversightFinding(findingId: Int) async -> OversightActResultDTO? {
        let path = "/oversight/findings/\(findingId)/act"
        guard let reply = await request(method: "POST", path: path, query: [], body: Data()) else {
            return nil
        }
        if (200..<300).contains(reply.status) {
            let finding = try? decoder.decode(OversightFindingDTO.self, from: reply.body)
            return OversightActResultDTO(
                findingId: findingId, succeeded: true, status: finding?.status ?? "acted", reason: "")
        }
        return OversightActResultDTO(
            findingId: findingId, succeeded: false, status: "",
            reason: errorMessage(reply.body) ?? "HTTP \(reply.status)")
    }

    public func oversightScripts() async -> [OversightScript]? { await get("/oversight/scripts") }

    public func saveOversightScript(_ script: OversightScript) async -> OversightScript? {
        guard let body = try? encoder.encode(script) else { return nil }
        return await post("/oversight/scripts/\(script.id)", body: body)
    }

    public func deleteOversightScript(id: String) async -> Bool {
        let path = "/oversight/scripts/\(id)/delete"
        guard let reply = await request(method: "POST", path: path, query: [], body: Data()) else {
            return false
        }
        return (200..<300).contains(reply.status)
    }

    public func resetOversightScript(id: String) async -> OversightScript? {
        await post("/oversight/scripts/\(id)/reset", body: Data())
    }

    public func aiInteractions(limit: Int) async -> [AIInteractionDTO]? {
        await get("/ai/interactions", query: [URLQueryItem(name: "limit", value: String(limit))])
    }

    public func aiInteraction(id: Int) async -> AIInteractionDTO? { await get("/ai/interactions/\(id)") }

    public func aiProviderConfigs() async -> [DaemonProviderConfig]? { await get("/preferences/ai/configs") }
    public func summaryPreferences() async -> SummaryPreferenceResponse? { await get("/preferences/summaries") }
    public func oversightPreferences() async -> OversightPreferenceResponse? { await get("/preferences/oversight") }

    public func setSummaryPreferences(_ request: SummaryPreferenceRequest) async -> Bool {
        guard let body = try? encoder.encode(request) else { return false }
        let reply: SummaryPreferenceResponse? = await post("/preferences/summaries", body: body)
        return reply != nil
    }

    public func setOversightPreferences(_ request: OversightPreferenceRequest) async -> Bool {
        guard let body = try? encoder.encode(request) else { return false }
        let reply: OversightPreferenceResponse? = await post("/preferences/oversight", body: body)
        return reply != nil
    }

    /// Sent with a plain encoder: `POST /preferences/ai` decodes the registry
    /// with a default `JSONDecoder`, so its keys stay camelCase (not the wire
    /// encoder's snake_case).
    public func setAIPreferences(_ sync: AIProviderConfigSync) async -> Bool {
        guard let body = try? JSONEncoder().encode(sync) else { return false }
        guard let reply = await request(method: "POST", path: "/preferences/ai", query: [], body: body) else {
            return false
        }
        return (200..<300).contains(reply.status)
    }

    // MARK: - Reconnect

    public func onReconnect(_ handler: @escaping @Sendable () -> Void) {
        let startPolling: Bool = lock.withLock {
            reconnectHandlers.append(handler)
            return healthTask == nil
        }
        guard startPolling else { return }
        let task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.pollHealthOnce()
                try? await Task.sleep(nanoseconds: UInt64(self.healthPollInterval * 1_000_000_000))
            }
        }
        lock.withLock { healthTask = task }
    }

    private func pollHealthOnce() async {
        guard let health = await health() else { return }
        let fire: [@Sendable () -> Void] = lock.withLock {
            defer { lastUptime = health.uptime }
            guard let previous = lastUptime, health.uptime < previous else { return [] }
            return reconnectHandlers
        }
        for handler in fire { handler() }
    }

    // MARK: - Transport

    private struct Reply {
        let status: Int
        let body: Data
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async -> T? {
        guard let reply = await request(method: "GET", path: path, query: query, body: nil),
              (200..<300).contains(reply.status) else { return nil }
        return try? decoder.decode(T.self, from: reply.body)
    }

    private func post<T: Decodable>(_ path: String, body: Data) async -> T? {
        guard let reply = await request(method: "POST", path: path, query: [], body: body),
              (200..<300).contains(reply.status) else { return nil }
        return try? decoder.decode(T.self, from: reply.body)
    }

    private func request(method: String, path: String, query: [URLQueryItem], body: Data?) async -> Reply? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        components.path = path
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = Self.timeout(method: method, path: path)
        if let body {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        guard let (data, response) = try? await session.data(for: urlRequest),
              let http = response as? HTTPURLResponse else { return nil }
        return Reply(status: http.statusCode, body: data)
    }

    /// How long a request may take. A summary runs inline on the daemon for up to the
    /// user's largest "Give up after" (600 s), so it gets that plus 5 s. The heavy reads
    /// can be slow on a cold cache and get 15 s. Everything else is a quick read: 10 s.
    static func timeout(method: String, path: String) -> TimeInterval {
        if method == "POST" && path.hasSuffix("/summarize") { return 605 }
        if method == "GET" && (path == "/conversations" || path == "/ai/interactions"
                               || path.hasPrefix("/ai/interactions/")) {
            return 15
        }
        return 10
    }

    /// The `{"error": "…"}` body DaemonKit's `HTTPResponse.error` produces.
    private func errorMessage(_ body: Data) -> String? {
        struct ErrorBody: Decodable { let error: String }
        return (try? decoder.decode(ErrorBody.self, from: body))?.error
    }
}
