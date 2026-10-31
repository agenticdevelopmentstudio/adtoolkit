import Combine
import Foundation
import AgenticToolkitCore
import os

/// The terminals the coding partner has open, newest first.
///
/// Opens each one in its own ``TerminalSessionManager`` with the variables
/// that tell a shell which pane it is (`ADKITCHEN_PANE_ID`) and which project
/// (`ADKITCHEN_PROJECT`), records it in the store, and turns its detector's
/// reports into ``PartnerInbound`` events for the partner.
@MainActor
public final class PartnerSessionRegistry: ObservableObject {

    /// Newest first.
    @Published public private(set) var sessions: [PartnerSession] = []

    /// A session went idle or exited.
    public var onEvent: ((PartnerInbound) -> Void)?

    private let store: PartnerStore
    private let environment: () -> [String: String]
    private let detector: any PartnerSessionEventDetecting
    private let now: () -> Date

    public init(store: PartnerStore, environment: @escaping () -> [String: String],
                detector: any PartnerSessionEventDetecting, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.environment = environment
        self.detector = detector
        self.now = now
        detector.onIdle = { [weak self] id in self?.sessionWentIdle(id: id) }
        detector.onExit = { [weak self] id in self?.sessionExited(id: id) }
    }

    /// Opens a shell in `directory` and, once it is running, types
    /// `firstCommand` into it.
    ///
    /// - Parameters:
    ///   - title: Defaults to the directory's last path component.
    ///   - reviewID: The review the session works for, stored with its first record.
    @discardableResult
    public func open(directory: String, title: String?, firstCommand: String?,
                     reviewID: String? = nil) -> PartnerSession {
        let id = UUID()
        var variables = environment()
        variables["ADKITCHEN_PANE_ID"] = id.uuidString
        // What Claude Code's hooks record as the session's terminal, so the
        // Stop detector can tell this pane's agent from any other in the same
        // directory. Set here, over anything inherited, or every pane would
        // carry the same one.
        variables["TERM_SESSION_ID"] = id.uuidString
        variables["ADKITCHEN_PROJECT"] = directory
        let manager = TerminalSessionManager(workingDirectory: directory, environment: variables)
        let terminal = manager.addSession()
        let chat = TerminalChatSession()
        // Connecting reads the screen, which creates the terminal view, which
        // starts the shell: no window is needed for it to run.
        chat.connect(to: terminal)
        let viewController = TerminalSessionContentViewController(sessionManager: manager)
        viewController.loadViewIfNeeded()

        let session = PartnerSession(
            id: id, title: title ?? (directory as NSString).lastPathComponent, directory: directory,
            manager: manager, terminal: terminal, chat: chat, viewController: viewController, now: now)
        session.reviewID = reviewID
        sessions.insert(session, at: 0)
        save(session.record)
        detector.watch(session)

        if let firstCommand {
            Task { [weak terminal] in
                for _ in 0..<50 {
                    guard let terminal else { return }
                    if terminal.isRunning {
                        terminal.sendInput(firstCommand + "\n")
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
                Self.logger.error("Partner session \(id) never started; first command not sent")
            }
        }
        return session
    }

    public func session(id: UUID) -> PartnerSession? {
        sessions.first { $0.id == id }
    }

    /// Ends the session's shell and records its final screen and when it closed.
    public func close(id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        let session = sessions.remove(at: index)
        // Unwatched first: a close the partner asked for is not an exit to tell
        // it about.
        detector.unwatch(id: id)
        var record = session.record
        record.finalScreen = session.screenText()
        record.closedAt = session.exitedAt ?? now()
        session.chat.close()
        session.manager.terminateAll()
        save(record)
    }

    /// Closes every session, for quit. Returns the ids that were closed.
    public func closeAll() -> [String] {
        let ids = sessions.map(\.id)
        for id in ids { close(id: id) }
        return ids.map(\.uuidString)
    }

    /// Forgets stored sessions closed more than `retentionDays` ago.
    public func purge(retentionDays: Int) {
        let cutoff = now().addingTimeInterval(-TimeInterval(retentionDays) * 86_400)
        do {
            _ = try store.purgeSessions(closedBefore: cutoff)
        } catch {
            Self.logger.error("Purging partner sessions failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Detector reports

    private func sessionWentIdle(id: UUID) {
        guard let session = session(id: id), session.state == .running else { return }
        session.markIdle()
        onEvent?(.sessionIdle(sessionID: id.uuidString, title: session.title))
    }

    private func sessionExited(id: UUID) {
        guard let session = session(id: id), session.state != .exited else { return }
        let exitedAt = now()
        session.markExited(at: exitedAt)
        detector.unwatch(id: id)
        var record = session.record
        record.finalScreen = session.screenText()
        record.closedAt = exitedAt
        save(record)
        onEvent?(.sessionExited(sessionID: id.uuidString, title: session.title))
    }

    private func save(_ record: PartnerStore.SessionRecord) {
        do {
            try store.upsert(record)
        } catch {
            Self.logger.error("Saving partner session \(record.id) failed: \(error.localizedDescription)")
        }
    }
}

extension PartnerSessionRegistry: Loggable {
    public static nonisolated let logger = makeLogger()
}
