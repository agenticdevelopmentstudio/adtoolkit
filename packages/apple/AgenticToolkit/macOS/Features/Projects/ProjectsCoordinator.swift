import AppKit
import OSLog
import AgenticToolkitCore

/// Opens a project's window. Injected rather than owned so the registry — the
/// database, the scan, the chooser — does not depend on the window layer, and
/// can be exercised without one (`dependency-injection`).
@MainActor
public protocol ProjectOpening: AnyObject {
    func openProject(_ repo: GitRepo)

    /// Closes the project's window, if it has one. Called when the project
    /// stops existing: a window still bound to a row that is about to be
    /// deleted can only fail on its next write (`fail-fast`).
    func closeProject(repoID: UUID)
}

/// The project registry feature: one database, the list of known git
/// repositories, and the scan that keeps that list true.
///
/// A "project" here is a row, not a file. Nothing about a project lives in the
/// repository's own directory, so a repository can be renamed or moved without
/// losing its settings or its window layout.
@MainActor
public final class ProjectsCoordinator: AppFeature {

    /// Posted after any change to the repository list — a scan finishing, a
    /// rename, a project being opened. Carries no payload: readers ask for
    /// `repos`, which is the one representation of that knowledge (`dry`).
    public static let didChangeNotification = Notification.Name("ProjectsCoordinatorDidChange")

    public let database: ProjectDatabase
    public private(set) var repos: [GitRepo] = []
    public private(set) var isScanning = false
    /// The result of the most recent scan, for anything that wants to show it
    /// after the progress panel has gone.
    public private(set) var lastScanSummary: ProjectScanSummary?

    /// The projects to offer the user: every registered one except those the
    /// scan settings now leave out.
    ///
    /// Hidden rather than deleted. A row under a directory the user has just
    /// skipped is still a repository, and the reconciler keeps it so that its
    /// layout and settings survive; taking the directory back out brings it
    /// straight back. `repos` stays the whole registry, because restoring a
    /// window or renaming a project is about the row, not about the list.
    /// Recomputed in `reload()`, which every change to either input goes
    /// through, rather than on every read: a filter field reads it per
    /// keystroke, and each `skips` call touches the disk.
    public private(set) var listedRepos: [GitRepo] = []

    /// Shows the project picker, handed in by the host — the command palette's
    /// picker mode in the app. The registry does not know what a palette is
    /// (`dependency-injection`).
    public var presentChooser: (() -> Void)?

    /// Set only by a test or a host that wants a particular walk. Left `nil`,
    /// each scan builds its own scanner from the current settings, so editing
    /// them takes effect at once rather than on the next launch.
    private let injectedScanner: GitRepoScanner?
    private weak var opener: ProjectOpening?
    private var progressWindow: ProjectScanProgressWindow?
    private var settingObservers: [AnyObject] = []
    /// A settings change that landed while a scan was running. The running
    /// scan walked the old settings, so it is followed by one more.
    private var rescanPending = false

    /// The ids this feature's actions answer to. Named once here rather than
    /// spelled at each of the register/contribute pairs: they are the contract
    /// `contributes.menus` (4.5) and the extension host (Stage 5) address, so a
    /// typo in one of two copies would be a silently dead menu item.
    public enum CommandID {
        public static let openProject = "projects.action.openProject"
        public static let scanForProjects = "projects.action.scanForProjects"
    }

    /// - Parameter commandRegistry: Where this feature's actions are registered
    ///   so a palette, a shortcut or an extension can reach them by id.
    ///
    ///   **Required, deliberately.** A defaulted private registry would let a
    ///   caller omit the argument and still get a working menu — while the
    ///   palette silently lost this entire feature's commands, with no log, no
    ///   crash and nothing a test could observe, since a private registry is
    ///   reachable only through the closures its own menu items captured. That
    ///   is the exact silent-wrong-behaviour the rest of this design refuses
    ///   (`execute` throws rather than no-op'ing; `isEnabled(id:)` answers
    ///   `false`, not `true`, for an id nobody registered). Requiring the
    ///   parameter moves the failure to compile time, where it costs one line
    ///   to fix.
    public init(
        database: ProjectDatabase,
        scanner: GitRepoScanner? = nil,
        opener: ProjectOpening? = nil,
        commandRegistry registry: CommandRegistry
    ) throws {
        self.database = database
        self.injectedScanner = scanner
        self.opener = opener
        super.init()

        self.repos = (try? database.allRepos()) ?? []
        self.listedRepos = Self.listed(repos, by: currentScanner)

        // A settings change updates the registry at once: the list drops what
        // the new settings leave out straight away (a scan would not — it keeps
        // rows that are still repositories), and a quiet scan picks up what
        // they newly cover.
        let changed: () -> Void = { [weak self] in self?.scanSettingsDidChange() }
        settingObservers = [
            UserSettingObserver(UserSettings.projectDirectories) { _ in changed() },
            UserSettingObserver(UserSettings.projectSkippedDirectories) { _ in changed() },
            UserSettingObserver(UserSettings.projectScanSkipsHiddenDirectories) { _ in changed() },
            UserSettingObserver(UserSettings.projectScanSkipsSubmodules) { _ in changed() }
        ]

        registry.register(AppCommand(
            id: CommandID.openProject,
            title: "Choose Project…",
            category: "Projects",
            run: { [weak self] in self?.showProjectChooser() }
        ))
        registry.register(AppCommand(
            id: CommandID.scanForProjects,
            title: "Scan for Projects",
            category: "Projects",
            run: { [weak self] in self?.scan() }
        ))

        self.menuContributions = [
            MenuContribution(
                slot: .file,
                title: "Open Project…",
                commandID: CommandID.openProject,
                registry: registry,
                order: 0,
                key: "p",
                modifiers: [.command, .option]
            ),
            MenuContribution(
                slot: .file,
                title: "Scan for Projects",
                commandID: CommandID.scanForProjects,
                registry: registry,
                order: 10,
                isHidden: { [weak self] in self?.isScanning ?? false }
            )
        ]
    }

    /// Set once by the host after the window layer exists — the opener and the
    /// registry would otherwise have to be constructed in the same breath.
    public func setOpener(_ opener: ProjectOpening) {
        self.opener = opener
    }

    // MARK: - AppFeature

    /// Launching scans: the registry is only as good as its last look at disk,
    /// and the alternative is an app whose project list is quietly wrong until
    /// someone thinks to refresh it.
    public override func start() throws {
        scan()
    }

    public override func stop() {
        try? database.checkpoint()
    }

    /// Stops every open project's language servers before the process exits.
    ///
    /// Awaited by the host's termination sweep, which is the only place that
    /// can wait: `stop()` is synchronous and a language server exits by way of
    /// `SubprocessChannel.terminate()`, which is not. Without this, quitting
    /// with project windows open leaves the `willCloseNotification` shutdowns
    /// racing the process exit and orphans a `sourcekit-lsp` per window.
    ///
    /// Reached through `opener` rather than `ProjectWindowManager.shared` so a
    /// host that attached its own manager gets that one. The cast is the seam
    /// on purpose: `ProjectOpening` says nothing about language servers, and
    /// widening it for this one call would push an LSP concern into the
    /// protocol the registry is tested against.
    public override func terminate() async {
        guard let windows = opener as? ProjectWindowManager else { return }
        await windows.shutdownAllLanguageServices()
    }

    // MARK: - Registry

    public func repo(id: UUID) -> GitRepo? {
        repos.first { $0.id == id }
    }

    private static func listed(_ repos: [GitRepo], by scanner: GitRepoScanner) -> [GitRepo] {
        repos.filter { !scanner.skips(path: $0.path) }
    }

    /// The scanner a scan would use right now — the injected one, or one built
    /// from the current settings so an edit takes effect at once.
    private var currentScanner: GitRepoScanner {
        injectedScanner ?? UserSettings.projectScanner()
    }

    private func scanSettingsDidChange() {
        reload()
        if isScanning {
            rescanPending = true
        } else {
            scan(showingProgress: false)
        }
    }

    /// Renames a project. The name is the user's; a scan never overwrites it.
    public func rename(repoID: UUID, to name: String) {
        guard var repo = repo(id: repoID) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != repo.name else { return }
        repo.name = trimmed
        do {
            try database.update(repo)
            reload()
        } catch {
            Self.logger.error("Rename failed for \(repoID.uuidString, privacy: .public): \(error)")
        }
    }

    public func openProject(_ repo: GitRepo) {
        do {
            try database.markOpened(id: repo.id)
        } catch {
            Self.logger.error("Could not record open time: \(error)")
        }
        reload()
        opener?.openProject(repo)
    }

    /// Shows the picker the host handed in. A host that wired none has a
    /// menu item that does nothing, which is a wiring mistake worth a log line
    /// rather than silence (`fail-fast`).
    public func showProjectChooser() {
        guard let presentChooser else {
            Self.logger.error("Choose Project… has no picker: the host never set presentChooser")
            return
        }
        presentChooser()
    }

    /// The picker's content: the project browser in chooser mode, which opens
    /// the project it is told to choose after `dismiss` has put the picker
    /// away — a window must not open behind a panel about to vanish.
    public func makeChooser(dismiss: @escaping () -> Void) -> ProjectBrowserViewController {
        let browser = ProjectBrowserViewController(coordinator: self, mode: .chooser)
        browser.onChoose = { [weak self] repo in
            dismiss()
            self?.openProject(repo)
        }
        return browser
    }

    private func reload() {
        repos = (try? database.allRepos()) ?? repos
        listedRepos = Self.listed(repos, by: currentScanner)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    // MARK: - Scanning

    /// Walks the scan roots on a background queue and reconciles the result
    /// into the database. Re-entrant calls are dropped rather than queued: two
    /// scans of the same disk produce the same answer, so the second is waste.
    public func scan(showingProgress: Bool = true) {
        guard !isScanning else { return }
        isScanning = true

        if showingProgress {
            let window = ProjectScanProgressWindow()
            window.present()
            progressWindow = window
        }

        let scanner = currentScanner
        Task.detached(priority: .utility) {
            let found = scanner.scan()
            await MainActor.run { self.finishScan(found: found) }
        }
    }

    private func finishScan(found: [ScannedGitRepo]) {
        let plan = ProjectReconciler.plan(existing: repos, scanned: found)
        var summary = plan.summary

        // Each row is applied on its own. One failed write used to abandon
        // every row after it while the summary still claimed the whole plan had
        // been applied, so the registry and what the user was told disagreed
        // (`fail-fast`: report what actually happened, per row).
        for repo in plan.inserts {
            do { try database.insert(repo) } catch {
                summary.added -= 1
                Self.logger.error("Could not add \(repo.path, privacy: .public): \(error)")
            }
        }
        for repo in plan.updates {
            do { try database.update(repo) } catch {
                Self.logger.error("Could not update \(repo.path, privacy: .public): \(error)")
            }
        }
        // Windows close first: closing one writes to the row it belongs
        // to, which after the delete is a foreign key that no longer
        // resolves.
        for repo in plan.deletes { opener?.closeProject(repoID: repo.id) }
        for repo in plan.deletes {
            do {
                try database.delete(id: repo.id)
            } catch {
                summary.removed -= 1
                Self.logger.error("Could not remove \(repo.path, privacy: .public): \(error)")
                continue
            }
            // The rows cascade; the window frame does not — it lives in
            // `UserDefaults` under an id nothing else will ever ask for
            // again, so it is cleared here or it is leaked forever.
            let windowID = ComposableTabsWindowController.windowID(for: repo.id)
            WindowManager.shared.frames.clearSavedState(for: windowID)
            WindowManager.shared.frames.clearVisibility(for: windowID)
        }

        lastScanSummary = summary
        isScanning = false
        reload()
        if rescanPending {
            rescanPending = false
            scan(showingProgress: false)
        }

        Self.logger.info("Scan complete: \(summary.summaryText, privacy: .public)")
        progressWindow?.finish()
        progressWindow = nil
    }
}

extension ProjectsCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
