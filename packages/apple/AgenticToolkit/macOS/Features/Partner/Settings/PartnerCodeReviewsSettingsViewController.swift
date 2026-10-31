import AppKit

import AgenticToolkitCore
import os

/// Code Reviews tab: how the code-reviews job crawls and reviews, and which projects it reviews.
@MainActor
public final class PartnerCodeReviewsSettingsViewController: ComposableSettings.SettingsPanelViewController,
    NSTableViewDataSource, NSTableViewDelegate {

    private static let logger = Logger(subsystem: "com.agenticdevelopertoolkit",
                                       category: "PartnerCodeReviewsSettings")
    /// The per-repo `review_setting` key the Review checkbox writes; "1" means the repo is not reviewed.
    static let optedOutKey = "opted_out"

    private let store: PartnerStore
    private let projects: @MainActor () -> [PartnerToolSource.Project]
    private let settings: SettingsStore
    /// Internal for tests.
    let projectsTable = NSTableView()
    /// The projects as last listed. Internal for tests.
    private(set) var listed: [PartnerToolSource.Project] = []

    public init(store: PartnerStore, projects: @escaping @MainActor () -> [PartnerToolSource.Project],
                settings: SettingsStore = UserSettings.shared) {
        self.store = store
        self.projects = projects
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Code Reviews",
            icon: NSImage(systemSymbolName: "checkmark.bubble", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["code reviews", "review", "crawl", "commits", "window", "interval", "concurrency", "branches",
         "reviewer", "model", "fix branch", "projects", "opt out"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Code reviews",
                  body: "When the Code reviews job is enabled on the Jobs tab, the partner crawls your projects "
                      + "for recent commits, reviews each one in a worktree of its own with /code-review, and "
                      + "commits the fixes on the fix branch. Nothing is pushed."),
            .init(title: "Crawl interval",
                  body: "How often the crawl runs. Changing it rewrites the job's schedule and restarts its "
                      + "timer, which crawls at once."),
            .init(title: "Projects",
                  body: "Uncheck Review to leave a project out of the crawl. Reviews already queued for it stay.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let settings = self.settings

        let crawl = ComposableSettings.GroupView(withTitle: "Crawl")
        crawl.addSettingSubview(identified(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Review commits from the last (hours)", minValue: 1, maxValue: 24 * 30,
                get: { settings.get(UserSettings.partnerReviewsWindowHours) },
                set: { settings.set($0, for: UserSettings.partnerReviewsWindowHours) })),
            "settings.partner.reviews.window-hours"))
        crawl.addSettingSubview(identified(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Crawl every (minutes)", minValue: 1, maxValue: 24 * 60,
                get: { settings.get(UserSettings.partnerReviewsCrawlIntervalMinutes) },
                set: { settings.set($0, for: UserSettings.partnerReviewsCrawlIntervalMinutes) },
                explanation: "The Code reviews job's schedule.")),
            "settings.partner.reviews.crawl-interval"))
        crawl.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Include other local branches",
            get: { settings.get(UserSettings.partnerReviewsIncludeOtherBranches) },
            set: { settings.set($0, for: UserSettings.partnerReviewsIncludeOtherBranches) },
            explanation: "Off, only each project's default branch is crawled.")))
        addGroup(crawl)

        let review = ComposableSettings.GroupView(withTitle: "Reviewing")
        review.addSettingSubview(identified(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Reviews at once", minValue: 1, maxValue: 8,
                get: { settings.get(UserSettings.partnerReviewsConcurrency) },
                set: { settings.set($0, for: UserSettings.partnerReviewsConcurrency) },
                explanation: "Never more than one per project.")),
            "settings.partner.reviews.concurrency"))
        review.addSettingSubview(ComposableSettings.TextEditView(with: ComposableSettings.ViewModel<String>(
            title: "Reviewer model",
            get: { settings.get(UserSettings.partnerReviewsReviewerModel) },
            set: { settings.set($0, for: UserSettings.partnerReviewsReviewerModel) },
            explanation: "Passed to the reviewer's claude --model. Empty uses Claude Code's own default.")))
        review.addSettingSubview(ComposableSettings.TextEditView(with: ComposableSettings.ViewModel<String>(
            title: "Fix branch",
            get: { settings.get(UserSettings.partnerReviewsFixBranch) },
            set: { settings.set($0, for: UserSettings.partnerReviewsFixBranch) },
            explanation: "Fixes are committed here; other branches get this name plus their own.")))
        addGroup(review)

        let repos = ComposableSettings.GroupView(withTitle: "Projects")
        configureProjectsTable()
        let scroll = NSScrollView()
        scroll.documentView = projectsTable
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.heightAnchor.constraint(equalToConstant: 180).isActive = true
        repos.addSettingSubview(scroll)
        addGroup(repos)
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        reloadProjects()
    }

    /// Names a number field's text field, so accessibility can find and drive it.
    private func identified(_ view: ComposableSettings.IntegerFieldView,
                            _ identifier: String) -> ComposableSettings.IntegerFieldView {
        _ = view.textField.accessibilityID(identifier)
        return view
    }

    // MARK: - Projects

    /// Re-reads the projects; ones without a path cannot be crawled and are left out.
    func reloadProjects() {
        listed = projects().filter { !$0.path.isEmpty }
        projectsTable.reloadData()
    }

    /// Whether the project is reviewed: anything but an explicit opt-out. Unreadable counts as reviewed here,
    /// since the crawl logs and skips it on its own.
    func isReviewed(_ projectID: String) -> Bool {
        do { return try store.reviewSetting(repoID: projectID, key: Self.optedOutKey) != "1" } catch {
            Self.logger.error("Reading a review opt-out failed: \(error.localizedDescription)")
            return true
        }
    }

    /// Opting back in deletes the setting rather than storing "0".
    func setReviewed(_ reviewed: Bool, projectID: String) {
        do {
            try store.setReviewSetting(repoID: projectID, key: Self.optedOutKey, value: reviewed ? nil : "1")
        } catch {
            Self.logger.error("Saving a review opt-out failed: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    private func configureProjectsTable() {
        for (id, title, width) in [("name", "Name", 140.0), ("path", "Path", 260.0), ("review", "Review", 60.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            projectsTable.addTableColumn(column)
        }
        projectsTable.dataSource = self
        projectsTable.delegate = self
        projectsTable.usesAlternatingRowBackgroundColors = true
        _ = projectsTable.accessibilityID("settings.partner.reviews.projects")
    }

    public func numberOfRows(in tableView: NSTableView) -> Int { listed.count }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier, listed.indices.contains(row) else { return nil }
        let project = listed[row]
        switch identifier.rawValue {
        case "review":
            let box = NSButton(checkboxWithTitle: "", target: self, action: #selector(reviewToggled(_:)))
            box.state = isReviewed(project.id) ? .on : .off
            box.tag = row
            _ = box.accessibilityID("settings.partner.reviews.review.\(project.id)")
            return box
        case "path":
            let field = NSTextField(labelWithString: project.path)
            field.lineBreakMode = .byTruncatingMiddle
            field.toolTip = project.path
            return field
        default:
            let field = NSTextField(labelWithString: project.name)
            field.lineBreakMode = .byTruncatingTail
            return field
        }
    }

    @objc private func reviewToggled(_ sender: NSButton) {
        guard listed.indices.contains(sender.tag) else { return }
        let project = listed[sender.tag]
        setReviewed(sender.state == .on, projectID: project.id)
        sender.state = isReviewed(project.id) ? .on : .off
    }
}
