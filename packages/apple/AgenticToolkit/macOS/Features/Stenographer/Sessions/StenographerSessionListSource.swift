import Foundation
import AgenticToolkitCore

/// Backs the toolkit's Sessions window with stenographerd from the daemon, so the same UI
/// the Whippet app drives from SQLite is driven here from the daemon's `/sessions`
/// API — keeping the daemon the single source of truth.
///
/// `fetchSessions()` returns instantly from a cached snapshot that a polling loop keeps
/// fresh (mirroring the app's `UsageModel`) rather than awaiting a daemon round-trip on
/// every reload; `onChange` fires only when the snapshot actually changes.
public final class StenographerSessionListSource: SessionWatcher.SessionListSource, @unchecked Sendable {

    private let pollInterval: TimeInterval

    private let lock = NSLock()
    private var cache: [SessionWatcher.SessionWatcherSession] = []
    /// Hours of recency to show (any status); 0 = every session. Mirrors
    /// `UserSettings.stenographerSessionsFilterHours`, pushed in by the window
    /// controller (UserSettings observation stays on the main actor).
    private var sinceHours: Int
    private var onChangeCallback: (@Sendable () -> Void)?

    /// Under `lock` like every other mutable field — that is the whole basis of the
    /// `@unchecked Sendable` above, and this one is not special. `deinit` reaches it
    /// from whichever thread drops the last reference (the view model that owns this
    /// is not `@MainActor`, and its own `deinit` can run off a cooperative-pool
    /// thread), so an unsynchronized read-modify-write here races `startObserving` on
    /// the main actor: either the new task's assignment is lost and its 3-second daemon
    /// poll outlives the window, or the same `Task` is released twice.
    private var pollTask: Task<Void, Never>?

    /// hours → sessions (nil = fetch failed). Injectable so tests can drive the
    /// poll/filter logic without a live daemon; defaults to the daemon path.
    typealias Fetcher = @Sendable (Int) async -> [SessionWatcher.SessionWatcherSession]?
    private let fetcher: Fetcher

    public convenience init(
        service: any StenographerDaemonService, pollInterval: TimeInterval = 3, sinceHours: Int = 24
    ) {
        self.init(pollInterval: pollInterval, sinceHours: sinceHours, fetcher: Self.fetcher(service: service))
    }

    init(pollInterval: TimeInterval = 3, sinceHours: Int = 24, fetcher: @escaping Fetcher) {
        self.pollInterval = pollInterval
        self.sinceHours = sinceHours
        self.fetcher = fetcher
    }

    deinit {
        lock.withLock { pollTask }?.cancel()
    }

    public func fetchSessions() async throws -> [SessionWatcher.SessionWatcherSession] {
        lock.withLock { cache }
    }

    /// Applies a new time filter and refreshes immediately (instead of waiting
    /// out the current poll interval) so the list visibly follows the popup.
    public func setSinceHours(_ hours: Int) {
        let changed: Bool = lock.withLock {
            guard sinceHours != hours else { return false }
            sinceHours = hours
            return true
        }
        guard changed else { return }
        Task { [weak self] in
            guard let self else { return }
            let callback = self.lock.withLock { self.onChangeCallback }
            if await self.refresh() { callback?() }
        }
    }

    public func startObserving(onChange: @escaping @Sendable () -> Void) {
        stopObserving()
        let task = Task { [weak self, pollInterval] in
            while !Task.isCancelled {
                guard let self else { return }
                if await self.refresh() {
                    onChange()
                }
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            }
        }
        // Both fields in one critical section, and the task handed over inside it: a
        // `stopObserving` interleaving between them would otherwise cancel nothing and
        // leave this loop polling the daemon forever.
        let displaced: Task<Void, Never>? = lock.withLock {
            onChangeCallback = onChange
            defer { pollTask = task }
            return pollTask
        }
        displaced?.cancel()
    }

    public func stopObserving() {
        let task: Task<Void, Never>? = lock.withLock {
            defer { pollTask = nil }
            onChangeCallback = nil
            return pollTask
        }
        task?.cancel()
    }

    /// Refreshes the cache and returns whether it changed. The window shows a
    /// time slice — every session (any status) active within `sinceHours` — so
    /// recently-ended sessions stay visible; the daemon orders by
    /// `last_activity_at DESC`, which keeps the live ones on top.
    private func refresh() async -> Bool {
        let hours = lock.withLock { sinceHours }
        // nil = daemon unreachable / transient failure — keep the last good snapshot.
        guard let sessions = await fetcher(hours) else { return false }
        return lock.withLock {
            guard sessions != cache else { return false }
            cache = sessions
            return true
        }
    }

    /// The live fetch: the time-filtered slice from the daemon, or nil on failure.
    private static func fetcher(service: any StenographerDaemonService) -> Fetcher {
        { sinceHours in
            // The window doesn't render event counts; skip the daemon's COUNT join.
            guard let dtos = await service.sessions(
                status: nil, project: nil, sinceHours: sinceHours, includeCounts: false
            ) else {
                return nil
            }
            return dtos.map(StenographerSessionListSource.session(from:))
        }
    }

    /// The one place a daemon session row becomes the toolkit's session model.
    /// Not private because the Conversations window resolves a clicked row's
    /// session the same way, and two spellings of this mapping would let the two
    /// windows disagree about which terminal a session is in.
    static func session(from dto: SessionDTO) -> SessionWatcher.SessionWatcherSession {
        SessionWatcher.SessionWatcherSession(
            sessionId: dto.sessionId,
            cwd: dto.cwd,
            model: dto.model,
            startedAt: dto.startedAt,
            lastActivityAt: dto.lastActivityAt,
            lastTool: dto.lastTool,
            status: SessionWatcher.SessionWatcherStatus(rawValue: dto.status) ?? .active,
            gitBranch: dto.gitBranch,
            summary: dto.summary,
            pid: Int32(truncatingIfNeeded: dto.pid),
            termProgram: dto.termProgram,
            projectRoot: dto.projectRoot,
            termSessionId: dto.termSessionId,
            sessionName: dto.transcriptTitle,
            lastOutput: dto.lastOutput,
            lastEventType: dto.lastEventType,
            subagentWorking: dto.subagentWorking
        )
    }
}
