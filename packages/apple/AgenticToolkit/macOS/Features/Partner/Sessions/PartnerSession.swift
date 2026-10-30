import Combine
import Foundation

/// A terminal the coding partner opened: one shell in one directory, with the
/// chat that types into it and the view that shows it.
///
/// Made and owned by ``PartnerSessionRegistry``, which moves ``state`` as its
/// detector reports.
@MainActor
public final class PartnerSession: Identifiable, ObservableObject {

    public enum State: String, Sendable {
        /// The shell is working, or has printed since it last went idle.
        case running
        /// The detector judged the shell finished with what it was doing.
        case idle
        /// The shell has exited.
        case exited
    }

    public let id: UUID
    public let title: String
    public let directory: String
    public let manager: TerminalSessionManager
    public let terminal: TerminalSession
    public let chat: TerminalChatSession
    public let viewController: TerminalSessionContentViewController

    @Published public private(set) var state: State = .running
    @Published public private(set) var lastActivity: Date

    /// The review this session works for, when it was opened for one.
    public var reviewID: String?

    public let openedAt: Date

    private var subscriptions: Set<AnyCancellable> = []

    init(id: UUID, title: String, directory: String, manager: TerminalSessionManager, terminal: TerminalSession,
         chat: TerminalChatSession, viewController: TerminalSessionContentViewController,
         now: @escaping () -> Date) {
        self.id = id
        self.title = title
        self.directory = directory
        self.manager = manager
        self.terminal = terminal
        self.chat = chat
        self.viewController = viewController
        self.openedAt = now()
        self.lastActivity = openedAt
        terminal.outputActivity
            .sink { [weak self] in MainActor.assumeIsolated { self?.outputArrived(at: now()) } }
            .store(in: &subscriptions)
    }

    private func outputArrived(at date: Date) {
        lastActivity = date
        if state == .idle { state = .running }
    }

    func markIdle() {
        guard state == .running else { return }
        state = .idle
    }

    func markExited() {
        state = .exited
    }

    /// The last `lines` non-blank-trailing lines the terminal shows, read off
    /// the terminal itself so it still works once the chat has let go of an
    /// exited shell.
    func screenText(lines: Int = 200) -> String {
        var rows = terminal.screenSnapshot().lines
        while rows.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { rows.removeLast() }
        return rows.suffix(lines).joined(separator: "\n")
    }

    var record: PartnerStore.SessionRecord {
        PartnerStore.SessionRecord(id: id.uuidString, title: title, directory: directory, openedAt: openedAt,
                                   reviewID: reviewID)
    }
}
