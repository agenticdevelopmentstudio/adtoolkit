import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS
import os

/// One account's detail: who is signed in, or how to sign in. Renders
/// entirely from `account`; keeps no copy of its state.
@MainActor
final class AccountDetailPanelViewController: ComposableSettings.SettingsPanelViewController {
    static let restoringText = "Checking sign-in…"
    private static let log = Logger(subsystem: "com.agentic-cookbook.toolkit", category: "accounts")

    let account: any Account
    private let openURL: @MainActor (URL) -> Void

    let summaryLabel = ThemedLabel.wrapping("", width: 360, role: .secondaryText, textRole: .body)
    let statusLabel = ThemedLabel(string: restoringText, role: .secondaryText, textRole: .body)
    let spinner = NSProgressIndicator()
    let avatarView = AccountAvatarView()
    let nameLabel = ThemedLabel(role: .primaryText, textRole: .title)
    let emailLabel = ThemedLabel(role: .secondaryText, textRole: .body)
    let messageLabel = ThemedLabel.wrapping("", width: 360, role: .danger, textRole: .caption)
    private(set) lazy var loginButton = ThemedActionButton(
        title: "Login", style: .primary, target: self, action: #selector(loginPressed))
    private(set) lazy var signupButton = ThemedActionButton(
        title: "Signup", style: .secondary, target: self, action: #selector(signupPressed))
    private(set) lazy var logoutButton = ThemedActionButton(
        title: "Logout", style: .secondary, target: self, action: #selector(logoutPressed))

    private lazy var identityRow = NSStackView(views: [avatarView, NSStackView(views: [nameLabel, emailLabel])])
    private lazy var statusRow = NSStackView(views: [spinner, statusLabel])

    /// The user shown before a `busy` began, so signing out keeps showing
    /// who is signing out rather than flashing the signed-out controls.
    private var lastUser: AccountUser?

    init(account: any Account, openURL: @escaping @MainActor (URL) -> Void = { _ = NSWorkspace.shared.open($0) }) {
        self.account = account
        self.openURL = openURL
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: account.displayName,
            icon: NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var searchKeywords: [String] {
        ["account", "login", "sign in", "sign up", "logout", account.displayName]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        summaryLabel.setAccessibilityIdentifier("accounts.detail.summary")
        nameLabel.setAccessibilityIdentifier("accounts.detail.name")
        emailLabel.setAccessibilityIdentifier("accounts.detail.email")
        messageLabel.setAccessibilityIdentifier("accounts.detail.message")
        spinner.setAccessibilityIdentifier("accounts.detail.spinner")
        loginButton.setAccessibilityIdentifier("accounts.detail.login")
        signupButton.setAccessibilityIdentifier("accounts.detail.signup")
        logoutButton.setAccessibilityIdentifier("accounts.detail.logout")
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false

        if let nameColumn = identityRow.arrangedSubviews.last as? NSStackView {
            nameColumn.orientation = .vertical
            nameColumn.alignment = .leading
            nameColumn.spacing = 2
        }
        identityRow.orientation = .horizontal
        identityRow.alignment = .centerY
        identityRow.spacing = 12
        statusRow.orientation = .horizontal
        statusRow.spacing = 8

        let buttons = NSStackView(views: [loginButton, signupButton, logoutButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        let column = NSStackView(views: [identityRow, summaryLabel, statusRow, buttons, messageLabel])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 12
        column.translatesAutoresizingMaskIntoConstraints = false

        // One row holds the whole column so hiding parts never leaves an
        // orphaned row separator behind.
        let group = ComposableSettings.GroupView(withTitle: "Account")
        group.addSettingSubview(column)
        addGroup(group)

        account.onChange = { [weak self] in self?.render() }
        render()
    }

    // MARK: Rendering

    private func render() {
        let state = account.state
        let busy = state == .busy
        var signedInUser: AccountUser?
        if case .signedIn(let user) = state { signedInUser = user }
        let restoring = state == .restoring
        let signedOutLike = state == .signedOut || (busy && signedInUser == nil && lastUser == nil)

        if let signedInUser { lastUser = signedInUser } else if !busy { lastUser = nil }
        let shownUser = signedInUser ?? (busy ? lastUser : nil)

        identityRow.isHidden = shownUser == nil
        avatarView.user = shownUser
        nameLabel.isHidden = shownUser == nil
        nameLabel.stringValue = shownUser?.name ?? ""
        emailLabel.stringValue = shownUser?.email ?? ""

        summaryLabel.stringValue = account.summary
        summaryLabel.isHidden = !signedOutLike
        statusLabel.isHidden = !restoring
        statusRow.isHidden = !(restoring || busy)
        if restoring || busy { spinner.startAnimation(nil) } else { spinner.stopAnimation(nil) }
        spinner.isHidden = !(restoring || busy)

        loginButton.isHidden = !signedOutLike
        signupButton.isHidden = !signedOutLike || account.signupURL == nil
        logoutButton.isHidden = shownUser == nil
        for button in [loginButton, signupButton, logoutButton] { button.isEnabled = !busy }

        messageLabel.stringValue = account.message ?? ""
        messageLabel.isHidden = account.message == nil
    }

    // MARK: Actions

    func login() {
        let anchorObject: AnyObject = view.window ?? self
        account.presentSignIn(from: AccountPresentationAnchor(anchorObject))
    }

    func signup() {
        guard let url = account.signupURL else {
            Self.log.error("signup pressed with no signup URL for \(self.account.id, privacy: .public)")
            return
        }
        openURL(url)
    }

    func logout() async {
        await account.signOut()
    }

    @objc private func loginPressed() { login() }
    @objc private func signupPressed() { signup() }
    @objc private func logoutPressed() { Task { await logout() } }
}
