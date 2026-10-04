#if os(macOS)
import AppKit
import UniformTypeIdentifiers
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS
import AgenticToolkitMacOS

/// Settings → Tracked Apps: whether app time is recorded, whether the
/// Accessibility grant that lets it be attributed is in place, which apps
/// count, and how long the detail is kept.
///
/// The panel never asks the system about Accessibility itself — that call
/// freezes the machine when the grant is missing. It only shows what the
/// injected `status` returns, and runs `recheck` after the person pressed
/// "Grant…" (when the panel reappears) or "Check Again".
@MainActor
public final class TrackedAppsSettingsPanel: ComposableSettings.SettingsPanelViewController {

    private let settings: WorkTrackingUserSettings
    private let status: @MainActor () async -> WorkTrackingStatus?
    private let recheck: @MainActor () async -> WorkTrackingStatus?
    private let openAccessibilitySettings: @MainActor () -> Void
    private let chooseApp: @MainActor () -> (bundleId: String, name: String)?

    /// Set by "Grant…"; the next refresh runs `recheck` instead of `status`
    /// and clears it, so the check happens once per press.
    private var grantPressed = false
    private var grantPresses = 0
    private var chosenNames: [String: String] = [:]

    private var accessibilityLine: ComposableSettings.ExplanationView?
    private var degradedLine: ComposableSettings.ExplanationView?
    private var failureLine: ComposableSettings.ExplanationView?
    private var checkButton: ComposableSettings.ButtonView?
    /// Bumped before every `status()`/`recheck()` await; a result whose
    /// generation is no longer current is stale and dropped.
    private var refreshGeneration = 0
    private var rechecksInFlight = 0
    private var lastStatus: WorkTrackingStatus?
    private var appsCard: ComposableSettings.EditableTableCard?

    public init(settings: WorkTrackingUserSettings,
                status: @escaping @MainActor () async -> WorkTrackingStatus?,
                recheck: @escaping @MainActor () async -> WorkTrackingStatus?,
                openAccessibilitySettings: @escaping @MainActor () -> Void = TrackedAppsSettingsPanel.openPrivacyPane,
                chooseApp: @escaping @MainActor () -> (bundleId: String, name: String)? = TrackedAppsSettingsPanel.chooseApplication) {
        self.settings = settings
        self.status = status
        self.recheck = recheck
        self.openAccessibilitySettings = openAccessibilitySettings
        self.chooseApp = chooseApp
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Tracked Apps",
            icon: NSImage(systemSymbolName: "app.badge.checkmark", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override var searchKeywords: [String] {
        ["tracked", "apps", "work", "accessibility", "xcode", "editor", "terminal", "retention"]
    }

    // MARK: - Pure parts

    /// Rows: defaults ∪ added, each checked unless removed.
    static func rows(preferences: WorkTrackingPreferences) -> [(app: TrackedApp, checked: Bool)] {
        let removed = Set(preferences.removedBundleIds)
        let defaults = AppAllowlist.defaults
        let known = Set(defaults.map(\.bundleId))
        var apps = defaults
        for id in Set(preferences.addedBundleIds).sorted() where !known.contains(id) {
            apps.append(TrackedApp(bundleId: id, name: id, resolver: .editor))
        }
        return apps.map { (app: $0, checked: !removed.contains($0.bundleId)) }
    }

    /// Preferences after toggling one row.
    static func toggling(_ bundleId: String, on: Bool, in prefs: WorkTrackingPreferences) -> WorkTrackingPreferences {
        var next = prefs
        let isDefault = AppAllowlist.defaults.contains { $0.bundleId == bundleId }
        if on {
            next.removedBundleIds.removeAll { $0 == bundleId }
        } else if isDefault {
            next.removedBundleIds.append(bundleId)
        } else {
            next.addedBundleIds.removeAll { $0 == bundleId }
        }
        return next.normalized()
    }

    /// Preferences after adding an app: appended unless already present, and
    /// no longer removed.
    static func adding(_ bundleId: String, to prefs: WorkTrackingPreferences) -> WorkTrackingPreferences {
        var next = prefs
        next.removedBundleIds.removeAll { $0 == bundleId }
        let isDefault = AppAllowlist.defaults.contains { $0.bundleId == bundleId }
        if !isDefault && !next.addedBundleIds.contains(bundleId) {
            next.addedBundleIds.append(bundleId)
        }
        return next.normalized()
    }

    /// True for an app the user added; false for a built-in default.
    static func isAddedApp(_ bundleId: String) -> Bool {
        !AppAllowlist.defaults.contains { $0.bundleId == bundleId }
    }

    static func accessibilityText(_ status: WorkTrackingStatus?) -> String {
        switch status?.accessibility ?? .unknown {
        case .granted: "Granted"
        case .denied: "Not granted"
        case .unknown: "Unknown — press Check Again"
        }
    }

    static func failureText(_ status: WorkTrackingStatus?) -> String? {
        guard let status, status.writeFailures > 0 else { return nil }
        return "\(status.writeFailures) writes failed — last: \(status.lastError ?? "unknown")"
    }

    // MARK: - System helpers

    public static func openPrivacyPane() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    public static func chooseApplication() -> (bundleId: String, name: String)? {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let bundleId = Bundle(url: url)?.bundleIdentifier else { return nil }
        let name = FileManager.default.displayName(atPath: url.path)
        return (bundleId, name.hasSuffix(".app") ? String(name.dropLast(4)) : name)
    }

    // MARK: - Layout

    public override func viewDidLoad() {
        super.viewDidLoad()

        let work = ComposableSettings.GroupView(withTitle: "Work Tracking")
        work.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: "Track time in development apps",
                setting: settings.enabled
            )
        ))
        work.addSettingSubview(ComposableSettings.ExplanationView(
            withText: "Time spent in the apps below is billed to the project whose repository the app is working in."
        ))
        addGroup(work)

        let access = ComposableSettings.GroupView(withTitle: "Accessibility")
        let line = ComposableSettings.ExplanationView(withText: Self.accessibilityText(nil))
        accessibilityLine = line
        access.addSettingSubview(line)
        access.addSettingSubview(ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(title: "Grant…") { [weak self] in
                MainActor.assumeIsolated { self?.grantTapped() }
            },
            placement: .leading
        ))
        let check = ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(title: "Check Again") { [weak self] in
                MainActor.assumeIsolated { self?.checkAgainTapped() }
            },
            placement: .leading
        )
        checkButton = check
        access.addSettingSubview(check)
        let degraded = ComposableSettings.ExplanationView(withText: WorkTrackingStatus.degradedNotice)
        degraded.isHidden = true
        degradedLine = degraded
        access.addSettingSubview(degraded)
        let failure = ComposableSettings.ExplanationView(withText: "")
        failure.isHidden = true
        failureLine = failure
        access.addSettingSubview(failure)
        addGroup(access)

        let card = ComposableSettings.EditableTableCard(
            title: "Apps",
            columns: [
                .init(id: "track", title: "Track", width: 44, kind: .toggle),
                .init(id: "app", title: "App", width: 260)
            ],
            emptyMessage: "Add an app to track its time.",
            visibleRows: 8,
            accessibilityPrefix: "worktracking.apps"
        )
        card.onToggle = { [weak self] rowID, _, isOn in self?.apply(toggling: rowID, on: isOn) }
        card.onAdd = { [weak self] in self?.addTapped() }
        card.onRemove = { [weak self] rowID in self?.apply(toggling: rowID, on: false) }
        // Defaults are switched off with their toggle; only added apps are removed.
        card.canRemoveRow = { Self.isAddedApp($0) }
        appsCard = card
        addGroup(card)
        reloadRows()

        let retention = ComposableSettings.GroupView(withTitle: "Retention")
        retention.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Keep activity detail for",
                setting: settings.retentionDays,
                minValue: WorkTrackingPreferences.retentionDaysRange.lowerBound,
                maxValue: WorkTrackingPreferences.retentionDaysRange.upperBound,
                explanation: "days"
            )
        ))
        addGroup(retention)
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        Task { @MainActor [weak self] in await self?.refresh() }
    }

    // MARK: - Behaviour

    private func grantTapped() {
        grantPressed = true
        grantPresses += 1
        openAccessibilitySettings()
    }

    private func checkAgainTapped() {
        Task { @MainActor [weak self] in await self?.checkAgain() }
    }

    /// An explicit recheck satisfies the pending "Grant…" one, so the next
    /// appear does not repeat it.
    private func checkAgain() async {
        grantPressed = false
        rechecksInFlight += 1
        renderChecking()
        refreshGeneration += 1
        let generation = refreshGeneration
        let result = await recheck()
        rechecksInFlight -= 1
        if generation == refreshGeneration { lastStatus = result }
        renderChecking()
        if generation == refreshGeneration { show(result) }
    }

    /// The `viewWillAppear` path: a recheck only if "Grant…" was pressed since
    /// the last one; otherwise a plain status read.
    private func refresh() async {
        // The pending "Grant…" recheck is cleared only once a result is
        // applied, so a refresh that is superseded hands it on to the newer one.
        let wantsRecheck = grantPressed
        let pressesSeen = grantPresses
        refreshGeneration += 1
        let generation = refreshGeneration
        let result = wantsRecheck ? await recheck() : await status()
        guard generation == refreshGeneration else { return }
        if wantsRecheck && grantPresses == pressesSeen { grantPressed = false }
        lastStatus = result
        show(result)
    }

    private func renderChecking() {
        checkButton?.button.isEnabled = rechecksInFlight == 0
        accessibilityLine?.text = rechecksInFlight > 0 ? "Checking…" : Self.accessibilityText(lastStatus)
    }

    private func show(_ status: WorkTrackingStatus?) {
        if rechecksInFlight == 0 { accessibilityLine?.text = Self.accessibilityText(status) }
        degradedLine?.isHidden = !(status?.isDegraded ?? false)
        if let text = Self.failureText(status) {
            failureLine?.text = text
            failureLine?.isHidden = false
        } else {
            failureLine?.isHidden = true
        }
    }

    private func apply(toggling bundleId: String, on: Bool) {
        write(Self.toggling(bundleId, on: on, in: settings.preferences))
    }

    private func addTapped() {
        guard let chosen = chooseApp() else { return }
        chosenNames[chosen.bundleId] = chosen.name
        write(Self.adding(chosen.bundleId, to: settings.preferences))
    }

    /// Writes the app lists through the settings, then rereads the normalized
    /// result into the table.
    private func write(_ prefs: WorkTrackingPreferences) {
        settings.addedBundleIds.value = prefs.addedBundleIds
        settings.removedBundleIds.value = prefs.removedBundleIds
        reloadRows()
    }

    private func reloadRows() {
        let rows = Self.rows(preferences: settings.preferences).map { entry in
            ComposableSettings.EditableTableRow(id: entry.app.bundleId, cells: [
                "track": .toggle(entry.checked),
                "app": .text(displayName(entry.app))
            ])
        }
        appsCard?.setRows(rows)
    }

    /// Defaults carry names; an added app is known only by bundle id, so show
    /// the name it was chosen with, or the installed app's, else the id.
    private func displayName(_ app: TrackedApp) -> String {
        guard app.name == app.bundleId else { return app.name }
        if let name = chosenNames[app.bundleId] { return name }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) {
            let name = FileManager.default.displayName(atPath: url.path)
            return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
        }
        return app.bundleId
    }

    // MARK: - Test seams

    func refreshForTesting() async { await refresh() }
    func checkAgainForTesting() async { await checkAgain() }
    func grantPressedForTesting() { grantTapped() }
    var accessibilityLineTextForTesting: String { accessibilityLine?.text ?? "" }
    var degradedLineHiddenForTesting: Bool { degradedLine?.isHidden ?? true }
    var failureLineHiddenForTesting: Bool { failureLine?.isHidden ?? true }
    var failureLineTextForTesting: String { failureLine?.text ?? "" }
    var checkAgainEnabledForTesting: Bool { checkButton?.button.isEnabled ?? false }
    var appsCardForTesting: ComposableSettings.EditableTableCard? { appsCard }
}
#endif
