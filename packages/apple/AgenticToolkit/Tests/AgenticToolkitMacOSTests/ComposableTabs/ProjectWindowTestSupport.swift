import AppKit
import Synchronization
import XCTest
@testable import AgenticToolkitLanguage
@testable import AgenticToolkitMacOS

/// One unique directory per call under the system temp directory, removed
/// when the test process exits.
///
/// Factories that hand back an object with no handle on its directory
/// (`makeProject`, each suite's `makeWorkspace`) cannot clean up after
/// themselves, and a SQLite database leaves `-wal` and `-shm` beside its
/// `.db`, so the whole directory is what has to go. Everything a test writes
/// goes inside the directory this returns; nothing is written to the temp root.
enum TestTempDirectory {
    private static let created = Mutex<[URL]>([])

    /// `atexit` takes a function that captures nothing, so it calls back into
    /// this type; the lazy static makes the registration happen exactly once.
    private static let removeAtExit: Void = {
        atexit { TestTempDirectory.removeAll() }
    }()

    /// Makes `<temp>/<label>-<UUID>/` and schedules its removal.
    static func make(label: String) -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(label)-\(UUID().uuidString)", isDirectory: true)
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        register(directory)
        return directory
    }

    /// Schedules removal of a directory a suite made itself.
    static func register(_ directory: URL) {
        _ = removeAtExit
        created.withLock { $0.append(directory) }
    }

    static func removeAll() {
        let directories = created.withLock { directories -> [URL] in
            defer { directories.removeAll() }
            return directories
        }
        for directory in directories {
            try? FileManager.default.removeItem(at: directory)
        }
    }
}

/// Scaffolding shared by the project-window suites.
///
/// Two helpers had been copied into `ProjectWindowSearchTests` and
/// `ProjectDrawerTests` verbatim, and a third suite is where a copy stops
/// being a compromise (`dry`). Only the parts that are genuinely the same are
/// here: each suite still installs its own layout, because what its panes are
/// made of is the thing each suite is actually varying.
@MainActor
enum ProjectWindowTestSupport {

    /// AppKit only asks the delegate for its items once a toolbar is on a
    /// window, and a custom-view item is the only place an accessibility
    /// identifier — or an `NSSearchField` — can live, so the test does the
    /// asking itself.
    ///
    /// Nothing is refreshed afterwards: the field has to be right the moment it
    /// exists. A test that hand-ordered a refresh after the ask would be
    /// arranging an ordering production only probably achieves.
    @discardableResult
    static func buildToolbarItems(
        _ controller: ComposableTabsWindowController
    ) -> [NSToolbarItem.Identifier] {
        let toolbar = controller.toolbarDelegate.makeToolbar(identifier: "test.toolbar")
        let identifiers = controller.toolbarDelegate.toolbarDefaultItemIdentifiers(toolbar)
        for identifier in identifiers {
            _ = controller.toolbarDelegate.toolbar(
                toolbar, itemForItemIdentifier: identifier, willBeInsertedIntoToolbar: false)
        }
        return identifiers
    }

    /// A workspace on its own temporary database, so two tests never share a
    /// remembered anything.
    ///
    /// The repo is registered before the workspace is made: every row keyed to
    /// a project carries a foreign key onto `git_repo`, so a workspace over an
    /// unregistered repo silently persists nothing — and every "the project
    /// remembered it" assertion reads back as a brand-new project.
    ///
    /// - Parameters:
    ///   - label: names the temporary directory, so a failure names its suite.
    ///   - registered: pass `false` for the one case that wants a workspace
    ///     whose repo is *not* in `git_repo` — the state in which the chrome
    ///     still has to work while `setSetting` swallows every failure.
    ///   - languageServices: `nil` by default, matching every existing
    ///     caller. A suite proving something about per-window language-server
    ///     teardown passes its own instance rather than this helper building
    ///     one every caller would otherwise pay for.
    static func makeProject(
        label: String,
        named name: String = "api-server",
        registered: Bool = true,
        languageServices: ProjectLanguageServices? = nil
    ) -> ProjectWorkspace {
        let path = TestTempDirectory.make(label: label)
            .appendingPathComponent("Test.db").path
        let repo = GitRepo(path: NSTemporaryDirectory(), name: name)
        // swiftlint:disable:next force_try
        let database = try! ProjectDatabase(path: path)
        if registered {
            // swiftlint:disable:next force_try
            try! database.insert(repo)
        }
        return ProjectWorkspace(repo: repo, database: database, languageServices: languageServices)
    }

    /// A one-entry registry holding only an editor, matching what the
    /// Document pane installs as its `layoutOverride` in the running app: a
    /// tab there may hold editors and nothing else.
    ///
    /// `min: 1` on the allowance is what makes the container's floor a fact
    /// about the layout spec rather than something `DocumentTabsViewController`
    /// has to police on its own — a tab can never be split down to zero
    /// editors because the spec itself refuses to remove the last one.
    static func makeDocumentLayout(
        viewID: ComposableTabsViewID = ComposableTabsViewID("document.editor")
    ) throws -> ComposableTabsLayout {
        let registry = ComposableTabsViewRegistry()
        registry.register(viewID, descriptor: .init(displayName: "Editor")) { context in
            DocumentEditorViewController(
                store: context.makeStateStore(prefix: "document."),
                documentStore: TextDocumentStore(),
                saveScheduler: TextDocumentSaveScheduler(write: { _ in }),
                languageServices: nil,
                rootURL: context.workingDirectory
            )
        }
        return try ComposableTabsLayout(
            registry: registry,
            spec: .pane(viewID, allows: [.unbounded(viewID, min: 1)])
        )
    }
}
