import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS
import AgenticToolkitCoreUI

/// The "Accounts" settings panel: one topic per account an app offers, the
/// account's sign-in detail beside it. `+`/`−` are shown but disabled until
/// adding account types is supported.
@MainActor
open class AccountsSettingsPanelViewController: ComposableSettings.SettingsPanelSplitViewController {
    public let registry: AccountRegistry
    let footer = ComposableSettings.AddRemoveFooterView(accessibilityPrefix: "accounts.add-remove")

    public init(registry: AccountRegistry) {
        self.registry = registry
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Accounts",
            icon: NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: nil)
        ))
        sidebarTitle = "Accounts"
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Accounts",
                body: "Each row is an online account this app can use. Select one to "
                    + "sign in, create an account on the web, or sign out. Signing in "
                    + "here connects this app to that account."
            )
        ])
    }

    open override var searchKeywords: [String] {
        ["account", "login", "sign in", "sign up", "logout"] + registry.accounts.map(\.displayName)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        footer.addButton.isEnabled = false
        footer.isRemoveEnabled = false
        footer.addButton.toolTip = "Adding accounts is not available yet"
        footer.removeButton.toolTip = "Removing accounts is not available yet"
        listViewController.setFooterView(makeFooter())
        listViewController.view.setAccessibilityIdentifier("accounts.list")
        registry.onChange = { [weak self] in self?.rebuildPanels() }
        rebuildPanels()
    }

    /// The footer under the list, with the hairline above it that the LLM
    /// Providers panel's footer also draws for itself.
    private func makeFooter() -> NSView {
        let separator = ThemedSeparatorView(role: .border)
        let stack = NSStackView(views: [separator, footer])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        for sub in [separator, footer] {
            sub.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        return stack
    }

    /// Matches the panels to the registry, reusing existing ones by account
    /// id so a change never discards a detail the user is looking at.
    private func rebuildPanels() {
        let previous = (selectedPanel as? AccountDetailPanelViewController)?.account.id
        let existing = Dictionary(
            panels.compactMap { ($0 as? AccountDetailPanelViewController).map { ($0.account.id, $0) } },
            uniquingKeysWith: { first, _ in first }
        )
        let rebuilt: [any ComposableSettingsPanel] = registry.accounts.map { account in
            existing[account.id] ?? AccountDetailPanelViewController(account: account)
        }
        setPanels(rebuilt)
        if let index = registry.accounts.firstIndex(where: { $0.id == previous }) {
            selectPanel(at: index)
        } else if !rebuilt.isEmpty {
            selectPanel(at: 0)
        }
    }

    // MARK: Scripted / testable selection

    /// The accounts' names, in sidebar order.
    public var accountNames: [String] {
        panels.compactMap { ($0 as? AccountDetailPanelViewController)?.descriptor.title }
    }

    /// Selects the account named `name`; `false` when there is none. The
    /// themed list does not reliably take synthetic clicks, so scripts and
    /// tests select through this.
    @discardableResult
    public func selectAccount(named name: String) -> Bool {
        guard let index = panels.firstIndex(where: { $0.descriptor.title == name }) else { return false }
        selectPanel(at: index)
        return true
    }
}
