import AgenticToolkitHubService
import Foundation
import OpenAPIRuntime
import Testing

/// Counts calls; the stub must never make one. `@unchecked Sendable` is safe
/// here because each test owns its instance and the stub never touches it.
private final class ExplodingPasskeys: PasskeyAssertionProvider, @unchecked Sendable {
    var calls = 0
    func assert(options: OpenAPIObjectContainer) async throws -> OpenAPIObjectContainer {
        calls += 1
        throw CancellationError()
    }
}

private final class ExplodingSocial: SocialSignInProvider, @unchecked Sendable {
    var calls = 0
    func authenticate(_ request: SocialSignInRequest) async throws -> SocialSignInResult {
        calls += 1
        throw CancellationError()
    }
}

@Suite("StubSignInSession")
@MainActor
struct StubSignInSessionTests {
    @Test("starts signed out")
    func startsSignedOut() {
        #expect(StubSignInSession(delay: .zero).state == .signedOut)
    }

    @Test("signIn with credentials signs in as the sample user and reports it")
    func signIn() async throws {
        let session = StubSignInSession(delay: .zero)
        var seen: [SessionState] = []
        session.onChange = { seen.append($0) }
        let step = try await session.signIn(email: "x@y.z", password: "pw")
        #expect(step == .done(StubSignInSession.sampleUser))
        #expect(session.state == .signedIn(StubSignInSession.sampleUser))
        #expect(seen == [.signedIn(StubSignInSession.sampleUser)])
    }

    @Test("signIn rejects empty credentials and stays signed out")
    func emptyCredentials() async {
        let session = StubSignInSession(delay: .zero)
        await #expect(throws: StubSignInSession.StubError.emptyCredentials) {
            _ = try await session.signIn(email: "  ", password: "")
        }
        #expect(session.state == .signedOut)
    }

    @Test("signOut returns to signed out")
    func signOut() async throws {
        let session = StubSignInSession(delay: .zero)
        _ = try await session.signIn(email: "x@y.z", password: "pw")
        await session.signOut()
        #expect(session.state == .signedOut)
    }

    @Test("passkey sign-in never calls the provider")
    func passkeyDoesNotCallProvider() async throws {
        let session = StubSignInSession(delay: .zero)
        let passkeys = ExplodingPasskeys()
        let user = try await session.signInWithPasskey(identifier: "x", provider: passkeys)
        #expect(user == StubSignInSession.sampleUser)
        #expect(passkeys.calls == 0)
    }

    @Test("social sign-in never calls the provider")
    func socialDoesNotCallProvider() async throws {
        let session = StubSignInSession(delay: .zero)
        let social = ExplodingSocial()
        let user = try await session.signInWithSocial(.google, using: social)
        #expect(user == StubSignInSession.sampleUser)
        #expect(social.calls == 0)
    }

    @Test("SessionController satisfies SignInSession")
    func conformance() {
        let check: (SessionController) -> any SignInSession = { $0 }
        _ = check
    }
}
