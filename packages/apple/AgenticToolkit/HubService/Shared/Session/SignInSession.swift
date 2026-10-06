import Foundation

/// The sign-in verbs the sign-in screen and `HubAccount` use, so they run
/// over the live `SessionController` or over `StubSignInSession` alike.
/// Signatures are `SessionController`'s own.
@MainActor
public protocol SignInSession: AnyObject {
    var state: SessionState { get }
    var onChange: @MainActor (SessionState) -> Void { get set }

    func signIn(email: String, password: String) async throws -> SignInStep
    func completeMfa(challenge: MfaChallengeInfo, method: MfaChallengeMethod, code: String) async throws -> HubUser
    func sendMfaSms(challenge: MfaChallengeInfo) async throws
    func signInWithPasskey(identifier: String, provider: any PasskeyAssertionProvider) async throws -> HubUser
    func completeMfaWithPasskey(
        challenge: MfaChallengeInfo,
        provider: any PasskeyAssertionProvider
    ) async throws -> HubUser
    func signInWithSocial(_ provider: SocialProvider, using session: any SocialSignInProvider) async throws -> HubUser
    func signOut() async
}

extension SessionController: SignInSession {}
