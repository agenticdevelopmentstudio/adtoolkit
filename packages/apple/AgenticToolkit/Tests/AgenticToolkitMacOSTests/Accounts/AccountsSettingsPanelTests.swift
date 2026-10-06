import AppKit
import Foundation
import Testing
@testable import AgenticToolkitMacOS
import AgenticToolkitCore

@MainActor
final class FakeAccount: Account {
    let id: String
    let displayName: String
    var summary = "Sign in to try it."
    var state: AccountState = .signedOut { didSet { onChange() } }
    var message: String? { didSet { onChange() } }
    var signupURL: URL? = URL(string: "https://example.com/signup")
    var onChange: @MainActor () -> Void = {}
    var presentCount = 0
    var lastAnchor: AnyObject?
    var signOutCount = 0

    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }

    func presentSignIn(from anchor: AccountPresentationAnchor) {
        presentCount += 1
        lastAnchor = anchor.object
    }

    func signOut() async { signOutCount += 1 }
}

@Suite("AccountsSettingsPanelViewController")
@MainActor
struct AccountsSettingsPanelTests {
    private func makePanel(_ accounts: [FakeAccount]) -> AccountsSettingsPanelViewController {
        let panel = AccountsSettingsPanelViewController(registry: AccountRegistry(accounts: accounts))
        _ = panel.view
        return panel
    }

    @Test("titles itself Accounts")
    func title() {
        let panel = makePanel([])
        #expect(panel.descriptor.title == "Accounts")
        #expect(panel.sidebarTitle == "Accounts")
    }

    @Test("one sub-panel per account, in registry order")
    func subPanels() {
        let panel = makePanel([FakeAccount(id: "a", displayName: "Alpha"), FakeAccount(id: "b", displayName: "Beta")])
        #expect(panel.accountNames == ["Alpha", "Beta"])
    }

    @Test("selectAccount(named:) selects a known account and refuses an unknown one")
    func select() {
        let panel = makePanel([FakeAccount(id: "a", displayName: "Alpha"), FakeAccount(id: "b", displayName: "Beta")])
        #expect(panel.selectAccount(named: "Beta"))
        #expect(panel.selectedPanel?.descriptor.title == "Beta")
        #expect(!panel.selectAccount(named: "Nope"))
    }

    @Test("both footer buttons are disabled")
    func footerDisabled() {
        let panel = makePanel([FakeAccount(id: "a", displayName: "Alpha")])
        #expect(panel.footer.addButton.isEnabled == false)
        #expect(panel.footer.removeButton.isEnabled == false)
        #expect(panel.footer.addButton.toolTip == "Adding accounts is not available yet")
        #expect(panel.footer.removeButton.toolTip == "Removing accounts is not available yet")
    }

    @Test("a registry change rebuilds and reuses existing sub-panels by id")
    func rebuild() {
        let alpha = FakeAccount(id: "a", displayName: "Alpha")
        let registry = AccountRegistry(accounts: [alpha])
        let panel = AccountsSettingsPanelViewController(registry: registry)
        _ = panel.view
        let before = panel.panels.first as AnyObject
        registry.add(FakeAccount(id: "b", displayName: "Beta"))
        #expect(panel.accountNames == ["Alpha", "Beta"])
        #expect(panel.panels.first as AnyObject === before)
    }

    @Test("search keywords include each account's name")
    func keywords() {
        let panel = makePanel([FakeAccount(id: "a", displayName: "Alpha")])
        #expect(panel.searchKeywords.contains("Alpha"))
        #expect(panel.searchKeywords.contains("sign in"))
    }
}

@Suite("AccountDetailPanelViewController")
@MainActor
struct AccountDetailPanelTests {
    private func makeDetail(
        _ account: FakeAccount,
        opened: ((URL) -> Void)? = nil
    ) -> AccountDetailPanelViewController {
        let detail = AccountDetailPanelViewController(account: account, openURL: { opened?($0) })
        _ = detail.view
        return detail
    }

    @Test("restoring shows the spinner and status, no buttons")
    func restoring() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        account.state = .restoring
        let detail = makeDetail(account)
        #expect(!detail.statusLabel.isHidden)
        #expect(detail.statusLabel.stringValue == "Checking sign-in…")
        #expect(detail.loginButton.isHidden && detail.signupButton.isHidden && detail.logoutButton.isHidden)
    }

    @Test("signed out shows summary, Login and Signup")
    func signedOut() {
        let detail = makeDetail(FakeAccount(id: "a", displayName: "Alpha"))
        #expect(detail.summaryLabel.stringValue == "Sign in to try it.")
        #expect(!detail.loginButton.isHidden && detail.loginButton.isEnabled)
        #expect(!detail.signupButton.isHidden && detail.signupButton.isEnabled)
        #expect(detail.logoutButton.isHidden)
        #expect(detail.nameLabel.isHidden)
    }

    @Test("signed out with no signup URL hides Signup")
    func noSignup() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        account.signupURL = nil
        let detail = makeDetail(account)
        #expect(detail.signupButton.isHidden)
    }

    @Test("signed in shows avatar, name, email and Logout")
    func signedIn() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        account.state = .signedIn(AccountUser(id: "u", name: "Ada Lovelace", email: "ada@x.y", avatarURL: nil))
        let detail = makeDetail(account)
        #expect(detail.nameLabel.stringValue == "Ada Lovelace")
        #expect(detail.emailLabel.stringValue == "ada@x.y")
        #expect(detail.avatarView.user?.initials == "AL")
        #expect(!detail.logoutButton.isHidden)
        #expect(detail.loginButton.isHidden && detail.signupButton.isHidden)
    }

    @Test("signed in then busy keeps the user showing, Logout disabled")
    func signedInThenBusy() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        account.state = .signedIn(AccountUser(id: "u", name: "Ada Lovelace", email: "ada@x.y", avatarURL: nil))
        let detail = makeDetail(account)
        account.state = .busy
        #expect(!detail.nameLabel.isHidden)
        #expect(detail.nameLabel.stringValue == "Ada Lovelace")
        #expect(!detail.logoutButton.isHidden)
        #expect(!detail.logoutButton.isEnabled)
    }

    @Test("busy then signed out clears the identity")
    func busyThenSignedOut() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        account.state = .signedIn(AccountUser(id: "u", name: "Ada Lovelace", email: "ada@x.y", avatarURL: nil))
        let detail = makeDetail(account)
        account.state = .busy
        account.state = .signedOut
        #expect(!detail.loginButton.isHidden)
        #expect(detail.nameLabel.isHidden)
        #expect(detail.avatarView.user == nil)
    }

    @Test("busy disables every button and shows the spinner")
    func busy() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        let detail = makeDetail(account)
        account.state = .busy
        #expect(!detail.loginButton.isEnabled && !detail.signupButton.isEnabled && !detail.logoutButton.isEnabled)
        #expect(!detail.spinner.isHidden)
    }

    @Test("message shows when set and hides when cleared")
    func message() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        let detail = makeDetail(account)
        #expect(detail.messageLabel.isHidden)
        account.message = "Something went wrong."
        #expect(!detail.messageLabel.isHidden)
        #expect(detail.messageLabel.stringValue == "Something went wrong.")
        account.message = nil
        #expect(detail.messageLabel.isHidden)
    }

    @Test("Login asks the account to present its sign-in")
    func login() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        let detail = makeDetail(account)
        detail.login()
        #expect(account.presentCount == 1)
        #expect(account.lastAnchor != nil)
    }

    @Test("Signup opens the signup URL")
    func signup() {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        var opened: URL?
        let detail = makeDetail(account, opened: { opened = $0 })
        detail.signup()
        #expect(opened == account.signupURL)
    }

    @Test("Logout signs the account out")
    func logout() async {
        let account = FakeAccount(id: "a", displayName: "Alpha")
        account.state = .signedIn(AccountUser(id: "u", name: "A", email: "a@b.c", avatarURL: nil))
        let detail = makeDetail(account)
        await detail.logout()
        #expect(account.signOutCount == 1)
    }
}
