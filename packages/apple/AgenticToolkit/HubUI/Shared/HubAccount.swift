import AgenticDeveloperToolkit
import AgenticToolkitHubService
import Foundation

/// Shows a sign-in UI for `model` from `anchor` and calls `onClose` once it
/// is gone (signed in or cancelled). Returns `false` when it could not
/// present (the anchor resolved to nothing).
public typealias HubSignInPresenter = @MainActor (
    SignInViewModel, AccountPresentationAnchor, _ onClose: @escaping @MainActor () -> Void
) -> Bool

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
/// the generic account states and presents the hub's own sign-in screen.
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
    private let passkeys: any PasskeyAssertionProvider
    private let social: any SocialSignInProvider
    private let presenter: HubSignInPresenter
    private var isPresenting = false

    public init(
        session: any SignInSession,
        passkeys: any PasskeyAssertionProvider = PasskeyAssertion(),
        social: any SocialSignInProvider = WebAuthSocialSignIn(),
        presenter: @escaping HubSignInPresenter = HubSignInSheet.present
    ) {
        self.session = session
        self.passkeys = passkeys
        self.social = social
        self.presenter = presenter
        // Chain, never replace: the live controller's onChange already has an
        // owner (the app coordinator), and it must keep hearing every change.
        let prior = session.onChange
        session.onChange = { [weak self] newState in
            prior(newState)
            self?.apply(newState)
        }
        apply(session.state)
    }

    public func presentSignIn(from anchor: AccountPresentationAnchor) {
        guard !isPresenting else { return }
        let model = SignInViewModel(session: session, passkeys: passkeys, social: social)
        isPresenting = presenter(model, anchor) { [weak self] in self?.isPresenting = false }
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
