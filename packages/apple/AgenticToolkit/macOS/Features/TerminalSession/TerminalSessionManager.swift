import AgenticToolkitCore
import Combine
import Foundation
import os

/// Manages an ordered list of terminal sessions for a single window.
@MainActor
public final class TerminalSessionManager: ObservableObject {
    @Published public var sessions: [TerminalSession] = []
    @Published public var selectedSessionID: UUID?

    private var sessionCounter: Int = 0
    public let workingDirectory: String?

    /// Extra shell variables every session this manager opens gets.
    public let environment: [String: String]

    public init(workingDirectory: String? = nil, environment: [String: String] = [:]) {
        self.workingDirectory = workingDirectory
        self.environment = environment
    }

    public var selectedSession: TerminalSession? {
        guard let id = selectedSessionID else { return nil }
        return sessions.first { $0.id == id }
    }

    @discardableResult
    public func addSession() -> TerminalSession {
        sessionCounter += 1
        let session = TerminalSession(
            name: "Session \(sessionCounter)", workingDirectory: workingDirectory, environment: environment)
        sessions.append(session)
        selectedSessionID = session.id
        logger.info("Added session '\(session.name)' (\(session.id)), total: \(self.sessions.count)")
        return session
    }

    public func removeSession(id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }

        let removedSession = sessions[index]
        logger.info("Removing session '\(removedSession.name)' (\(id))")
        removedSession.terminateProcess()
        sessions.remove(at: index)

        if selectedSessionID == id {
            if sessions.isEmpty {
                selectedSessionID = nil
            } else {
                let newIndex = min(index, sessions.count - 1)
                selectedSessionID = sessions[newIndex].id
            }
        }
    }

    public func selectSession(id: UUID) {
        if sessions.contains(where: { $0.id == id }) {
            selectedSessionID = id
        }
    }

    public func terminateAll() {
        logger.info("Terminating all \(self.sessions.count) session(s)")
        for session in sessions {
            session.terminateProcess()
        }
    }
}

extension TerminalSessionManager: Loggable {
    public static nonisolated let logger = makeLogger()
}
