import AgenticDeveloperHubClient
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

    /// What the next web sign-in does: succeed as `ada`, or throw.
    var webOutcome: Result<HubUser, any Error> = .success(ada)
    var webCalls = 0
    var stateDuringWeb: AccountState?
    /// When set, a web sign-in waits here until the test resumes it.
    var webGate: CheckedContinuation<Void, Never>?
    var holdsWeb = false

    func signInWithWeb(using session: any SocialSignInProvider) async throws -> HubUser {
        webCalls += 1
        stateDuringWeb = account?.state
        if holdsWeb { await withCheckedContinuation { webGate = $0 } }
        switch webOutcome {
        case .success(let user):
            state = .signedIn(user)
            return user
        case .failure(let error):
            state = .signedOut
            throw error
        }
    }

    /// What the next restore lands on.
    var restoreOutcome: SessionState = .signedOut
    var restoreCalls = 0

    func restore() async {
        restoreCalls += 1
        state = restoreOutcome
    }

    func signOut() async {
        signOutCount += 1
        stateDuringSignOut = account?.state
        state = .signedOut
    }
}

/// The fake session never hands the browser on, so this is never asked.
private struct UnusedBrowser: SocialSignInProvider {
    func authenticate(_ request: SocialSignInRequest) async throws -> SocialSignInResult {
        throw CancellationError()
    }
}

private struct Offline: LocalizedError {
    var errorDescription: String? { "The hub is unreachable." }
}

private let adaAvatar = URL(string: "https://x.y/a.png")
private let ada = HubUser(id: "u1", email: "ada@x.y", name: "Ada Lovelace", slug: "ada", avatarURL: adaAvatar)

@Suite("HubAccount")
@MainActor
struct HubAccountTests {
    private func make(_ session: FakeSession) -> HubAccount {
        let account = HubAccount(session: session, browser: UnusedBrowser())
        session.account = account
        return account
    }

    /// Lets the account's sign-in task run to completion.
    private func settle(_ account: HubAccount) async {
        for _ in 0..<50 where account.state == .busy { await Task.yield() }
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

    @Test("Login signs in on the web, busy until it lands")
    func webSignIn() async {
        let session = FakeSession()
        let account = make(session)
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        #expect(account.state == .busy)
        await settle(account)
        #expect(session.webCalls == 1)
        #expect(session.stateDuringWeb == .busy)
        let expected = AccountUser(id: "u1", name: "Ada Lovelace", email: "ada@x.y", avatarURL: adaAvatar)
        #expect(account.state == .signedIn(expected))
        #expect(account.message == nil)
    }

    @Test("closing the browser sheet returns to signed out with no message")
    func webCancelled() async {
        let session = FakeSession()
        session.webOutcome = .failure(CancellationError())
        let account = make(session)
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        await settle(account)
        #expect(account.state == .signedOut)
        #expect(account.message == nil)
    }

    @Test("a failed web sign-in shows why")
    func webFailed() async {
        let session = FakeSession()
        session.webOutcome = .failure(Offline())
        let account = make(session)
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        await settle(account)
        #expect(account.state == .signedOut)
        #expect(account.message == SessionController.browserSignInMessage(for: Offline()))
    }

    @Test("a second Login while the browser is up is ignored, then Login works again")
    func singleWebSignIn() async {
        let session = FakeSession()
        session.holdsWeb = true
        session.webOutcome = .failure(CancellationError())
        let account = make(session)
        let anchor = AccountPresentationAnchor(NSObject())
        account.presentSignIn(from: anchor)
        for _ in 0..<50 where session.webGate == nil { await Task.yield() }
        account.presentSignIn(from: anchor)
        #expect(session.webCalls == 1)
        session.webGate?.resume()
        session.webGate = nil
        await settle(account)
        session.holdsWeb = false
        account.presentSignIn(from: anchor)
        await settle(account)
        #expect(session.webCalls == 2)
    }

    @Test("Login after a failed restore re-checks the stored login, no browser")
    func loginRetriesRestore() async {
        let session = FakeSession()
        session.state = .error("The hub is unreachable.")
        session.restoreOutcome = .signedIn(ada)
        let account = make(session)
        #expect(account.message == "The hub is unreachable.")
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        await settle(account)
        #expect(session.restoreCalls == 1)
        #expect(session.webCalls == 0)
        if case .signedIn = account.state {} else { Issue.record("expected signedIn, got \(account.state)") }
    }

    @Test("a restore that still fails keeps its message and opens no browser")
    func loginRestoreStillFails() async {
        let session = FakeSession()
        session.state = .error("The hub is unreachable.")
        session.restoreOutcome = .error("Still unreachable.")
        let account = make(session)
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        await settle(account)
        #expect(session.webCalls == 0)
        #expect(account.state == .signedOut)
        #expect(account.message == "Still unreachable.")
    }

    @Test("a restore the hub turns down goes on to the web sign-in")
    func loginRestoreRejected() async {
        let session = FakeSession()
        session.state = .error("The hub is unreachable.")
        session.restoreOutcome = .signedOut
        let account = make(session)
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        await settle(account)
        #expect(session.restoreCalls == 1)
        #expect(session.webCalls == 1)
        #expect(account.state == .signedIn(AccountUser(ada)))
    }

    @Test("the default browser is private, so Sign Out leaves no web login behind")
    func defaultBrowserIsEphemeral() {
        let account = HubAccount(session: FakeSession())
        let browser = account.browser as? WebAuthSocialSignIn
        #expect(browser?.ephemeral == true)
    }

    @Test("a web sign-in the hub turns down never blames a password")
    func webRejectedNotPassword() async {
        let session = FakeSession()
        session.webOutcome = .failure(SessionError.invalidCredentials)
        let account = make(session)
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        await settle(account)
        #expect(account.message == "The hub didn't accept that sign-in. Please try again.")
    }

    @Test("a web sign-in that timed out says so")
    func webTimedOut() async {
        let session = FakeSession()
        session.webOutcome = .failure(LoopbackAuthServerError.timedOut(300))
        let account = make(session)
        account.presentSignIn(from: AccountPresentationAnchor(NSObject()))
        await settle(account)
        #expect(account.message == "The sign-in took too long and was stopped. Please try again.")
    }
}
