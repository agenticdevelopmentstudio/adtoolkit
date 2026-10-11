import AgenticDeveloperToolkit
import AgenticDeveloperHubClient
import AgenticToolkitHubService
import Foundation

extension AccountUser {
    /// The hub user as an accounts UI shows them. The name follows
    /// `AccountMenuModel.avatarLabel`, the one authority for name → slug →
    /// email precedence.
    public init(_ user: HubUser) {
        self.init(
            id: user.id,
            name: AccountMenuModel.avatarLabel(name: user.name, slug: user.slug, email: user.email),
            email: user.email,
            avatarURL: user.avatarURL
        )
    }
}

/// The Agentic Developer Hub as an `Account`: maps a `SignInSession` onto
/// the generic account states and signs in on the hub's hosted login page in
/// a browser sheet — the page offers every method (password, passkey, MFA,
/// social), so the app shows no sign-in screen of its own.
@MainActor
public final class HubAccount: Account {
    public let id = "agentic-developer-hub"
    public let displayName = "Agentic Developer Hub"
    public let summary = "Sign in to connect this app to your Agentic Developer Hub account."
    public let signupURL: URL? = HubLinks.url(path: "signup")
    public private(set) var state: AccountState = .restoring
    public private(set) var message: String?
    public var onChange: @MainActor () -> Void = {}

    private let session: any SignInSession
    private let browser: any SocialSignInProvider
    private var signingIn: Task<Void, Never>?

    /// `browser` runs the hosted page's round-trip; the default opens it in
    /// an `ASWebAuthenticationSession` sheet on the key window.
    public init(session: any SignInSession, browser: any SocialSignInProvider = WebAuthSocialSignIn()) {
        self.session = session
        self.browser = browser
        // Chain, never replace: the live controller's onChange already has an
        // owner (the app coordinator), and it must keep hearing every change.
        let prior = session.onChange
        session.onChange = { [weak self] newState in
            prior(newState)
            self?.apply(newState)
        }
        apply(session.state)
    }

    /// Busy while the browser sheet is up. Closing the sheet is a cancel and
    /// says nothing; any other failure lands signed out with its message. The
    /// browser sheet finds its own window, so `anchor` is unused.
    ///
    /// A session left in `.error` still has its stored login — the hub just
    /// couldn't confirm it — so Login re-checks that first, and only opens
    /// the browser if the hub turned the login down.
    public func presentSignIn(from anchor: AccountPresentationAnchor) {
        guard signingIn == nil else { return }
        set(state: .busy, message: nil)
        signingIn = Task { [weak self] in
            guard let self else { return }
            if case .error = session.state {
                await session.restore()
                guard session.state == .signedOut else {
                    finishSigningIn(failure: nil)
                    return
                }
            }
            do {
                _ = try await session.signInWithWeb(using: browser)
                finishSigningIn(failure: nil)
            } catch is CancellationError {
                finishSigningIn(failure: nil)
            } catch {
                finishSigningIn(failure: SessionController.userMessage(for: error))
            }
        }
    }

    private func finishSigningIn(failure: String?) {
        signingIn = nil
        // A failure never demotes a live session, so its message only shows
        // when the session is signed out.
        if let failure, session.state == .signedOut {
            set(state: .signedOut, message: failure)
        } else {
            apply(session.state)
        }
    }

    public func signOut() async {
        set(state: .busy, message: nil)
        await session.signOut()
        apply(session.state)
    }

    private func apply(_ sessionState: SessionState) {
        switch sessionState {
        case .restoring: set(state: .restoring, message: nil)
        case .signedOut: set(state: .signedOut, message: nil)
        case .signedIn(let user): set(state: .signedIn(AccountUser(user)), message: nil)
        case .error(let text): set(state: .signedOut, message: text)
        }
    }

    private func set(state newState: AccountState, message newMessage: String?) {
        guard newState != state || newMessage != message else { return }
        state = newState
        message = newMessage
        onChange()
    }
}

extension HubAccount {
    /// The hub account for an app that is not the hub app: a live
    /// `SessionController` over direct HTTPS (no adh-daemon), its session kept
    /// in the Keychain, restored straight away so the account leaves
    /// `.restoring` on its own.
    public static func live(
        sessionStore: any SessionStore = KeychainSessionStore(keyPrefix: "adh.api"),
        configuration: SignInConfiguration = .fromBundle()
    ) -> HubAccount {
        let environment = HubEnvironment.direct(sessionStore: sessionStore)
        let session = SessionController(environment: environment, configuration: configuration)
        let account = HubAccount(session: session)
        Task { await session.restore() }
        return account
    }
}
