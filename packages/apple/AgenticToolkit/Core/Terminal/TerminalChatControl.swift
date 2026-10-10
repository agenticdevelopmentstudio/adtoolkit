import Foundation

/// How a process outside an app — `adterm`, run by Claude Code in an ordinary
/// terminal — drives the app's Terminal Chats: lists them, types a command
/// into one, and gets back what the terminal printed, concealed by that chat's
/// substitutions exactly as its own transcript shows it.
///
/// Each app that hosts Terminal Chats listens on a Unix-domain socket named
/// for its process id in ``socketDirectory``, and answers one JSON request per
/// connection (`UnixSocketLineServer`). The directory is not named after any
/// one app, so a client finds every running host the same way.
public enum TerminalChatControl {

    public enum Action: String, Codable, Sendable {
        /// The chats this app hosts.
        case list
        /// Type `command` into the chat and return the reply.
        case run
        /// More output from a command that outlasted `run`.
        case wait
        /// Control-C, and what the terminal printed in response.
        case interrupt
        /// The last `lines` lines on the terminal's screen.
        case screen
    }

    public struct Request: Codable, Sendable, Equatable {
        public var action: Action
        /// A chat's id, or a prefix of one. Optional when the app hosts
        /// exactly one chat.
        public var chat: String?
        public var command: String?
        /// Seconds output has to stop for before the reply is complete.
        public var settle: Double?
        /// Seconds to wait at most; a command still printing then is
        /// reported as still running.
        public var timeout: Double?
        public var lines: Int?

        public init(action: Action, chat: String? = nil, command: String? = nil,
                    settle: Double? = nil, timeout: Double? = nil, lines: Int? = nil) {
            self.action = action
            self.chat = chat
            self.command = command
            self.settle = settle
            self.timeout = timeout
            self.lines = lines
        }
    }

    public struct Chat: Codable, Sendable, Equatable {
        public var id: String
        public var project: String
        public var directory: String
        /// The pane's number in its project window, as the window shows it.
        public var paneNumber: Int
        /// Whether the chat has a terminal to type into.
        public var connected: Bool

        public init(id: String, project: String, directory: String, paneNumber: Int, connected: Bool) {
            self.id = id
            self.project = project
            self.directory = directory
            self.paneNumber = paneNumber
            self.connected = connected
        }
    }

    public struct Response: Codable, Sendable, Equatable {
        public var error: String?
        /// The app answering, for a client talking to several.
        public var app: String?
        public var chats: [Chat]?
        /// The chat that answered a run, wait, interrupt or screen.
        public var chat: String?
        public var output: String?

        public var isSuccess: Bool { error == nil }

        public init(error: String? = nil, app: String? = nil, chats: [Chat]? = nil,
                    chat: String? = nil, output: String? = nil) {
            self.error = error
            self.app = app
            self.chats = chats
            self.chat = chat
            self.output = output
        }

        public static func failure(_ message: String) -> Response { Response(error: message) }
    }

    /// Picks the chat a request means: the one whose id starts with `query`,
    /// or the only one when `query` is nil. Answers an error message instead
    /// when that is none or more than one.
    public static func resolve(_ query: String?, in chats: [Chat]) -> Result<Chat, ResolveError> {
        let query = query?.lowercased()
        let matches = query.map { prefix in chats.filter { $0.id.lowercased().hasPrefix(prefix) } } ?? chats
        switch matches.count {
        case 1: return .success(matches[0])
        case 0: return .failure(ResolveError(message: query.map { "No Terminal Chat with id \($0)." }
                                             ?? "There is no Terminal Chat open."))
        default:
            let ids = matches.map(\.id).joined(separator: ", ")
            return .failure(ResolveError(message: "More than one Terminal Chat matches — choose one of: \(ids)"))
        }
    }

    public struct ResolveError: Error, Equatable {
        public let message: String
    }

    // MARK: - Where the sockets are

    /// `~/Library/Application Support/TerminalChat/sockets` — owner-only, so
    /// the sockets in it are reachable by this user alone.
    public static var socketDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/TerminalChat/sockets", isDirectory: true)
    }

    public static func socketURL(pid: Int32, in directory: URL = socketDirectory) -> URL {
        directory.appendingPathComponent("\(pid).sock")
    }

    /// Creates ``socketDirectory`` owner-only, and removes the sockets of
    /// processes that are no longer running.
    public static func prepareSocketDirectory(_ directory: URL = socketDirectory) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        for host in runningHosts(in: directory, includeStale: true) where !isRunning(host.pid) {
            try? FileManager.default.removeItem(at: host.socket)
        }
    }

    public struct Host: Sendable, Equatable {
        public let pid: Int32
        public let socket: URL
    }

    /// Every app with a control socket whose process is still running.
    public static func runningHosts(in directory: URL = socketDirectory) -> [Host] {
        runningHosts(in: directory, includeStale: false)
    }

    private static func runningHosts(in directory: URL, includeStale: Bool) -> [Host] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return names.compactMap { name -> Host? in
            guard name.hasSuffix(".sock"), let pid = Int32(name.dropLast(5)) else { return nil }
            guard includeStale || isRunning(pid) else { return nil }
            return Host(pid: pid, socket: directory.appendingPathComponent(name))
        }.sorted { $0.pid < $1.pid }
    }

    private static func isRunning(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0 || errno == EPERM
    }

    // MARK: - Asking

    /// Sends `request` to the app at `host` and decodes its answer.
    ///
    /// The wait is the request's own timeout plus a margin, so a long `run`
    /// is not cut off by the transport before the app reports it.
    public static func send(_ request: Request, to host: Host) throws -> Response {
        let payload = try JSONEncoder().encode(request)
        let waitSeconds = (request.timeout ?? 60) + 15
        let reply = try UnixSocketLineClient.request(payload, path: host.socket.path, timeout: waitSeconds)
        return try JSONDecoder().decode(Response.self, from: reply)
    }
}
