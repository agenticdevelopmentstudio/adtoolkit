import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreUI

/// A popup of the daemon's saved LLM provider configurations, led by the
/// caller's sentinel choices, bound to a `UserSetting<String>` holding the
/// chosen value (a configuration id, or a sentinel's value).
///
/// The registry is the daemon's — the one Stenographer's LLM Providers pane
/// pushed — not this process's plugin manager, which is why this is not the
/// toolkit's `LLMPickerView`. There is no model row: the model is the daemon
/// configuration's own. The list is read from the daemon at init and again each
/// time the menu is about to open, not pushed live, and the selection follows the
/// bound setting across a reload.
@MainActor
public final class DaemonProviderPickerView: NSView {

    public struct LeadingChoice: Sendable {
        public let label: String
        public let value: String
        public init(label: String, value: String) {
            self.label = label
            self.value = value
        }
    }

    private let service: any StenographerDaemonService
    private let selectedSetting: UserSetting<String>
    private let leadingChoices: [LeadingChoice]
    private let titleLabel = NSTextField(labelWithString: "Provider")
    private let popup = NSPopUpButton(frame: .zero, pullsDown: false)
    private var observer: UserSettingObserver<String>?
    public private(set) var choices: [(label: String, value: String)] = []

    public init(
        service: any StenographerDaemonService,
        selectedSetting: UserSetting<String>,
        leadingChoices: [LeadingChoice]
    ) {
        self.service = service
        self.selectedSetting = selectedSetting
        self.leadingChoices = leadingChoices
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.target = self
        popup.action = #selector(popupChanged)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        addSubview(popup)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            popup.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            popup.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            popup.topAnchor.constraint(equalTo: topAnchor),
            popup.bottomAnchor.constraint(equalTo: bottomAnchor),
            popup.widthAnchor.constraint(greaterThanOrEqualToConstant: 220)
        ])

        rebuildMenu(configs: [])
        observer = UserSettingObserver(selectedSetting) { [weak self] _ in self?.syncSelection() }
        // Load now, and again every time the menu is about to open, so a daemon that was
        // not up (or was migrating) at init, or a configuration added later, still appears.
        NotificationCenter.default.addObserver(
            self, selector: #selector(menuWillOpen), name: NSPopUpButton.willPopUpNotification, object: popup)
        Task { [weak self] in await self?.reload() }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func menuWillOpen() {
        Task { [weak self] in await self?.reload() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Re-reads the daemon's configurations; an unreachable daemon keeps the menu as is.
    /// The menu is rebuilt (keeping the selected value) only when the list changed.
    public func reload() async {
        guard let configs = await service.aiProviderConfigs() else { return }
        let fresh = Self.menuChoices(leading: leadingChoices, configs: configs)
        guard fresh.map(\.value) != choices.map(\.value) || fresh.map(\.label) != choices.map(\.label) else { return }
        rebuildMenu(configs: configs)
    }

    /// Sentinels first, in the caller's order, then the configurations by name.
    public nonisolated static func menuChoices(
        leading: [LeadingChoice], configs: [DaemonProviderConfig]
    ) -> [(label: String, value: String)] {
        leading.map { ($0.label, $0.value) }
            + configs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                .map { ($0.name, $0.id.uuidString) }
    }

    /// Test seam for a user pick.
    func selectChoice(at index: Int) {
        popup.selectItem(at: index)
        popupChanged()
    }

    private func rebuildMenu(configs: [DaemonProviderConfig]) {
        choices = Self.menuChoices(leading: leadingChoices, configs: configs)
        popup.removeAllItems()
        for choice in choices { popup.addItem(withTitle: choice.label) }
        syncSelection()
    }

    private func syncSelection() {
        let value = selectedSetting.value
        if let index = choices.firstIndex(where: { $0.value == value }) {
            popup.selectItem(at: index)
        } else {
            // A configuration the daemon no longer has: fall back to the first sentinel.
            popup.selectItem(at: 0)
        }
    }

    @objc private func popupChanged() {
        let index = popup.indexOfSelectedItem
        guard choices.indices.contains(index) else { return }
        let value = choices[index].value
        if selectedSetting.value != value { selectedSetting.value = value }
    }
}
