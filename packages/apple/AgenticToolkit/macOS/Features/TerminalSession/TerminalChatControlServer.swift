import Foundation
import AgenticToolkitCore

/// The Terminal Chats an app has open, by id — what a
/// ``TerminalChatControlServer`` answers from.
///
/// A Terminal Chat pane adds itself when it is made and removes itself when
/// it is discarded. Sessions are held weakly besides, so a pane that goes
/// without saying so drops out rather than lingering.
@MainActor
public final class TerminalChatDirectory {

    public struct Listing {
        /// Short and stable: the start of the pane's layout node id, which
        /// survives relaunches.
        public let id: String
        public let project: String
        public let directory: URL
        public let paneNumber: Int
    }

    private struct Entry {
        let listing: Listing
        weak var session: TerminalChatSession?
    }

    private var entries: [String: Entry] = [:]

    public init() {}

    public func add(_ session: TerminalChatSession, as listing: Listing) {
        entries[listing.id] = Entry(listing: listing, session: session)
    }

    public func remove(id: String) {
        entries[id] = nil
    }

    /// The id a pane's chat is listed under.
    public static func chatID(forNode nodeID: UUID) -> String {
        String(nodeID.uuidString.prefix(8)).lowercased()
    }

    var chats: [(TerminalChatControl.Chat, TerminalChatSession)] {
        entries = entries.filter { $0.value.session != nil }
        return entries.values.compactMap { entry in
            guard let session = entry.session else { return nil }
            let listing = entry.listing
            // Concealed like everything else the chat reports: a home
            // directory or a project named after the user gives them away.
            let chat = TerminalChatControl.Chat(
                id: listing.id,
                project: session.filter.concealing(listing.project),
                directory: session.filter.concealing(listing.directory.path),
                paneNumber: listing.paneNumber, connected: session.terminal != nil)
            return (chat, session)
        }.sorted { ($0.0.project, $0.0.paneNumber) < ($1.0.project, $1.0.paneNumber) }
    }
}

/// Lets a process outside the app drive its Terminal Chats, over the protocol
/// ``TerminalChatControl`` defines: `adterm`, run by Claude Code in another
/// terminal, types into a chat here and reads the concealed reply.
///
/// Everything goes through the chat, never the terminal, so what the caller
/// sends is revealed by the chat's substitutions and what it reads back is
/// concealed by them — and it shows in the chat's transcript as it happens.
@MainActor
public final class TerminalChatControlServer {

    private let directory: TerminalChatDirectory
    private let appName: String
    private var server: UnixSocketLineServer?

    public init(directory: TerminalChatDirectory, appName: String) {
        self.directory = directory
        self.appName = appName
    }

    /// Listens at this process's socket in `TerminalChatControl.socketDirectory`.
    public func start() throws {
        guard server == nil else { return }
        try TerminalChatControl.prepareSocketDirectory()
        let path = TerminalChatControl.socketURL(pid: ProcessInfo.processInfo.processIdentifier).path
        let server = UnixSocketLineServer(path: path) { [weak self] data in
            await self?.answer(data) ?? Self.encode(.failure("The app is shutting down."))
        }
        try server.start()
        self.server = server
    }

    public func stop() {
        server?.stop()
        server = nil
    }

    private func answer(_ data: Data) async -> Data {
        guard let request = try? JSONDecoder().decode(TerminalChatControl.Request.self, from: data) else {
            return Self.encode(.failure("Not a Terminal Chat request."))
        }
        var response = await respond(to: request)
        response.app = appName
        return Self.encode(response)
    }

    private func respond(to request: TerminalChatControl.Request) async -> TerminalChatControl.Response {
        let chats = directory.chats
        if request.action == .list {
            return .init(chats: chats.map(\.0))
        }
        let chat: TerminalChatControl.Chat
        switch TerminalChatControl.resolve(request.chat, in: chats.map(\.0)) {
        case .success(let found): chat = found
        case .failure(let error): return .failure(error.message)
        }
        guard let session = chats.first(where: { $0.0.id == chat.id })?.1, session.terminal != nil else {
            return .failure("Terminal Chat \(chat.id) is not connected to a terminal — turn on "
                            + "Connect to terminal in its pane's Settings.")
        }
        let settle = Self.duration(request.settle, default: 1.5, limit: 60)
        let timeout = Self.duration(request.timeout, default: 60, limit: 600)

        switch request.action {
        case .run:
            guard let command = request.command, !command.isEmpty else {
                return .failure("run needs a command.")
            }
            return .init(chat: chat.id, output: await session.run(command, settle: settle, timeout: timeout))
        case .wait:
            return .init(chat: chat.id, output: await session.waitForOutput(settle: settle, timeout: timeout))
        case .interrupt:
            return .init(chat: chat.id, output: await session.interruptAndWait(settle: settle))
        case .screen:
            return .init(chat: chat.id, output: session.screen(lines: request.lines ?? 40) ?? "")
        case .list:
            return .init(chats: chats.map(\.0))
        }
    }

    private static func duration(_ seconds: Double?, default fallback: Double, limit: Double) -> Duration {
        .milliseconds(Int(min(max(seconds ?? fallback, 0.1), limit) * 1000))
    }

    private nonisolated static func encode(_ response: TerminalChatControl.Response) -> Data {
        (try? JSONEncoder().encode(response)) ?? Data(#"{"error":"Could not encode the reply."}"#.utf8)
    }
}
