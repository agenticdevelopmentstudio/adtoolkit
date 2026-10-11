import Foundation

/// An in-memory `SignInSession` for apps that show sign-in UI before it is
/// wired to the backend. Any non-empty credentials sign in as `sampleUser`;
/// passkey, social and web sign in without touching their providers, so no system
/// sheet or browser opens. Nothing is persisted.
@MainActor
public final class StubSignInSession: SignInSession {
    public enum StubError: LocalizedError, Equatable {
        case emptyCredentials
        public var errorDescription: String? { "Enter your email and password." }
    }

    public static let sampleUser = HubUser(
        id: "sample-user",
        email: "sample@agenticdeveloperhub.com",
        name: "Sample User",
        slug: nil,
        avatarURL: nil
    )

    public private(set) var state: SessionState = .signedOut {
        didSet { if state != oldValue { onChange(state) } }
    }
    public var onChange: @MainActor (SessionState) -> Void = { _ in }

    private let delay: Duration

    public init(delay: Duration = .milliseconds(400)) {
        self.delay = delay
    }

    public func signIn(email: String, password: String) async throws -> SignInStep {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else {
            throw StubError.emptyCredentials
        }
        return .done(try await signInSample())
    }

    public func completeMfa(
        challenge: MfaChallengeInfo,
        method: MfaChallengeMethod,
        code: String
    ) async throws -> HubUser {
        try await signInSample()
    }

    public func sendMfaSms(challenge: MfaChallengeInfo) async throws {}

    public func signInWithPasskey(
        identifier: String,
        provider: any PasskeyAssertionProvider
    ) async throws -> HubUser {
        try await signInSample()
    }

    public func completeMfaWithPasskey(
        challenge: MfaChallengeInfo,
        provider: any PasskeyAssertionProvider
    ) async throws -> HubUser {
        try await signInSample()
    }

    public func signInWithSocial(
        _ provider: SocialProvider,
        using session: any SocialSignInProvider
    ) async throws -> HubUser {
        try await signInSample()
    }

    public func signInWithWeb(using session: any SocialSignInProvider) async throws -> HubUser {
        try await signInSample()
    }

    /// The stub keeps no stored session: anything but signed in restores to
    /// signed out.
    public func restore() async {
        if case .signedIn = state { return }
        state = .signedOut
    }

    public func signOut() async {
        state = .signedOut
    }

    private func signInSample() async throws -> HubUser {
        if delay > .zero { try await Task.sleep(for: delay) }
        // A cancelled sign-in must never land as signed in, even when the
        // cancel arrived as the delay ended.
        try Task.checkCancellation()
        state = .signedIn(Self.sampleUser)
        return Self.sampleUser
    }
}
