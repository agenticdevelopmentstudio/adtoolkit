import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

import AppKit
import Foundation

/// Everything Stenographer-specific about the Conversations window: where the
/// feed comes from, how a daemon entry becomes a chat message, and what a row
/// click means here.
///
/// The window itself — the poll, the filter, the rows — is the toolkit's
/// ``ConversationsViewController``, which knows nothing about stenographerd.
/// This is the whole of the seam between them, which is why it is a handful of
/// free functions rather than a type: there is no state to hold.
@MainActor
final class ConversationsFeed {

    private let service: any StenographerDaemonService

    init(service: any StenographerDaemonService) { self.service = service }

    /// How many entries the window holds while it is showing every session.
    /// The feed is re-read whole on every poll (an entry can be reclassified or
    /// filtered out between reads), so this is a working-set size, not a page
    /// cursor — a few hundred lines is more scrollback than anyone reads and
    /// still one cheap indexed query.
    ///
    /// A window with sessions hidden asks for a multiple of it: the daemon
    /// answers across every session, and the hidden ones' share of that answer
    /// is thrown away here — see ``ConversationsSessionFilter/pageDeepening``.
    static let limit = 200

    /// The feed as it stands, oldest first, or nil when the daemon can't be
    /// reached — which the window reads as "keep what's on screen".
    ///
    /// `sessionID` narrows to one conversation, which is what the focus overlay
    /// reads. Passed down to the daemon rather than applied here: the merged
    /// answer is the newest ``limit`` lines across *every* session, so one
    /// session's share of it is a handful — filtering it client-side would show
    /// a conversation with most of itself missing.
    func load(
        includeWorkOutput: Bool,
        sessionID: String? = nil,
        limit: Int = ConversationsFeed.limit
    ) async -> [ChatMessage]? {
        guard let entries = await service.conversations(
            limit: limit,
            includeWorkOutput: includeWorkOutput,
            sessionId: sessionID
        ) else {
            return nil
        }
        // The daemon answers newest-first — that is what makes `before` paging
        // work — and a chat transcript reads the other way round.
        return entries.reversed().map(Self.message(from:))
    }

    // MARK: - Mapping

    /// One daemon entry as a chat message.
    ///
    /// The `kind` vocabulary is wider than the three roles a chat has, and the
    /// narrowing is deliberate: the two work-output kinds are still the agent
    /// talking, so they stay `.assistant` and are told apart by
    /// `isWorkOutput` — which the bubble draws in muted text — and by their
    /// icon, rather than by a role the bubble would colour differently. A
    /// reader who has turned work output on wants it *in* the conversation, not
    /// beside it.
    nonisolated static func message(from entry: ConversationEntryDTO) -> ChatMessage {
        ChatMessage(
            id: String(entry.id),
            role: role(of: entry),
            text: entry.text,
            timestamp: date(from: entry.timestamp),
            attribution: ChatMessage.Attribution(
                sourceID: entry.sessionId,
                context: context(of: entry),
                name: entry.sessionName,
                iconSymbol: iconSymbol(of: entry),
                appIdentity: entry.termProgram
            ),
            isWorkOutput: entry.isWorkOutput
        )
    }

    private nonisolated static func role(of entry: ConversationEntryDTO) -> ChatMessage.Role {
        if entry.isFromUser { return .user }
        return entry.kind == "notice" ? .notice : .assistant
    }

    /// The project and the branch — the two facts that identify *which*
    /// checkout is talking, which in a feed spanning worktrees of the same
    /// project is the only thing telling two sessions apart.
    ///
    /// Kept as two crumbs rather than joined into `project/branch`: the row
    /// draws them apart, in different colours, and a branch name has slashes of
    /// its own, so a joined string could never be taken back apart. Either half
    /// may be missing — a session outside a repo, or one whose cwd has not been
    /// recorded yet — and an empty crumb is dropped rather than drawn as a gap.
    private nonisolated static func context(of entry: ConversationEntryDTO) -> [String] {
        [entry.projectName, entry.gitBranch].filter { !$0.isEmpty }
    }

    /// The icon names the agent's kinds apart, since they share a role and a
    /// side; the bubble's muted text says only "work output or not". Naming
    /// them matters most when work output is on: that is the mode where a
    /// row's kind stops being obvious from its side.
    private nonisolated static func iconSymbol(of entry: ConversationEntryDTO) -> String {
        switch entry.kind {
        case "prompt":   return "person.crop.circle.fill"
        case "thinking": return "brain"
        case "progress": return "ellipsis.bubble"
        case "notice":   return "exclamationmark.circle"
        default:         return "sparkles"
        }
    }

    /// Transcript stamps carry milliseconds; not every row does. An unparseable
    /// stamp becomes "now" rather than 1970 — the row is already in place in a
    /// feed the daemon ordered, and a 1970 time under it would read as a bug in
    /// the entry rather than in its clock.
    private nonisolated static func date(from text: String) -> Date {
        let parsed = formatterLock.withLock {
            fractional.date(from: text) ?? whole.date(from: text)
        }
        return parsed ?? Date()
    }

    /// `ISO8601DateFormatter` publishes no thread-safety guarantee (unlike
    /// `DateFormatter`), and these two are reached from the feed's poll — off the
    /// main actor, and a second poll can start while one is mapping. A lock
    /// rather than a formatter per call because this runs once per entry per
    /// poll, and constructing one is expensive relative to parsing with it.
    private nonisolated static let formatterLock = NSLock()

    /// Never touched outside ``formatterLock``.
    nonisolated(unsafe) private static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Never touched outside ``formatterLock``.
    nonisolated(unsafe) private static let whole: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Writing back

    /// Types `text` into an observed session's terminal, as if the human at
    /// that keyboard had typed it. Nil when the line was handed over, or the
    /// reason it could not be.
    ///
    /// "Handed over" is as strong as this gets: AppleScript's `write text`
    /// leaves the characters in the pane and presses Return, and what Claude
    /// does with them is Claude's business. The window learns the line was
    /// taken by reading it back out of the daemon on a later poll — the same
    /// way it learns about every other line in the feed.
    ///
    /// The terminal is *not* brought forward (`raising` defaults to off). A
    /// reader typing into one conversation of many is reading this window;
    /// jumping them into that session's terminal would take away the thing
    /// they were looking at. Going there is ``activateSession(id:)``, a
    /// separate gesture with its own control.
    func send(to sessionID: String, text: String) async -> String? {
        // Asked for by id rather than picked out of the list of every session:
        // that list is capped, costs the whole table's worth of JSON over XPC,
        // and answers "couldn't reach the daemon" and "no such session" with
        // the same nil — which are different things to tell somebody holding a
        // message that did not go.
        guard let found = await service.session(id: sessionID) else {
            return "Couldn't reach the daemon — it may be restarting. Try again."
        }
        guard let dto = found else {
            return "The daemon has no record of this session any more."
        }
        guard TerminalTextInjector.isSupported(termProgram: dto.termProgram) else {
            let term = dto.termProgram.isEmpty ? "an unknown terminal" : dto.termProgram
            return "Typing into a session needs iTerm2 or Terminal.app; this one runs in \(term)."
        }
        let result = TerminalTextInjector.inject(
            text, termProgram: dto.termProgram,
            termSessionId: dto.termSessionId, pid: dto.pid
        )
        if case .failure(let error) = result {
            return error.localizedDescription
        }
        return nil
    }

    // MARK: - Row action

    /// Brings the clicked row's session forward — the terminal tab it is
    /// running in, found the way the Sessions window finds it. Nil when it
    /// went there, or the reason it could not.
    ///
    /// Always `.activateWindow`, whatever `UserSettings.clickAction` says: that
    /// pref is the Sessions list's, and it can name actions — open a fresh
    /// terminal, run a command — that are the wrong answer to "take me there"
    /// from a feed row.
    ///
    /// The handler is left on its default of no Accessibility, as the Sessions
    /// window's is: an iTerm2 or Terminal.app session's tab is selected by
    /// Apple Event, and any other terminal is brought forward whole. Checking
    /// for an Accessibility grant Stenographer never asks for stalls tccd, and
    /// with it the whole machine, for ~10s.
    func activateSession(id: String) async -> String? {
        // The feed carries only a session id; the activation needs the
        // session's terminal identity (pid, term program, tab id), which
        // lives on the session record.
        // One row by id — not the whole session list searched client-side,
        // which read and encoded up to 10,000 sessions to find this one.
        // No event count: activation never reads it, and counting walks
        // every event the session logged.
        guard let found = await service.session(id: id, includeCounts: false) else {
            return "Couldn't reach the daemon — it may be restarting. Try again."
        }
        guard let dto = found else {
            return "The daemon has no record of this session any more."
        }
        let handler = SessionWatcher.SessionWatcherActionHandler(
            settingsStore: UserSettings.shared,
            usesAccessibility: false
        )
        let result = handler.execute(
            action: .activateWindow,
            for: StenographerSessionListSource.session(from: dto)
        )
        if case .failure(let error) = result {
            return error.localizedDescription
        }
        return nil
    }
}
