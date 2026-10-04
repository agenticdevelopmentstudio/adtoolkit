import Foundation

/// Lets any number of independently-gated consumers observe one
/// window-lifecycle source.
///
/// Three consumers in the daemon need the same observation for different
/// reasons: `WindowLifecycleContextTrigger` records the created/destroyed/
/// retitled events themselves, `AppFocusTrigger` needs only the retitle nudge
/// (switching a browser tab changes the window title without activating any
/// application, so it produces no focus event at all), and `UsageCollector`
/// needs that same nudge to re-poll focus.
///
/// They are opted into separately, start and stop at different times, and none
/// may switch the others off. Handing them all the same bare
/// `WindowLifecycleAdapter` would do exactly that — whichever stopped first
/// would tear down the observer the others were still using — and it would
/// also give them one `onEvent` slot to fight over, since the protocol's
/// callbacks are single closures. Giving each its own adapter instead runs a
/// full `SystemWindowObserver` per consumer over every application on the
/// machine, for one stream of events.
///
/// So this type is a hub, not a source: ``makeClient()`` vends one
/// `WindowLifecycleSource` facade per consumer, each with its own callbacks
/// and its own `start()`/`stop()`. Every callback fans out to the clients that
/// are currently started, and the base source observes exactly while at least
/// one of them is.
@MainActor
public final class SharedWindowLifecycleSource {
    private let base: any WindowLifecycleSource

    /// Weak, because each client is owned by the consumer that asked for it:
    /// a consumer that goes away should not keep its client — or the
    /// observation — alive. Compacted whenever the list is walked.
    private var clients: [WeakClient] = []
    private var isObservingBase = false

    public init(_ base: any WindowLifecycleSource) {
        self.base = base
        base.onEvent = { [weak self] kind, app, windowID, title in
            self?.forEachRunningClient { $0.onEvent?(kind, app, windowID, title) }
        }
        base.onTitleChange = { [weak self] in
            self?.forEachRunningClient { $0.onTitleChange?() }
        }
    }

    /// A facade over the shared observation, one per consumer, so that each
    /// gets its own callbacks and its own lifetime.
    public func makeClient() -> any WindowLifecycleSource {
        let client = Client(hub: self)
        clients.append(WeakClient(client))
        return client
    }

    /// Whether the underlying source is currently observing. Test-facing.
    public var isObserving: Bool { isObservingBase }

    /// How many vended clients are started right now. Test-facing.
    public var startCount: Int { liveClients().filter(\.isRunning).count }

    // MARK: - Reconciliation

    /// Derived from the live clients rather than counted up and down, so no
    /// running total can drift out of step with who is actually listening: a
    /// released client's weak entry goes nil and *this* pass already sees one
    /// fewer runner.
    ///
    /// Note what that does not buy. Nothing reconciles on release — `Client`
    /// has no `deinit`, and this is reached only from `Client.start()` and
    /// `Client.stop()`. Release the last started client without stopping it
    /// and no further call arrives to notice, so `isObservingBase` stays true
    /// and `base` goes on walking every application with nobody listening.
    /// Every teardown path in `ContextStrategy` calls `stop()` first, which is
    /// what keeps that from happening; a `deinit` hop here would be the fix if
    /// one ever did not.
    fileprivate func reconcile() {
        let wanted = liveClients().contains(where: \.isRunning)
        guard wanted != isObservingBase else { return }
        isObservingBase = wanted
        if wanted { base.start() } else { base.stop() }
    }

    private func liveClients() -> [Client] {
        clients.removeAll { $0.client == nil }
        return clients.compactMap(\.client)
    }

    private func forEachRunningClient(_ body: (Client) -> Void) {
        for client in liveClients() where client.isRunning { body(client) }
    }

    private struct WeakClient {
        weak var client: Client?
        init(_ client: Client) { self.client = client }
    }

    @MainActor
    private final class Client: WindowLifecycleSource {
        private weak var hub: SharedWindowLifecycleSource?
        fileprivate private(set) var isRunning = false

        var onEvent: ((WindowLifecycleKind, AppInfo, UInt32, String) -> Void)?
        var onTitleChange: (() -> Void)?

        init(hub: SharedWindowLifecycleSource) { self.hub = hub }

        /// Idempotent in both directions: a consumer that double-starts, or
        /// stops without having started, cannot move the hub's view of it.
        func start() {
            guard !isRunning else { return }
            isRunning = true
            hub?.reconcile()
        }

        func stop() {
            guard isRunning else { return }
            isRunning = false
            hub?.reconcile()
        }
    }
}
