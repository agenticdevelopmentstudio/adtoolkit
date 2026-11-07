import Foundation
import AgenticDeveloperHubSDKNotifications

/// The single entry point for putting notices on screen.
///
/// The host hands it notices and state changes; it decides what to show and
/// drives the presenters, and talks back through a `NoticeActionHandler`. For
/// each incoming active notice it:
/// 1. drops it if the filter rejects it;
/// 2. replaces in place a shown notice with the same `source` + `key`;
/// 3. holds it while Focus is on and its urgency is below `now`;
/// 4. folds it into a per-source summary while that source is flooding;
/// 5. resolves its style set and hands each style's items to that style's
///    presenter, once per style.
///
/// Every user action removes the card first and tells the host second, so the
/// screen never waits on the host's transport.
@MainActor
public final class NoticePresentationCenter {

    private struct Entry {
        var notice: Notice
        var set: NoticeStyleSet
        /// The styles the set was handed to, in item order, without repeats.
        var styles: [NoticeProfile.Style]
        /// When the card first went on screen; escalation counts from here,
        /// so a backlog notice gets its full threshold once drawn.
        var presentedAt: Date
        var escalated = false
        var isSummary = false
    }

    private let handler: NoticeActionHandler
    private let rules: @MainActor () -> NoticeRoutingRules
    private let filter: @MainActor () -> NoticeFilter
    private let focus: NoticeFocusMonitor
    private let idle: IdleMonitor
    private let clock: () -> Date

    /// The presenters by the style they draw. Internal so tests can register
    /// recording presenters; a host adds others (full screen, crawl, system)
    /// through `setPresenter(_:for:)`, or takes them all from `standard`.
    var presenters: [NoticeProfile.Style: NoticePresenter] = [:]

    /// The calendar snooze times ("tomorrow at 9:00") are computed in.
    public var calendar = Calendar.current

    private var entries: [String: Entry] = [:]
    /// Shown ids in the order they were presented, oldest first.
    private var order: [String] = []
    private var held: [Notice] = []
    private var floodFolder = FloodFolder()
    /// Notices already counted into a flood summary, by id, so a reconcile
    /// does not count them twice or show them after all, and a summary goes
    /// once nothing it folded is still active. The notice is kept so a
    /// partial reconcile can tell whether its list speaks for it.
    private var foldedIDs: [String: Notice] = [:]
    /// Ids whose style set is empty: evaluated once and drawn nowhere.
    /// Remembered so each reconcile does not feed them to the flood folder
    /// again and conjure a summary out of one quiet notice.
    private var evaluatedIDs: Set<String> = []
    /// Ids the user has just acted on. Their card is gone, but until the host
    /// applies the change its active list still has them, and a reconcile in
    /// that gap must not bring the card back.
    private var actedIDs: Set<String> = []
    /// Ids whose card was replaced in place by a newer notice with the same
    /// `source` + `key`. The host follows the new notice with the old one's
    /// `archived` change; that change is for a card already gone and must
    /// not take down the replacement now standing where it was.
    private var replacedIDs: Set<String> = []
    private var escalationTimer: Timer?
    /// Ids snoozed "until I'm back", with when that snooze ends on its own:
    /// woken early, as `unread`, the first time the user returns from being
    /// idle. Kept in `untilBackStore`, when there is one, so a relaunch while
    /// the user is away still wakes them.
    private var untilBack: [String: Date] = [:]
    private let untilBackStore: UserDefaults?
    static let untilBackKey = "NoticePresentationCenter.untilBack"

    public init(
        handler: NoticeActionHandler,
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        filter: @escaping @MainActor () -> NoticeFilter,
        focus: NoticeFocusMonitor = NeverFocused(),
        idle: IdleMonitor = IdleMonitor(),
        untilBackStore: UserDefaults? = nil,
        clock: @escaping () -> Date = Date.init
    ) {
        self.handler = handler
        self.rules = rules
        self.filter = filter
        self.focus = focus
        self.idle = idle
        self.untilBackStore = untilBackStore
        self.clock = clock
        presenters[.toast] = ToastPresenter(
            rules: rules, showHistory: { [weak handler] in handler?.showHistory() })
        presenters[.alert] = AlertPresenter(rules: rules)
        idle.onReturn = { [weak self] in self?.wakeUntilBack() }
        restoreUntilBack()
    }

    isolated deinit {
        escalationTimer?.invalidate()
        idle.stop()
    }

    /// A center with every style the SDK draws: toast and alert, plus crawl,
    /// full screen and the system's own Notification Center. What a host
    /// normally wants; the plain initializer leaves the last three to it.
    public static func standard(
        handler: NoticeActionHandler,
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        filter: @escaping @MainActor () -> NoticeFilter,
        focus: NoticeFocusMonitor = NeverFocused(),
        systemSound: @escaping @MainActor () -> Bool = { true },
        untilBackStore: UserDefaults? = .standard
    ) -> NoticePresentationCenter {
        let center = NoticePresentationCenter(
            handler: handler, rules: rules, filter: filter, focus: focus, untilBackStore: untilBackStore)
        center.setPresenter(CrawlPresenter(rules: rules), for: .crawl)
        center.setPresenter(FullScreenPresenter(rules: rules), for: .fullScreen)
        center.setPresenter(SystemNotificationPresenter(playsSound: systemSound), for: .system)
        return center
    }

    /// Adds or replaces the presenter for a style.
    public func setPresenter(_ presenter: NoticePresenter, for style: NoticeProfile.Style) {
        presenters[style] = presenter
    }

    /// The routing rules changed: lets each presenter restyle or move what it
    /// already has on screen.
    public func rulesDidChange() {
        for presenter in presenters.values {
            presenter.rulesDidChange()
        }
    }

    /// Brings up the host's history (the history hotkey, a menu item).
    public func showHistory() {
        handler.showHistory()
    }

    // MARK: Queries

    /// The most recently presented notice still on screen.
    public var newestShownID: String? { order.last }

    /// The styles a notice is presented in; empty when it is not on screen.
    public func presentedStyles(of id: String) -> Set<NoticeProfile.Style> {
        Set(entries[id]?.styles ?? [])
    }

    // MARK: Input

    public func receive(_ notice: Notice) {
        let now = clock()
        guard notice.state.isActive else { return }
        // Back before the user returned (it was unsnoozed some other way).
        forgetUntilBack(notice.id)
        if let expiresAt = notice.expiresAt, expiresAt <= now { return }
        guard filter().admits(notice) else { return }
        let rules = rules()

        // Already on screen (a re-post, or a reconcile racing a broadcast):
        // refresh it where it stands.
        if let existing = entries[notice.id] {
            replace(oldID: notice.id, existing: existing, with: notice, set: rules.style(for: notice))
            return
        }

        if let key = notice.key,
           let oldID = order.first(where: { id in
               guard let entry = entries[id], !entry.isSummary else { return false }
               return entry.notice.source == notice.source && entry.notice.key == key
           }),
           let existing = entries[oldID] {
            replace(oldID: oldID, existing: existing, with: notice, set: rules.style(for: notice))
            return
        }

        if focus.isFocused, notice.urgency.rank < Notice.Urgency.now.rank {
            held.removeAll { $0.id == notice.id }
            held.append(notice)
            return
        }

        guard foldedIDs[notice.id] == nil, !evaluatedIDs.contains(notice.id) else { return }
        floodFolder.configuration = rules.flood
        if case let .fold(source, count) = floodFolder.admit(notice, at: now) {
            foldedIDs[notice.id] = notice
            showSummary(source: source, count: count, like: notice, now: now)
            return
        }

        present(notice, set: rules.style(for: notice))
    }

    /// A state change the host broadcast. Anything but `unread` takes the
    /// notice off screen; it is not echoed back to the handler.
    public func apply(_ change: NoticeStateChange) {
        guard change.state != .unread else { return }
        if change.state != .snoozed {
            forgetUntilBack(change.id)
        }
        held.removeAll { $0.id == change.id }
        foldedIDs[change.id] = nil
        evaluatedIDs.remove(change.id)
        actedIDs.remove(change.id)
        if replacedIDs.remove(change.id) == nil {
            dismiss(change.id)
        }
        dropSpentSummaries()
    }

    /// Makes the screen match the host's list of active notices: removes every
    /// card not in it and presents any that are missing.
    ///
    /// `covering` says which notices the list speaks for. A host whose list is
    /// only part of what it broadcasts (say, everything above `fyi` from the
    /// last week) passes that test, and a card outside it stays where it is
    /// rather than being taken down for not being listed. The default covers
    /// every notice: the list is the whole truth.
    public func reconcile(active: [Notice], covering: (Notice) -> Bool = { _ in true }) {
        let activeIDs = Set(active.map(\.id))
        func stale(_ notice: Notice) -> Bool { covering(notice) && !activeIDs.contains(notice.id) }
        for id in order {
            guard let entry = entries[id], !entry.isSummary, stale(entry.notice) else { continue }
            dismiss(id)
        }
        held.removeAll(where: stale)
        foldedIDs = foldedIDs.filter { !stale($0.value) }
        evaluatedIDs.formIntersection(activeIDs)
        actedIDs.formIntersection(activeIDs)
        // A replaced notice is archived, so never in the list; a change for
        // it still in flight would only tell presenters to drop a card they
        // no longer have.
        replacedIDs.formIntersection(activeIDs)
        dropSpentSummaries()
        let heldIDs = Set(held.map(\.id))
        for notice in active.sorted(by: { $0.timestamp < $1.timestamp })
        where entries[notice.id] == nil && !heldIDs.contains(notice.id) && !actedIDs.contains(notice.id) {
            receive(notice)
        }
    }

    /// Re-checks escalation now. The timer calls this; tests call it directly.
    public func tick() {
        let now = clock()
        let rules = rules()
        for id in order {
            guard let entry = entries[id], !entry.escalated, !entry.isSummary,
                  let urgency = rules.escalation.escalated(entry.notice, since: entry.presentedAt, now: now)
            else { continue }
            var shown = entry.notice
            shown.urgency = urgency
            let set = rules.style(for: entry.notice, effectiveUrgency: urgency)
            let styles = hand(shown, set: set, replacing: id, from: entry.styles)
            guard !styles.isEmpty else {
                // Escalated into a set that shows nothing: drawn nowhere now.
                entries[id] = nil
                order.removeAll { $0 == id }
                evaluatedIDs.insert(id)
                continue
            }
            var escalated = entry
            escalated.set = set
            escalated.styles = styles
            escalated.escalated = true
            entries[id] = escalated
        }
        rearmEscalation()
    }

    /// Call when the Focus monitor's answer may have changed. Releases what
    /// was held once Focus is off.
    public func focusDidChange() {
        guard !focus.isFocused else { return }
        let released = held
        held = []
        for notice in released {
            receive(notice)
        }
    }

    // MARK: User actions

    /// The card was clicked: run the primary action.
    public func act(id: String) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
            handler.showHistory()
            return
        }
        guard let action = entry.notice.primaryAction else {
            userDismiss(id)
            handler.setState(id, .read)
            return
        }
        if case .reply = action.kind {
            // The first style that draws a field takes it. Crawl and system
            // draw none: with only those, the history is where it can be
            // answered.
            if !entry.styles.contains(where: { presenters[$0]?.focusReply(id: id) == true }) {
                handler.showHistory()
            }
            return
        }
        userDismiss(id)
        perform(action, of: id, text: nil)
    }

    /// One action button, with reply text for a reply action.
    public func respond(id: String, actionID: String, text: String?) {
        guard let entry = entries[id], !entry.isSummary,
              let action = entry.notice.actions.first(where: { $0.id == actionID }) else { return }
        userDismiss(id)
        perform(action, of: id, text: text)
    }

    /// The host refused a change the user made on a card: the notice was
    /// already finished, the id was unknown, or the host was unreachable.
    /// The id stops being suppressed, and a pending "until I'm back" wake is
    /// dropped, so the next `reconcile(active:)` shows whatever the host still
    /// calls active instead of hiding it until the host's list changes.
    public func actionNotApplied(id: String) {
        actedIDs.remove(id)
        forgetUntilBack(id)
    }

    public func archive(id: String) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
        } else {
            userDismiss(id)
            handler.setState(id, .archived)
        }
    }

    /// The snooze times the notice's set offers; empty for an unknown notice,
    /// a summary, or a set that is not snoozable. What a shortcut consults to
    /// pick a time.
    public func snoozeOptions(of id: String) -> [SnoozeOption] {
        guard let entry = entries[id], !entry.isSummary, entry.set.snooze.isSnoozable else { return [] }
        return entry.set.snooze.options
    }

    public func snooze(id: String, option: SnoozeOption) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
        } else {
            // A set that turned snoozing off offers no control; a stray call
            // (a shortcut, a stale card) changes nothing.
            guard entry.set.snooze.isSnoozable else { return }
            userDismiss(id)
            let until = option.until(now: clock(), calendar: calendar)
            handler.snooze(id, until: until)
            if option == .untilBack {
                untilBack[id] = until
                saveUntilBack()
                idle.start()
            }
        }
    }

    // MARK: Until I'm back

    /// Whether any notice is waiting for the user to come back.
    var hasUntilBackNotices: Bool { !untilBack.isEmpty }

    private func wakeUntilBack() {
        let now = clock()
        let woken = untilBack.filter { $0.value > now }.keys.sorted()
        untilBack = [:]
        saveUntilBack()
        idle.stop()
        for id in woken {
            handler.setState(id, .unread)
        }
    }

    private func forgetUntilBack(_ id: String) {
        guard untilBack.removeValue(forKey: id) != nil else { return }
        saveUntilBack()
        if untilBack.isEmpty {
            idle.stop()
        }
    }

    /// Picks up what a previous launch left, minus snoozes that have since
    /// run out on their own, and watches for the user's return again.
    private func restoreUntilBack() {
        guard let stored = untilBackStore?.dictionary(forKey: Self.untilBackKey) as? [String: Double] else { return }
        let now = clock()
        untilBack = stored.mapValues(Date.init(timeIntervalSince1970:)).filter { $0.value > now }
        if untilBack.count != stored.count {
            saveUntilBack()
        }
        if !untilBack.isEmpty {
            idle.start()
        }
    }

    private func saveUntilBack() {
        guard let untilBackStore else { return }
        if untilBack.isEmpty {
            untilBackStore.removeObject(forKey: Self.untilBackKey)
        } else {
            untilBackStore.set(untilBack.mapValues(\.timeIntervalSince1970), forKey: Self.untilBackKey)
        }
    }

    /// The close button or an auto-dismiss expiry: off screen, marked `read`.
    public func close(id: String) {
        guard let entry = entries[id] else { return }
        if entry.isSummary {
            dismiss(id)
        } else {
            userDismiss(id)
            handler.setState(id, .read)
        }
    }

    // MARK: Presenting

    private func present(_ notice: Notice, set: NoticeStyleSet) {
        let styles = hand(notice, set: set, replacing: nil, from: [])
        guard !styles.isEmpty else {
            evaluatedIDs.insert(notice.id)
            return
        }
        entries[notice.id] = Entry(notice: notice, set: set, styles: styles, presentedAt: clock())
        order.append(notice.id)
        rearmEscalation()
    }

    private func replace(oldID: String, existing: Entry, with notice: Notice, set: NoticeStyleSet) {
        entries[oldID] = nil
        order.removeAll { $0 == oldID }
        if oldID != notice.id {
            replacedIDs.insert(oldID)
        }
        let styles = hand(notice, set: set, replacing: oldID, from: existing.styles)
        if styles.isEmpty {
            evaluatedIDs.insert(notice.id)
        } else {
            // The slot's `presentedAt` carries over, but the escalation clock
            // runs from `max(timestamp, presentedAt)`, the later of the two. A
            // key replacement carries a newer timestamp, so it restarts the
            // clock from the replacement's timestamp; a refresh with an
            // unchanged timestamp keeps the clock running from when the slot
            // was filled.
            entries[notice.id] = Entry(notice: notice, set: set, styles: styles, presentedAt: existing.presentedAt)
            order.append(notice.id)
        }
        rearmEscalation()
    }

    /// Puts `notice` up in every style of `set`, one presenter call per style.
    /// With `oldID`, it takes over that notice's presentation: a style in both
    /// `previous` and the set is replaced in place, one only in `previous` is
    /// removed, and one only in the set is shown. Returns the styles used.
    private func hand(
        _ notice: Notice, set: NoticeStyleSet, replacing oldID: String?, from previous: [NoticeProfile.Style]
    ) -> [NoticeProfile.Style] {
        let groups = Self.groups(set)
        let styles = groups.map(\.style)
        if let oldID {
            for style in previous where !styles.contains(style) {
                presenters[style]?.remove(id: oldID)
            }
        }
        let actions = cardActions(for: notice.id, set: set)
        for group in groups {
            if let oldID, previous.contains(group.style) {
                presenters[group.style]?.replace(oldID: oldID, with: notice, profiles: group.items, actions: actions)
            } else {
                presenters[group.style]?.show(notice, profiles: group.items, actions: actions)
            }
        }
        return styles
    }

    /// The set's items by style, in the order each style first appears, each
    /// stamped with the set's dismiss.
    private static func groups(
        _ set: NoticeStyleSet
    ) -> [(style: NoticeProfile.Style, items: [NoticeProfile])] {
        var groups: [(style: NoticeProfile.Style, items: [NoticeProfile])] = []
        for item in set.presentedItems {
            if let index = groups.firstIndex(where: { $0.style == item.style }) {
                groups[index].items.append(item)
            } else {
                groups.append((item.style, [item]))
            }
        }
        return groups
    }

    /// A flood summary is one toast, bottom right, that never times out and
    /// cannot be snoozed, whatever the folded notices' own set says.
    private static let summarySet = NoticeStyleSet(
        items: [NoticeProfile(style: .toast, position: .bottomRight)],
        snooze: SnoozeSettings(isEnabled: false, options: []))

    private func showSummary(source: String, count: Int, like notice: Notice, now: Date) {
        let id = "flood:\(source)"
        let summary = Notice(
            id: id, timestamp: now, source: source, title: "\(count) from \(source)",
            body: "Click to see them in history.", app: notice.app, level: .info, urgency: .fyi)
        let set = Self.summarySet
        let actions = cardActions(for: id, set: set, summary: true)
        let wasShown = entries[id] != nil
        entries[id] = Entry(notice: summary, set: set, styles: [.toast], presentedAt: now, isSummary: true)
        order.removeAll { $0 == id }
        order.append(id)
        if wasShown {
            presenters[.toast]?.replace(oldID: id, with: summary, profiles: set.presentedItems, actions: actions)
        } else {
            presenters[.toast]?.show(summary, profiles: set.presentedItems, actions: actions)
        }
    }

    /// Off screen everywhere. Every presenter is told, tracked or not, because
    /// a notice's set may span several, and a presenter may hold a card this
    /// center has already forgotten.
    private func dismiss(_ id: String) {
        entries[id] = nil
        order.removeAll { $0 == id }
        var seen: Set<ObjectIdentifier> = []
        for presenter in presenters.values where seen.insert(ObjectIdentifier(presenter)).inserted {
            presenter.remove(id: id)
        }
        rearmEscalation()
    }

    /// Off screen because the user acted, so a reconcile racing the host's
    /// broadcast leaves it off.
    private func userDismiss(_ id: String) {
        actedIDs.insert(id)
        dismiss(id)
    }

    /// A flood summary goes once nothing it folded is still active.
    private func dropSpentSummaries() {
        let folding = Set(foldedIDs.values.map(\.source))
        for id in order {
            guard let entry = entries[id], entry.isSummary, !folding.contains(entry.notice.source) else { continue }
            dismiss(id)
        }
    }

    private func perform(_ action: Notice.Action, of id: String, text: String?) {
        if case let .open(url) = action.kind {
            handler.openURL(url)
        }
        handler.respond(id, actionID: action.id, text: text)
    }

    private func cardActions(for id: String, set: NoticeStyleSet, summary: Bool = false) -> NoticeCardActions {
        var snooze: (@MainActor (SnoozeOption) -> Void)?
        var archive: (@MainActor () -> Void)?
        if !summary {
            if set.snooze.isSnoozable {
                snooze = { [weak self] option in self?.snooze(id: id, option: option) }
            }
            archive = { [weak self] in self?.archive(id: id) }
        }
        return NoticeCardActions(
            act: { [weak self] in self?.act(id: id) },
            respond: { [weak self] actionID, text in self?.respond(id: id, actionID: actionID, text: text) },
            snooze: snooze,
            snoozeOptions: set.snooze.options,
            archive: archive,
            close: { [weak self] in self?.close(id: id) })
    }

    // MARK: Escalation timer

    private func rearmEscalation() {
        escalationTimer?.invalidate()
        escalationTimer = nil
        let policy = rules().escalation
        let next = entries.values
            .filter { !$0.escalated && !$0.isSummary }
            .compactMap { policy.nextCheck(for: $0.notice, since: $0.presentedAt) }
            .min()
        guard let next else { return }
        let interval = max(0.5, next.timeIntervalSince(clock()))
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        escalationTimer = timer
    }
}
