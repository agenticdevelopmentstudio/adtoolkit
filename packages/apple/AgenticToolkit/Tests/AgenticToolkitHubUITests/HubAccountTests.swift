import AgenticDeveloperToolkit
import AgenticToolkitHubService
@testable import AgenticToolkitHubUI
import Foundation
import Testing

@MainActor
private final class FakeSession: SignInSession {
    var state: SessionState = .signedOut { didSet { onChange(state) } }
    var onChange: @MainActor (SessionState) -> Void = { _ in }
    var signOutCount = 0
    var stateDuringSignOut: AccountState?
    weak var account: HubAccount?

    func signIn(email: String, password: String) async throws -> SignInStep { .done(StubSignInSession.sampleUser) }
    func completeMfa(challenge: MfaChallengeInfo, method: MfaChallengeMethod, code: String) async throws -> HubUser {
        StubSignInSession.sampleUser
    }
    func sendMfaSms(challenge: MfaChallengeInfo) async throws {}
    func signInWithPasskey(identifier: String, provider: any PasskeyAssertionProvider) async throws -> HubUser {
        StubSignInSession.sampleUser
    }
    func completeMfaWithPasskey(
        challenge: MfaChallengeInfo,
        provider: any PasskeyAssertionProvider
    ) async throws -> HubUser {
        StubSignInSession.sampleUser
    }
    func signInWithSocial(
        _ provider: SocialProvider,
        using session: any SocialSignInProvider
    ) async throws -> HubUser {
        StubSignInSession.sampleUser
    }
    func signOut() async {
        signOutCount += 1
        stateDuringSignOut = account?.state
        state = .signedOut
    }
}

private let adaAvatar = URL(string: "https://x.y/a.png")
private let ada = HubUser(id: "u1", email: "ada@x.y", name: "Ada Lovelace", slug: "ada", avatarURL: adaAvatar)

@Suite("HubAccount")
@MainActor
struct HubAccountTests {
    private func make(
        _ session: FakeSession,
        presenter: @escaping HubSignInPresenter = { _, _, _ in true }
    ) -> HubAccount {
        let account = HubAccount(session: session, presenter: presenter)
        session.account = account
        return account
    }

    @Test("identity and copy")
    func identity() {
        let account = make(FakeSession())
        #expect(account.id == "agentic-developer-hub")
        #expect(account.displayName == "Agentic Developer Hub")
        #expect(account.summary == "Sign in to connect this app to your Agentic Developer Hub account.")
        #expect(account.signupURL == HubLinks.url(path: "signup"))
    }

    @Test("maps every session state")
    func mapping() {
        let session = FakeSession()
        let account = make(session)
        session.state = .restoring
        #expect(account.state == .restoring)
        session.state = .signedIn(ada)
        let expected = AccountUser(id: "u1", name: "Ada Lovelace", email: "ada@x.y", avatarURL: adaAvatar)
        #expect(account.state == .signedIn(expected))
        #expect(account.message == nil)
        session.state = .error("Network down")
        #expect(account.state == .signedOut)
        #expect(account.message == "Network down")
        session.state = .signedOut
        #expect(account.state == .signedOut)
        #expect(account.message == nil)
    }

    @Test("reads the session's state at init")
    func initialState() {
        let session = FakeSession()
        session.state = .signedIn(ada)
        let account = make(session)
        if case .signedIn = account.state {} else { Issue.record("expected signedIn, got \(account.state)") }
    }

    @Test("a blank name falls back to slug, then email local-part")
    func nameFallback() {
        let slugOnly = HubUser(id: "1", email: "z@x.y", name: " ", slug: "zed", avatarURL: nil)
        let emailOnly = HubUser(id: "2", email: "zoe@x.y", name: "", slug: nil, avatarURL: nil)
        #expect(AccountUser(slugOnly).name == "zed")
        #expect(AccountUser(emailOnly).name == "zoe")
    }

    @Test("onChange fires on a session change")
    func onChangeFires() {
        let session = FakeSession()
        let account = make(session)
        var count = 0
        account.onChange = { count += 1 }
        session.state = .signedIn(ada)
        #expect(count == 1)
    }

    @Test("keeps a prior session observer working")
    func chaining() {
        let session = FakeSession()
        var prior: [SessionState] = []
        session.onChange = { prior.append($0) }
        _ = make(session)
        session.state = .signedIn(ada)
        #expect(prior == [.signedIn(ada)])
    }

    @Test("signOut is busy while the session signs out, then signed out")
    func signOutBusy() async {
        let session = FakeSession()
        session.state = .signedIn(ada)
        let account = make(session)
        await account.signOut()
        #expect(session.signOutCount == 1)
        #expect(session.stateDuringSignOut == .busy)
        #expect(account.state == .signedOut)
    }

    @Test("a second presentSignIn while a sheet is up is ignored")
    func singleSheet() {
        var calls = 0
        let account = make(FakeSession(), presenter: { _, _, _ in calls += 1; return true })
        let anchor = AccountPresentationAnchor(NSObject())
        account.presentSignIn(from: anchor)
        account.presentSignIn(from: anchor)
        #expect(calls == 1)
    }

    @Test("closing the sheet lets Login present again")
    func reopenAfterClose() {
        var calls = 0
        var close: (@MainActor () -> Void)?
        let account = make(FakeSession(), presenter: { _, _, onClose in calls += 1; close = onClose; return true })
        let anchor = AccountPresentationAnchor(NSObject())
        account.presentSignIn(from: anchor)
        close?()
        account.presentSignIn(from: anchor)
        #expect(calls == 2)
    }

    @Test("an onClose fired synchronously does not leave the latch stuck")
    func synchronousCloseDoesNotLatch() {
        var calls = 0
        let account = make(FakeSession(), presenter: { _, _, onClose in calls += 1; onClose(); return true })
        let anchor = AccountPresentationAnchor(NSObject())
        account.presentSignIn(from: anchor)
        account.presentSignIn(from: anchor)
        #expect(calls == 2)
    }

    @Test("a presenter that cannot present does not latch")
    func failedPresentDoesNotLatch() {
        var calls = 0
        let account = make(FakeSession(), presenter: { _, _, _ in calls += 1; return false })
        let anchor = AccountPresentationAnchor(NSObject())
        account.presentSignIn(from: anchor)
        account.presentSignIn(from: anchor)
        #expect(calls == 2)
    }
}
