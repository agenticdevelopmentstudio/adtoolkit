import Foundation
import Testing
@testable import AgenticDeveloperToolkit

@MainActor
private final class StubAccount: Account {
    let id: String
    var displayName: String { id }
    var summary: String { "" }
    var state: AccountState = .signedOut
    var message: String?
    var signupURL: URL?
    var onChange: @MainActor () -> Void = {}
    init(id: String) { self.id = id }
    func presentSignIn(from anchor: AccountPresentationAnchor) {}
    func signOut() async {}
}

@Suite("AccountUser")
struct AccountUserTests {
    @Test("initials take the first letters of the first two words")
    func twoWords() {
        let user = AccountUser(id: "1", name: "ada lovelace byron", email: "a@b.c", avatarURL: nil)
        #expect(user.initials == "AL")
    }

    @Test("initials fall back to the email's first letter for a blank name")
    func blankName() {
        let user = AccountUser(id: "1", name: "   ", email: "zed@b.c", avatarURL: nil)
        #expect(user.initials == "Z")
    }

    @Test("initials are ? when name and email are both empty")
    func nothing() {
        let user = AccountUser(id: "1", name: "", email: "", avatarURL: nil)
        #expect(user.initials == "?")
    }
}

@Suite("AccountPresentationAnchor")
struct AccountPresentationAnchorTests {
    @Test("holds its object weakly")
    func weak() {
        var object: NSObject? = NSObject()
        let anchor = AccountPresentationAnchor(object!)
        #expect(anchor.object != nil)
        object = nil
        #expect(anchor.object == nil)
    }
}

@Suite("AccountRegistry")
@MainActor
struct AccountRegistryTests {
    @Test("keeps accounts in the order given")
    func order() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a"), StubAccount(id: "b")])
        #expect(registry.accounts.map(\.id) == ["a", "b"])
    }

    @Test("add appends and reports a change")
    func add() {
        let registry = AccountRegistry()
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.add(StubAccount(id: "a"))
        #expect(registry.accounts.map(\.id) == ["a"])
        #expect(changes == 1)
    }

    @Test("add ignores an id already present and reports nothing")
    func addDuplicate() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a")])
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.add(StubAccount(id: "a"))
        #expect(registry.accounts.count == 1)
        #expect(changes == 0)
    }

    @Test("remove drops the account and reports a change")
    func remove() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a"), StubAccount(id: "b")])
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.remove(id: "a")
        #expect(registry.accounts.map(\.id) == ["b"])
        #expect(changes == 1)
    }

    @Test("remove of an unknown id is a silent no-op")
    func removeUnknown() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a")])
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.remove(id: "zzz")
        #expect(registry.accounts.count == 1)
        #expect(changes == 0)
    }
}
