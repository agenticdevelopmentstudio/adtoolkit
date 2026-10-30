import AppKit
import Combine
import os
import AgenticToolkitCore

/// Keeps one window per project, keyed by `git_repo.id`.
///
/// The key is the row id and not the path, so opening "the same project" twice
/// means the same window even after the repository has been moved or renamed —
/// which is the whole reason the registry has ids in the first place.
@MainActor
public final class ProjectWindowManager: ProjectOpening, ObservableObject {

    public static let shared = ProjectWindowManager()

    /// `project_setting` key marking a project whose window was open when the
    /// app last quit. It lives with the project row rather than in app
    /// preferences so it cascades away with the project — a forgotten registry
    /// row can't leave a "reopen me" behind pointing at nothing.
    ///
    /// Internal rather than private so a test asserting what a close does *not*
    /// write names the same key the writer does, instead of a literal that can
    /// drift away from it silently.
    static let openWindowKey = "window.open"

    private var controllers: [UUID: ComposableTabsWindowController] = [:]

    /// Language-service shutdowns started by a window close, still running.
    /// The controller is out of `controllers` by then, so
    /// `shutdownAllLanguageServices()` cannot find it there; this is the
    /// handle that lets the quit path wait for it anyway. See
    /// `PendingTeardowns`.
    private let closeTeardowns = PendingTeardowns()

    /// The order projects were opened in.
    ///
    /// `controllers` is a `Dictionary`, whose value order is seeded per
    /// process; scripting enumerates windows, tabs and panes through this, and
    /// a script that lists `panes` twice must get the same order twice.
    private var openOrder: [UUID] = []

    /// Which projects have a window open right now, so anything outside a
    /// project window can follow projects opening and closing — the language
    /// server settings panel lists one section per open project, and a
    /// language server exists only inside one.
    ///
    /// Ids rather than workspaces. `openWorkspaces` is still the accessor for
    /// the values, and it reads them out of the controllers; publishing the
    /// workspaces instead would put a `@Published` array of them beside the
    /// controllers that own them, and a subscriber holding the last emission
    /// would then keep a closed project's workspace — and the language servers
    /// hanging off it — alive past its window.
    ///
    /// Derived from `openOrder` and `controllers` at every mutation rather
    /// than maintained alongside them, so the three cannot drift — and in
    /// `openOrder`'s order, because a subscriber that renders one section per
    /// open project must not have them rearrange themselves on the next
    /// unrelated open or close. `closeProject` is not one of
    /// those sites: it only asks the window to close, and the removal happens
    /// in the `willCloseNotification` observer below, which is also the path a
    /// user clicking the red button takes.
    @Published public private(set) var openWorkspaceIDs: [UUID] = []
    private var closeObservers: [UUID: NSObjectProtocol] = [:]

    /// The projects registered by `adoptForScripting(_:)` rather than opened
    /// here. Membership is what `forgetForScripting(_:)` checks, because the
    /// two registrations are not interchangeable: an adopted window's observer
    /// only unregisters it, while an opened window's observer also clears the
    /// persisted "reopen me" flag. Tearing the second one down through the
    /// undo of the first would leave the project reopening for ever.
    private var adoptedForScripting: Set<UUID> = []
    private weak var coordinator: ProjectsCoordinator?

    /// A database handed over by `attach(database:)`, for a host with no
    /// project registry. Strong where `coordinator` is weak: nothing else in
    /// such a host owns it on this manager's behalf.
    private var attachedDatabase: ProjectDatabase?

    /// Where windows persist their tabs and open state — the registry's
    /// database when there is one, the attached one otherwise.
    private var database: ProjectDatabase? {
        attachedDatabase ?? coordinator?.database
    }

    /// One `ProjectController` per open window, keyed the same way
    /// `controllers` is. Built in `openProject(_:)`, dropped in
    /// `observeClose(of:repoID:recordsOpenState:)`.
    private var projectControllers: [UUID: ProjectController] = [:]

    /// `NSWindow.didBecomeKeyNotification` observers installed by
    /// `observeBecameKey(of:repoID:)`, one per open window, so a worktree
    /// added or removed in a terminal shows up without a relaunch.
    private var keyObservers: [UUID: NSObjectProtocol] = [:]

    /// Injected so tests run against a throwaway client and hosts can share
    /// one rather than each `ProjectController` reaching for `GitClient.shared`
    /// on its own (`dependency-injection`).
    public var gitClient: GitClient = .shared

    /// Where each project's branch commands are registered. `nil` registers
    /// nothing — the configuration every test that does not ask for commands
    /// already runs in.
    public var commandRegistry: CommandRegistry?

    /// Builds the language-server stack for a project about to be opened, given
    /// its directory. Set once by the host at startup; `nil` in a host that
    /// wants no language support, and in every test that has not asked for it.
    ///
    /// A closure rather than a stored `TextDocumentStore` + settings pair
    /// because this type has no business knowing what a registry needs — the
    /// host already owns the app-wide document store and the settings, and this
    /// only has to know *when* to ask (`dependency-injection`).
    public var languageServicesFactory: (@MainActor (URL) -> ProjectLanguageServices)?

    /// Fires once, synchronously, from the same `willClose` handler that tears
    /// down a project's language services — a host that keys its own state off
    /// a `ProjectWorkspace` (the app's `DocumentSession`, one per project
    /// window) needs exactly this moment to discard it, and this type is the
    /// only one that knows a window's project is going away rather than
    /// merely losing focus.
    public var onProjectClosed: (@MainActor (ProjectWorkspace) -> Void)?

    /// Fires whenever the set of open project windows changes — one opened,
    /// one closed, one adopted for scripting, one forgotten.
    ///
    /// `onProjectClosed` above answers "*this* project is going away" and is
    /// the wrong shape for a reader that wants the new set: it never fires on
    /// an open, and it fires before the controller leaves `controllers`.
    ///
    /// A closure rather than a subscription to `$openWorkspaceIDs`, for a
    /// reason `@Published` makes easy to get wrong: it publishes from
    /// `willSet`, so a sink that reads `openWorkspaces` or
    /// `openWindowControllers` in response sees the set as it was *before* the
    /// change. This fires from `refreshOpenWorkspaceIDs()` after the
    /// assignment, so every accessor on this type already agrees with it.
    /// (`makeLanguageServerPanel` in the app takes the other route
    /// deliberately, mapping the ids the publisher hands it rather than
    /// reading back.)
    public var onOpenProjectsChanged: (@MainActor () -> Void)?

    /// How this manager brings the app forward when a project window opens.
    ///
    /// A seam, not a setting: `activateUnlessQuiet()` already declines under
    /// XCTest, so the *suppressed* branch is the only one a test could observe
    /// by watching `NSApp` — and the claim worth pinning is the other one.
    /// Injecting the call lets a test assert that opening a project asks for
    /// the foreground at all, which is the behaviour that was missing.
    var activateApp: () -> Void = { NSApp.activateUnlessQuiet() }

    public init() {}

    /// Wires the manager to the registry it opens projects from and registers
    /// itself as that registry's opener.
    public func attach(to coordinator: ProjectsCoordinator) {
        self.coordinator = coordinator
        coordinator.setOpener(self)
    }

    /// Wires the manager to a database alone, for a host that opens a fixed
    /// workspace rather than choosing among scanned projects — a terminal-only
    /// app has no registry, browser or scan, but its window still needs
    /// somewhere to keep its tabs.
    public func attach(database: ProjectDatabase) {
        attachedDatabase = database
    }

    /// The frontmost project window, for anything that acts on "the current
    /// project" — menu validation, the scripting bridge, and the
    /// `workspaceRoots` seam the extension hosts read.
    ///
    /// **AppKit answers first, this manager's own ordering answers last.**
    /// The two `NSApp` reads are the accurate ones while the app is active and
    /// a project window is genuinely key, and they stay first for that reason.
    /// But neither is answerable at every moment this property is asked, and
    /// the gap is not hypothetical:
    ///
    /// - This is a menubar host that opens project windows under *quiet*
    ///   presentation (see `activateApp` below, declined by
    ///   `activateUnlessQuiet()`). With the app not active, `NSApp.keyWindow`
    ///   is `nil` — there is no key window anywhere in a background app.
    /// - `orderedWindows` reflects the window server's ordering, which is
    ///   settled by `orderFront`, not by this manager's bookkeeping.
    ///
    /// So before `openProject(_:)` has actually put the window on screen,
    /// *both* reads answer for the previous front window, or for nothing at
    /// all when this is the first project of the session. That is what made
    /// `onOpenProjectsChanged` a lie for its most important consumer: the
    /// extension hosts' `workspaceRoots` closure read this property, got `nil`,
    /// and `ExtensionsCoordinator.projectWindowsDidChange()` took its
    /// `guard !roots.isEmpty else { return }` early exit — with no retry, so
    /// every `workspaceContains:` extension stayed dormant for the entire
    /// process lifetime.
    ///
    /// The final fallback closes that gap for good. `openOrder.last` is the
    /// most recently opened project still in `controllers`, which is precisely
    /// what this type means by "front" when the window server has not yet
    /// been asked — and it is the same pair (`openOrder` + `controllers`) that
    /// `refreshOpenWorkspaceIDs()` republishes, so this property now agrees
    /// with `openWorkspaces` and `openWindowControllers` at the instant
    /// `onOpenProjectsChanged` fires, which is what that callback's own doc
    /// already promises. Ordering the window on screen is still done first
    /// (see `openProject(_:)`), so the fallback is a floor rather than the
    /// normal path.
    public var frontWindowController: ComposableTabsWindowController? {
        if let key = NSApp.keyWindow?.windowController as? ComposableTabsWindowController {
            return key
        }
        // Visible only: a project window group keeps its other active
        // projects' windows loaded and ordered out.
        if let ordered = NSApp.orderedWindows
            .filter(\.isVisible)
            .compactMap({ $0.windowController as? ComposableTabsWindowController })
            .first {
            return ordered
        }
        return openOrder.last.flatMap { controllers[$0] }
    }

    /// Every open project's workspace, in the order their projects were
    /// opened — the same order as `openWindowControllers` below, and read out
    /// of the same two sources.
    public var openWorkspaces: [ProjectWorkspace] {
        openOrder.compactMap { controllers[$0]?.project }
    }

    /// Every open project window, in the order their projects were opened.
    public var openWindowControllers: [ComposableTabsWindowController] {
        openOrder.compactMap { controllers[$0] }
    }

    /// Republishes `openWorkspaceIDs` from the one ordering this type keeps.
    ///
    /// Every site that adds to or removes from `controllers` calls this, so
    /// the published ids, `openWorkspaces` and `openWindowControllers` are
    /// three views of the same pair — `openOrder` for the order, `controllers`
    /// for membership — and cannot disagree about either. Filtering through
    /// `controllers` rather than publishing `openOrder` itself keeps the
    /// membership answer in the dictionary alone: an id that outlives its
    /// controller is not open.
    private func refreshOpenWorkspaceIDs() {
        openWorkspaceIDs = openOrder.filter { controllers[$0] != nil }
        onOpenProjectsChanged?()
    }

    /// Registers a window this manager did not open, so scripting can see it.
    /// Idempotent — adopting twice leaves one entry.
    ///
    /// For a host that builds a project window itself, and for the tests: the
    /// scripting surface is "which project windows are open", and a window this
    /// manager never opened is still open (`principle-of-least-astonishment`).
    ///
    /// Adoption undoes itself when the window closes, so a host that adopts and
    /// then forgets to unregister still cannot leave `openWindowControllers`
    /// naming a window that is gone — or leave `openProject(_:)` re-showing a
    /// dead controller. `forgetForScripting(_:)` is for undoing it *sooner*
    /// than that, not for making the close safe.
    ///
    /// It deliberately does not touch the persisted open flag, in either
    /// direction: that flag drives `restoreOpenProjects()`, and a window this
    /// manager never opened is not one it may decide should not reopen.
    public func adoptForScripting(_ controller: ComposableTabsWindowController) {
        let id = controller.project.id
        guard controllers[id] == nil else { return }
        controllers[id] = controller
        openOrder.append(id)
        refreshOpenWorkspaceIDs()
        adoptedForScripting.insert(id)
        observeClose(of: controller, repoID: id, recordsOpenState: false)
    }

    /// The undo of `adoptForScripting(_:)`, and only of that. Guarded on
    /// identity, so forgetting a stale controller cannot evict the live window
    /// that replaced it, and guarded on *how* the controller was registered,
    /// so it cannot undo an `openProject(_:)`: that registration owns the
    /// observer which clears the persisted open flag on close, and removing it
    /// would leave the project marked open for ever and reopening at every
    /// launch. A controller this manager opened is silently left alone —
    /// there is nothing here for the caller to undo.
    ///
    /// It takes the adoption's close observer with it, so the eager undo leaks
    /// no more than the automatic one does.
    public func forgetForScripting(_ controller: ComposableTabsWindowController) {
        let id = controller.project.id
        guard controllers[id] === controller, adoptedForScripting.contains(id) else { return }
        controllers.removeValue(forKey: id)
        openOrder.removeAll { $0 == id }
        refreshOpenWorkspaceIDs()
        adoptedForScripting.remove(id)
        if let observer = closeObservers.removeValue(forKey: id) {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public func windowController(for repoID: UUID) -> ComposableTabsWindowController? {
        controllers[repoID]
    }

    /// The project controller behind a window this manager opened. `nil` for
    /// a repo with no window, and for a window `adoptForScripting(_:)` merely
    /// registered — those are built and owned by whoever adopted them.
    public func projectController(for repoID: UUID) -> ProjectController? {
        projectControllers[repoID]
    }

    /// Whether a `NSWindow.didBecomeKeyNotification` observer is still
    /// registered for `repoID`. Internal, not `public`, and reached only
    /// through `@testable import` — the sole consumer is a test proving that
    /// closing a window's observer is actually gone, not merely unreachable
    /// because `projectControllers[repoID]` already went with it.
    func hasKeyObserver(for repoID: UUID) -> Bool {
        keyObservers[repoID] != nil
    }

    // MARK: - ProjectOpening

    /// Opens `repo` in a project window.
    ///
    /// A project already active in a window is put on screen in that window.
    /// Anything else becomes an active project of the frontmost window — or of
    /// a new one, when there is no project window at all.
    public func openProject(_ repo: GitRepo) {
        if let group = group(containing: repo.id), let existing = controllers[repo.id] {
            existing.project.update(repo: repo)
            present(repo.id, in: group)
            // Asking for a project that is already open is still the user
            // asking for it, and a window raised behind the app that is
            // actually frontmost reads as nothing having happened.
            activateApp()
            return
        }
        if let existing = controllers[repo.id] {
            // A window adopted for scripting belongs to no group; raise it
            // the way this manager always has.
            existing.project.update(repo: repo)
            existing.showWindow(nil)
            existing.window?.makeKeyAndOrderFront(nil)
            activateApp()
            return
        }
        load(repo, into: frontGroup ?? makeGroup())
    }

    /// Loads `repo` into `group`'s window — what choosing a project in a
    /// window's Project Browser does. The project joins the window's active
    /// projects and goes on screen; one already active in another window is
    /// put on screen there instead, since one project has one set of panes.
    public func loadProject(_ repo: GitRepo, into group: ProjectWindowGroup) {
        coordinator?.recordOpened(repo)
        if group.contains(repo.id) {
            present(repo.id, in: group)
            return
        }
        if controllers[repo.id] != nil {
            openProject(repo)
            return
        }
        load(repo, into: group)
    }

    /// Opens a project window with no project in it, its shelf out on the
    /// Project Browser with the keyboard in the filter — File ▸ New Project
    /// Window.
    public func openNewWindow() {
        let template = frontGroup.flatMap { shownWindows[$0.id]?.window }
        let group = makeGroup()
        guard let empty = showEmptyWindow(for: group) else {
            removeGroup(group)
            return
        }
        // Sized like the window in front and cascaded off it, as New is in a
        // document app — a project chosen here inherits this frame, so the
        // 800×500 default would shrink every project opened from a new window
        // (`principle-of-least-astonishment`).
        if let template, let window = empty.window {
            // Offset by hand: `cascadeTopLeft(from:)` moves the window it is
            // sent to, which here would be the template.
            window.setFrame(template.frame.offsetBy(dx: 22, dy: -22), display: false)
        }
        empty.showShelfForChoosing()
        persistGroups()
        activateApp()
    }

    public func closeProject(repoID: UUID) {
        if let group = group(containing: repoID) {
            // The scan closes a deleted project and deletes its row in the same
            // turn, so the window has to be gone by the time this returns.
            closeActiveProject(repoID, in: group, synchronously: true)
        } else {
            controllers[repoID]?.close()
        }
    }

    // MARK: - Window groups

    /// The project windows, as the user sees them: each one a list of active
    /// projects with one of them on screen. See `ProjectWindowGroup`.
    public private(set) var groups: [ProjectWindowGroup] = []

    /// Which window each group has on screen: the shown project's, or its
    /// empty window.
    private var shownWindows: [UUID: NSWindowController & ProjectShelfWindow] = [:]
    private var emptyWindows: [UUID: EmptyProjectWindowController] = [:]
    private var emptyCloseObservers: [UUID: NSObjectProtocol] = [:]
    private var groupObservers: [UUID: AnyCancellable] = [:]

    /// Set while `restoreOpenProjects()` rebuilds the groups, so their
    /// half-built state is not written back over the state being read.
    private var isRestoring = false

    /// The group whose window is frontmost, or failing that the last made.
    private var frontGroup: ProjectWindowGroup? {
        let windows = [NSApp.keyWindow].compactMap { $0 } + NSApp.orderedWindows.filter(\.isVisible)
        for window in windows {
            if let group = groups.first(where: { shownWindows[$0.id]?.window === window }) {
                return group
            }
        }
        return groups.last
    }

    /// The window group `repoID` is an active project of.
    public func group(containing repoID: UUID) -> ProjectWindowGroup? {
        groups.first { $0.contains(repoID) }
    }

    @discardableResult
    private func makeGroup(state: ProjectWindowState = ProjectWindowState()) -> ProjectWindowGroup {
        let group = ProjectWindowGroup(state: state)
        groups.append(group)
        // The panel is the one piece of shelf state that changes without
        // passing through this manager; the active list and the selection are
        // written where they change.
        groupObservers[group.id] = group.$panel
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.persistGroups() }
        return group
    }

    private func removeGroup(_ group: ProjectWindowGroup) {
        groups.removeAll { $0 === group }
        groupObservers.removeValue(forKey: group.id)
        shownWindows.removeValue(forKey: group.id)
    }

    /// A shelf for one of `group`'s windows, wired to this manager. `nil` in
    /// a host with no registry, which has no projects to browse.
    private func makeShelf(for group: ProjectWindowGroup) -> ProjectShelfViewController? {
        guard let coordinator else { return nil }
        let shelf = ProjectShelfViewController(coordinator: coordinator, group: group)
        shelf.onLoadProject = { [weak self, weak group] repo in
            guard let self, let group else { return }
            self.loadProject(repo, into: group)
        }
        shelf.onShowActiveProject = { [weak self, weak group] repoID in
            guard let self, let group else { return }
            self.present(repoID, in: group)
        }
        shelf.onCloseActiveProject = { [weak self, weak group] repoID in
            guard let self, let group else { return }
            self.closeActiveProject(repoID, in: group, synchronously: false)
        }
        return shelf
    }

    /// Builds `repo`'s window hidden, makes it one of `group`'s active
    /// projects and puts it on screen.
    private func load(_ repo: GitRepo, into group: ProjectWindowGroup) {
        guard makeProjectWindow(repo, in: group) != nil else { return }
        group.activate(repo.id)
        present(repo.id, in: group)
        activateApp()
        // After the window is on screen and the app offered activation, not
        // at registration: every consumer of `onOpenProjectsChanged` asks a
        // question about the window that just opened, and two of them read
        // AppKit through `frontWindowController` — firing earlier published
        // "the open set changed" while `NSApp` still described the previous
        // window, and the extension hosts' `workspaceContains:` check ran
        // against the old project's roots and never ran again.
        refreshOpenWorkspaceIDs()
    }

    /// Puts `repoID`'s window on screen in place of whatever `group` shows.
    private func present(_ repoID: UUID, in group: ProjectWindowGroup) {
        guard let incoming = controllers[repoID] else { return }
        group.select(repoID)
        persistGroups()
        swap(to: incoming, in: group)
    }

    /// The swap that makes a group read as one window: the incoming window
    /// takes the outgoing one's frame, shelf and keyboard focus, is ordered
    /// in, and the outgoing one is ordered out — nothing is built or torn
    /// down, so every session in the outgoing project keeps running.
    private func swap(to incoming: NSWindowController & ProjectShelfWindow, in group: ProjectWindowGroup) {
        let outgoing = shownWindows[group.id]
        guard outgoing !== incoming else {
            incoming.showWindow(nil)
            incoming.window?.makeKeyAndOrderFront(nil)
            return
        }
        let focus = outgoing?.projectShelf?.focus ?? .elsewhere
        if incoming.window == nil { incoming.loadWindow() }
        let outgoingFrame = outgoing?.window?.frame
        if let outgoing {
            incoming.adoptShelfLayout(outgoing.shelfLayout)
        }
        incoming.window?.isExcludedFromWindowsMenu = false
        // Two windows standing in for one: neither may play AppKit's order-in
        // or order-out animation, which scales a document window down and
        // back up — the whole window seemed to bounce on every project swap.
        incoming.window?.animationBehavior = .none
        outgoing?.window?.animationBehavior = .none
        // Before showing as well as after: a window ordered in at its own
        // stale frame and then resized is the same bounce by another route.
        if let outgoingFrame {
            incoming.window?.setFrame(outgoingFrame, display: false)
        }
        incoming.showWindow(nil)
        // After `showWindow` too: showing restores the window's own saved
        // frame, which would undo the hand-off and make the group jump.
        if let outgoingFrame, incoming.window?.frame != outgoingFrame {
            incoming.window?.setFrame(outgoingFrame, display: true)
        }
        incoming.window?.makeKeyAndOrderFront(nil)
        shownWindows[group.id] = incoming
        if let outgoing {
            outgoing.window?.isExcludedFromWindowsMenu = true
            outgoing.window?.orderOut(nil)
            if let empty = outgoing as? EmptyProjectWindowController {
                discardEmptyWindow(empty, of: group)
            }
        }
        incoming.projectShelf?.restore(focus: focus)
    }

    /// Builds `repo`'s window without showing it.
    @discardableResult
    private func makeProjectWindow(_ repo: GitRepo, in group: ProjectWindowGroup) -> ComposableTabsWindowController? {
        guard let database else {
            Self.logger.error("Cannot open \(repo.name, privacy: .public): no project database attached")
            return nil
        }
        let languageServices = languageServicesFactory?(repo.url)
        if languageServices == nil {
            // Info, not a warning: a host with no language-server wiring is a
            // supported configuration, and this is the one line that tells a
            // reader of the log why a window has no completions.
            Self.logger.info(
                "No language services for \(repo.name, privacy: .public): no factory wired"
            )
        }
        let workspace = ProjectWorkspace(
            repo: repo,
            database: database,
            languageServices: languageServices,
            gitClient: gitClient,
            arrangementSourceID: UUID(uuidString: UserSettings.lastActiveProjectWindow.currentValue)
        )
        languageServices?.start()
        let projectController = ProjectController(
            workspace: workspace,
            commandRegistry: commandRegistry
        )
        projectControllers[repo.id] = projectController
        // The data source is passed to the initializer, not assigned after it:
        // the window installs its stored tabs while initializing, and a tab
        // whose item is built before the data source arrives falls back to a
        // plain title, leaving a pane-less tab until something else reloads.
        let controller = ComposableTabsWindowController(
            project: workspace,
            tabItemDataSource: projectController,
            shelf: makeShelf(for: group)
        )
        // Ruling Q: `projectController` is captured weakly here and the window
        // reloads only while this controller is still the one registered for
        // `repo.id`, so a controller that was closed and replaced — or one
        // whose window is already gone — can never drive a window that is no
        // longer its own.
        projectController.onTabsDidChange = { [weak self, weak controller, weak projectController] in
            guard let self, let projectController,
                  self.projectControllers[repo.id] === projectController else { return }
            controller?.reloadTabs()
        }
        // The window's debounced focus-persist writes the same rows a reconcile
        // is about to write. Cancelling it here, in the same turn as the write,
        // is what stops a pending item from landing afterwards with the tab set
        // the reconcile just replaced.
        projectController.onWillChangeTabs = { [weak controller] in
            controller?.cancelPendingTabPersist()
        }
        // The other half of the reconcile's two outcomes. Nothing was written,
        // so the panes stand; but the window built its tab buttons before this
        // controller had any checkouts to answer with, and now it has them.
        // Guarded the same way as `onTabsDidChange`, for the same reason.
        projectController.onTabItemsNeedRefresh = { [weak self, weak controller, weak projectController] in
            guard let self, let projectController,
                  self.projectControllers[repo.id] === projectController else { return }
            controller?.refreshTabItems()
        }
        controllers[repo.id] = controller
        openOrder.append(repo.id)
        // Loaded but not shown: an active project that is not on screen keeps
        // its window, its panes and its sessions, so switching to it is an
        // order-in rather than a build. Out of the Window menu until it is the
        // one on screen — there, the group is one window.
        controller.loadWindow()
        controller.window?.isExcludedFromWindowsMenu = true
        observeClose(of: controller, repoID: repo.id, recordsOpenState: true)
        observeBecameKey(of: controller, repoID: repo.id)
        // The checkout scan runs git, so it is a task. There is no reload
        // here: the scan reloads the window through `onTabsDidChange` if — and
        // only if — it actually wrote a different set of tabs. Reloading
        // unconditionally once the scan returned was the bug: the common case
        // is a project whose checkouts have not changed since last time, and
        // it threw away the pane tree the window had just built, and every
        // shell and file-system watcher living in it, to build an identical one.
        Task { await projectController.open() }
        setWindowOpen(true, repoID: repo.id)
        return controller
    }

    /// Takes `repoID` out of `group`: the next active project goes on screen
    /// in its place if it was the one shown — the empty window if it was the
    /// last — and its window closes, stopping its sessions.
    ///
    /// - Parameter synchronously: close the window before returning. False
    ///   for the shelf's close box, which is running inside the very window
    ///   being closed when the project is the one on screen.
    private func closeActiveProject(_ repoID: UUID, in group: ProjectWindowGroup, synchronously: Bool) {
        guard let controller = controllers[repoID] else { return }
        let wasShown = shownWindows[group.id] === controller
        let next = group.deactivate(repoID)
        if wasShown {
            if let next, let incoming = controllers[next] {
                group.select(next)
                swap(to: incoming, in: group)
            } else {
                group.select(nil)
                if let empty = showEmptyWindow(for: group) {
                    swap(to: empty, in: group)
                }
            }
        }
        persistGroups()
        if synchronously {
            controller.close()
        } else {
            DispatchQueue.main.async { controller.close() }
        }
    }

    /// The window `group` shows while it has no project, made on first use
    /// and shown at once when the group has nothing else on screen. `nil` in
    /// a host with no registry: a window with nothing to choose from is not
    /// worth showing.
    @discardableResult
    private func showEmptyWindow(for group: ProjectWindowGroup) -> EmptyProjectWindowController? {
        if let existing = emptyWindows[group.id] { return existing }
        guard let shelf = makeShelf(for: group) else { return nil }
        let empty = EmptyProjectWindowController(groupID: group.id, shelf: shelf)
        emptyWindows[group.id] = empty
        empty.loadWindow()
        if shownWindows[group.id] == nil {
            shownWindows[group.id] = empty
            empty.showWindow(nil)
            empty.window?.makeKeyAndOrderFront(nil)
        }
        if let window = empty.window {
            emptyCloseObservers[group.id] = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: nil
            ) { [weak self, weak group] _ in
                MainActor.assumeIsolated {
                    guard let self, let group, !WindowManager.shared.isTerminating,
                          self.groups.contains(where: { $0 === group }) else { return }
                    self.closeGroup(group)
                }
            }
        }
        return empty
    }

    /// Drops an empty window a project has just replaced. On the next turn:
    /// the swap may be running inside that window's own shelf.
    private func discardEmptyWindow(_ empty: EmptyProjectWindowController, of group: ProjectWindowGroup) {
        guard emptyWindows[group.id] === empty else { return }
        emptyWindows.removeValue(forKey: group.id)
        if let observer = emptyCloseObservers.removeValue(forKey: group.id) {
            NotificationCenter.default.removeObserver(observer)
        }
        DispatchQueue.main.async {
            empty.close()
            Self.forgetEmptyWindowState(of: group.id)
        }
    }

    /// An empty window's saved frame and visibility outlive it otherwise —
    /// keyed by a group id nothing will ever use again.
    private static func forgetEmptyWindowState(of groupID: UUID) {
        let windowID = EmptyProjectWindowController.windowID(for: groupID)
        WindowManager.shared.frames.clearSavedState(for: windowID)
        WindowManager.shared.frames.clearVisibility(for: windowID)
    }

    /// Closing a project window closes all of it: every active project in
    /// it, not only the one on screen.
    ///
    /// - Parameter closing: a project whose window is already closing, and
    ///   so is not closed again.
    private func closeGroup(_ group: ProjectWindowGroup, sparing closing: UUID? = nil) {
        // Out of the list first, so the closes below — each of which fires
        // this manager's close observer — find no group left to close.
        removeGroup(group)
        persistGroups()
        for repoID in group.activeRepoIDs where repoID != closing {
            controllers[repoID]?.close()
        }
        if let empty = emptyWindows.removeValue(forKey: group.id) {
            if let observer = emptyCloseObservers.removeValue(forKey: group.id) {
                NotificationCenter.default.removeObserver(observer)
            }
            empty.close()
            Self.forgetEmptyWindowState(of: group.id)
        }
    }

    /// Writes every group to `UserSettings.projectWindows`. Not while quitting
    /// — AppKit closes every window on the way out, and recording those as
    /// the user's closes would reopen nothing next launch.
    private func persistGroups() {
        guard !WindowManager.shared.isTerminating, !isRestoring else { return }
        let states = groups.map(\.state)
        if UserSettings.projectWindows.currentValue != states {
            UserSettings.projectWindows.value = states
        }
    }

    // MARK: - Termination

    /// Shuts down every open project's language servers, concurrently.
    ///
    /// A task group rather than a `for` loop over `await`: each
    /// `LanguageServerSession.stop()` bottoms out in
    /// `SubprocessChannel.terminate()`, which is uncancellable and waits up to
    /// 2.5 seconds for a child that ignores SIGTERM. Those budgets do not
    /// share — five stubborn servers run sequentially is twelve seconds of a
    /// beachball on quit, and run concurrently is still two and a half.
    ///
    /// Called from `ProjectsCoordinator.terminate()`, which the host's
    /// termination sweep already awaits. The per-window path in
    /// `observeClose(of:repoID:)` covers the ordinary case; this covers quitting
    /// with windows still open, where no `willClose` shutdown has run yet.
    public func shutdownAllLanguageServices() async {
        let services = controllers.values.compactMap(\.project.languageServices)
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask { await service.shutdown() }
            }
        }
        // A project whose window closed moments ago is not in `controllers`
        // any more, and its shutdown may still be inside
        // `SubprocessChannel.terminate()`'s ~2.5 s budget. Close a window and
        // press Cmd-Q and the loop above finds nothing to wait for; without
        // this the process exits and takes the detached teardown with it,
        // leaving an orphaned language server behind. The early `guard` that
        // used to stand above the loop is gone for the same reason: "no open
        // windows" is not "nothing to wait for".
        await closeTeardowns.drain()
    }

    // MARK: - Restore

    /// Reopens every project window that was open when the app last quit,
    /// each with all of its active projects built — the ones not on screen
    /// too, so their sessions are running before anyone switches to them —
    /// and the one that was on screen shown. Hosts call this once at launch,
    /// after the registry exists.
    ///
    /// Deliberately not routed through `ProjectsCoordinator.openProject(_:)`:
    /// restoring a window is not the user opening a project, and must not
    /// rewrite `lastOpened` and re-sort the browser on every launch.
    ///
    /// A project window is the app's workspace, not a document, so this does
    /// not consult `reopenOnLaunchPolicy` — that setting governs the recent-
    /// documents reopen in `WindowManager`. Closing the window is how you tell
    /// this to stop reopening it.
    public func restoreOpenProjects() {
        guard let coordinator else { return }
        var states = UserSettings.projectWindows.currentValue
        if states.isEmpty {
            // From before a project window held several projects: one window
            // per project flagged open.
            let plan = Self.restorePlan(
                repos: coordinator.repos,
                wasOpen: { [weak self] in self?.isWindowOpen(repoID: $0.id) ?? false },
                existsOnDisk: { FileManager.default.fileExists(atPath: $0.path) }
            )
            for repo in plan.forget {
                Self.logger.info("Not reopening \(repo.name, privacy: .public): its folder is gone")
                setWindowOpen(false, repoID: repo.id)
            }
            states = plan.reopen.map { ProjectWindowState(activeRepoIDs: [$0.id], selectedRepoID: $0.id) }
        }
        let repos = Dictionary(coordinator.repos.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        isRestoring = true
        for var state in states {
            state.activeRepoIDs = state.activeRepoIDs.filter { id in
                guard let repo = repos[id], controllers[id] == nil else { return false }
                guard FileManager.default.fileExists(atPath: repo.path) else {
                    Self.logger.info("Not reopening \(repo.name, privacy: .public): its folder is gone")
                    setWindowOpen(false, repoID: id)
                    return false
                }
                return true
            }
            if let selected = state.selectedRepoID, !state.activeRepoIDs.contains(selected) {
                state.selectedRepoID = state.activeRepoIDs.first
            }
            let group = makeGroup(state: state)
            for id in state.activeRepoIDs {
                if let repo = repos[id] { makeProjectWindow(repo, in: group) }
            }
            if let selected = state.selectedRepoID, controllers[selected] != nil {
                present(selected, in: group)
            } else if showEmptyWindow(for: group) == nil {
                removeGroup(group)
            }
        }
        isRestoring = false
        persistGroups()
        if !groups.isEmpty {
            refreshOpenWorkspaceIDs()
            activateApp()
        }
    }

    /// Which of the projects flagged open at quit are worth reopening, and
    /// which should have the flag cleared instead.
    ///
    /// A folder deleted or renamed since the last run would reopen as a
    /// workspace with an empty tree and a terminal in `/` — a window that looks
    /// broken rather than absent. Deleting the row is the scan's job; restore
    /// only declines to resurrect it, and forgets the flag so it stops trying
    /// every launch.
    ///
    /// Pure, so the rule can be tested without opening a window.
    static func restorePlan(
        repos: [GitRepo],
        wasOpen: (GitRepo) -> Bool,
        existsOnDisk: (GitRepo) -> Bool
    ) -> (reopen: [GitRepo], forget: [GitRepo]) {
        let open = repos.filter(wasOpen)
        return (open.filter(existsOnDisk), open.filter { !existsOnDisk($0) })
    }

    private func isWindowOpen(repoID: UUID) -> Bool {
        guard let database else { return false }
        do {
            return try database.setting(repoID: repoID, key: Self.openWindowKey) == "1"
        } catch {
            Self.logger.error("Could not read window state for \(repoID.uuidString, privacy: .public): \(error)")
            return false
        }
    }

    private func setWindowOpen(_ isOpen: Bool, repoID: UUID) {
        guard let database else { return }
        do {
            try database.setSetting(repoID: repoID, key: Self.openWindowKey, value: isOpen ? "1" : nil)
        } catch {
            Self.logger.error("Could not record window state for \(repoID.uuidString, privacy: .public): \(error)")
        }
    }

    /// Re-reads worktrees when the window comes back to the front, so a
    /// worktree added or removed in a terminal shows up without a relaunch —
    /// and records the window as the one the next new project is arranged
    /// like (`UserSettings.lastActiveProjectWindow`).
    private func observeBecameKey(of controller: ComposableTabsWindowController, repoID: UUID) {
        guard let window = controller.window else { return }
        keyObservers[repoID] = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: window,
            queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                if UserSettings.lastActiveProjectWindow.currentValue != repoID.uuidString {
                    UserSettings.lastActiveProjectWindow.value = repoID.uuidString
                }
                guard let projectController = self?.projectControllers[repoID] else { return }
                Task { await projectController.refreshCheckouts() }
            }
        }
    }

    /// Drops the controller when its window closes, so reopening the project
    /// builds a fresh window rather than resurrecting a closed one.
    ///
    /// - Parameter recordsOpenState: whether the close should also clear the
    ///   persisted "reopen this next launch" flag. True for a window this
    ///   manager opened; false for one it merely adopted, whose open state is
    ///   not its to decide. The deregistration itself happens either way.
    private func observeClose(
        of controller: ComposableTabsWindowController,
        repoID: UUID,
        recordsOpenState: Bool
    ) {
        guard let window = controller.window else { return }
        // `queue: nil`, not `.main`: a queue makes delivery an *enqueue*, so the
        // block runs a runloop turn after the close. The scan closes a deleted
        // project's window and then deletes its row in the same turn, and a
        // block that lands after that deletes-then-writes — a foreign key that
        // no longer resolves, and a controller still registered for a project
        // that is gone. Running on the poster's thread (always the main one,
        // for a window close) keeps the order the caller wrote.
        closeObservers[repoID] = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                // AppKit closes still-open windows on the way out of the app.
                // Recording that as "the user closed it" would stop every open
                // project from reopening next launch, which is the opposite of
                // what quitting with windows open means.
                if recordsOpenState, !WindowManager.shared.isTerminating {
                    self.setWindowOpen(false, repoID: repoID)
                }
                // Still active in its group means this is the window's own
                // close button, not the shelf's close box (which takes the
                // project out of the group first) — and closing a project
                // window closes every project in it.
                if !WindowManager.shared.isTerminating, let group = self.group(containing: repoID) {
                    self.closeGroup(group, sparing: repoID)
                }
                // Captured strongly and *before* the controller is dropped:
                // dropping it releases the workspace and with it the services,
                // and a shutdown needs the object to still exist when the task
                // it schedules runs. Nothing waits for it *here* — a window
                // close must not block the main thread on a subprocess
                // exiting — but the quit path does, through `closeTeardowns`.
                //
                // Routed through the project controller when there is one,
                // since `ProjectController.shutdown()` and this inline path
                // both end at `languageServices.shutdown()` — running both
                // would shut the same services down twice. The inline path
                // stays for a window `adoptForScripting(_:)` registered,
                // which has no project controller of its own.
                //
                // `markClosed()` first, and synchronously: `shutdown()` sets
                // the same flag, but only once the task below is scheduled,
                // and a reconcile continuation already enqueued ahead of that
                // task would resume in between with the flag still down —
                // writing a closed window's checkouts, registering its
                // commands and persisting its tabs. The flag has to be down
                // before this turn ends, not merely soon.
                let projectController = self.projectControllers.removeValue(forKey: repoID)
                projectController?.markClosed()
                // `markClosed()` takes back every branch command this window
                // registered — but the ids are derived from the checkout's
                // directory alone, so a second window over the same repository
                // owns the identical ids and has just lost them. Offer every
                // surviving controller its own commands back; the ones that
                // never collided are still registered and are left alone.
                for surviving in self.projectControllers.values {
                    surviving.reregisterCommands()
                }
                if let observer = self.keyObservers.removeValue(forKey: repoID) {
                    NotificationCenter.default.removeObserver(observer)
                }
                let services = self.controllers[repoID]?.project.languageServices
                if let project = self.controllers[repoID]?.project {
                    self.onProjectClosed?(project)
                }
                self.controllers.removeValue(forKey: repoID)
                self.openOrder.removeAll { $0 == repoID }
                self.adoptedForScripting.remove(repoID)
                self.refreshOpenWorkspaceIDs()
                if let projectController {
                    self.closeTeardowns.add { await projectController.shutdown() }
                } else if let services {
                    self.closeTeardowns.add { await services.shutdown() }
                }
                if let observer = self.closeObservers.removeValue(forKey: repoID) {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
}

extension ProjectWindowManager: Loggable {
    public static nonisolated let logger = makeLogger()
}
