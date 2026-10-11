import HTTPTypes
import OpenAPIRuntime
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubClient

@Suite("Session sign-in wrappers")
struct SessionWrappersTests {

    private static let authJSON = #"{"refreshToken":"r-1","token":"jwt-1","user":{"avatarUrl":"","capabilities":[],"email":"a@b.c","id":"u1","name":"A","profileVisibility":"private","publicProfileEnabled":false,"slug":null}}"#
    private static let mfaJSON = #"{"mfaRequired":true,"token":"mfa-tok","methods":["totp","sms"]}"#
    private static let userJSON = #"{"avatarUrl":"","capabilities":["x"],"email":"a@b.c","id":"u1","name":"A","profileVisibility":"private","publicProfileEnabled":false,"slug":null}"#

    private func makeClient(
        store: InMemorySessionStore = InMemorySessionStore(),
        route: @escaping @Sendable (HTTPRequest) -> (HTTPResponse.Status, String)
    ) -> (ADHClient, MockClientTransport) {
        let mock = MockClientTransport { request in
            let (status, json) = route(request)
            var response = HTTPResponse(status: status)
            response.headerFields[.contentType] = "application/json"
            return (response, HTTPBody(Data(json.utf8)))
        }
        return (ADHClient(transport: .direct(transport: mock), session: store), mock)
    }

    @Test("signIn with a password stores the session and returns the user")
    func signInPassword() async throws {
        let store = InMemorySessionStore()
        let (adh, _) = makeClient(store: store) { _ in (.ok, Self.authJSON) }

        let outcome = try await adh.signIn(email: "a@b.c", password: "pw")

        guard case .signedIn(let user) = outcome else { Issue.record("expected signedIn"); return }
        #expect(user.id == "u1")
        #expect(store.currentSession() == Session(credentials: Credentials(token: "jwt-1", kind: .jwt), refreshToken: "r-1"))
    }

    @Test("signIn sends what the user typed as `identifier`, never `email`")
    func signInSendsIdentifier() async throws {
        let (adh, mock) = makeClient { _ in (.ok, Self.authJSON) }

        _ = try await adh.signIn(email: "mike", password: "pw")

        let body = try #require(mock.lastBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json["identifier"] == "mike")
        #expect(json["email"] == nil)
    }

    @Test("signIn surfaces an MFA challenge without storing anything")
    func signInMfaChallenge() async throws {
        let store = InMemorySessionStore()
        let (adh, _) = makeClient(store: store) { _ in (.accepted, Self.mfaJSON) }

        let outcome = try await adh.signIn(email: "a@b.c", password: "pw")

        guard case .mfaRequired(let challenge) = outcome else { Issue.record("expected mfaRequired"); return }
        #expect(challenge.token == "mfa-tok")
        #expect(store.currentSession() == nil)
    }

    @Test("signIn maps 401 to invalidCredentials")
    func signInInvalid() async throws {
        let (adh, _) = makeClient { _ in (.unauthorized, #"{"error":{"message":"invalid credentials"}}"#) }

        await #expect(throws: SessionError.invalidCredentials) {
            try await adh.signIn(email: "a@b.c", password: "wrong")
        }
    }

    @Test("completeMfa posts token/method/code and stores the session")
    func completeMfa() async throws {
        let store = InMemorySessionStore()
        let (adh, mock) = makeClient(store: store) { _ in (.ok, Self.authJSON) }

        let user = try await adh.completeMfa(challengeToken: "mfa-tok", method: .totp, code: "123456")

        #expect(user.id == "u1")
        #expect(mock.lastRequest?.path == "/auth/login/mfa")
        #expect(store.currentSession()?.refreshToken == "r-1")
    }

    @Test("sendMfaSms posts the challenge token")
    func sendMfaSms() async throws {
        let (adh, mock) = makeClient { _ in (.accepted, #"{"ok":true}"#) }

        try await adh.sendMfaSms(challengeToken: "mfa-tok")

        #expect(mock.lastRequest?.path == "/auth/login/mfa/sms/send")
    }

    @Test("passkeyOptions returns the challenge token and the raw options object")
    func passkeyOptions() async throws {
        let (adh, mock) = makeClient { _ in
            (.ok, #"{"token":"pk-tok","options":{"challenge":"abc","rpId":"agenticdeveloperhub.com"}}"#)
        }

        let result = try await adh.passkeyOptions(identifier: "a@b.c")

        #expect(mock.lastRequest?.path == "/auth/login/webauthn/options")
        #expect(result.token == "pk-tok")
        #expect(result.options.value["challenge"] as? String == "abc")
    }

    @Test("completePasskey stores the session")
    func completePasskey() async throws {
        let store = InMemorySessionStore()
        let (adh, mock) = makeClient(store: store) { _ in (.ok, Self.authJSON) }

        let user = try await adh.completePasskey(
            challengeToken: "pk-tok",
            response: try OpenAPIObjectContainer(unvalidatedValue: ["id": "cred-1", "rawId": "cred-1", "type": "public-key"])
        )

        #expect(user.id == "u1")
        #expect(mock.lastRequest?.path == "/auth/login/webauthn")
        #expect(store.currentSession()?.credentials.token == "jwt-1")
    }

    @Test("mfaPasskeyOptions returns the rotated challenge token and raw options")
    func mfaPasskeyOptions() async throws {
        let (adh, mock) = makeClient { _ in (.ok, #"{"token":"mfa-tok-2","options":{"challenge":"abc","rpId":"agenticdeveloperhub.com"}}"#) }

        let result = try await adh.mfaPasskeyOptions(challengeToken: "mfa-tok")

        #expect(mock.lastRequest?.path == "/auth/login/mfa/webauthn/options")
        #expect(result.token == "mfa-tok-2")
        #expect(result.options.value["challenge"] as? String == "abc")
    }

    @Test("completeMfaPasskey stores the session")
    func completeMfaPasskey() async throws {
        let store = InMemorySessionStore()
        let (adh, mock) = makeClient(store: store) { _ in (.ok, Self.authJSON) }

        let user = try await adh.completeMfaPasskey(
            challengeToken: "mfa-tok-2",
            response: try OpenAPIObjectContainer(unvalidatedValue: ["id": "cred-1", "rawId": "cred-1", "type": "public-key"])
        )

        #expect(user.id == "u1")
        #expect(mock.lastRequest?.path == "/auth/login/mfa/webauthn")
        #expect(store.currentSession()?.credentials.token == "jwt-1")
    }

    @Test("exchangeOAuthCode stores the session")
    func exchangeOAuthCode() async throws {
        let store = InMemorySessionStore()
        let (adh, mock) = makeClient(store: store) { _ in (.ok, Self.authJSON) }

        let user = try await adh.exchangeOAuthCode("code-1")

        #expect(user.id == "u1")
        #expect(mock.lastRequest?.path == "/oauth/signin/exchange")
        #expect(store.currentSession()?.credentials.token == "jwt-1")
    }

    @Test("signOut revokes the refresh token and clears the store, even if revoke fails")
    func signOut() async throws {
        let store = InMemorySessionStore(Session(credentials: Credentials(token: "jwt-1", kind: .jwt), refreshToken: "r-1"))
        let (adh, mock) = makeClient(store: store) { _ in (.serviceUnavailable, "{}") }

        await adh.signOut()

        #expect(mock.lastRequest?.path == "/auth/revoke")
        // The committed `openapi.json` describes `POST /auth/revoke` as
        // bodiless, but the backend requires the refresh token in the body —
        // which is the whole reason `signOut` sends it through `rawJSON`. A
        // revoke without this body is a silent no-op server-side, so assert
        // the body, not just the path.
        #expect(mock.lastBody == Data(#"{"refreshToken":"r-1"}"#.utf8))
        #expect(store.currentSession() == nil)
    }

    /// The access token is usually already expired by the time the user signs
    /// out, so revoke is the request most likely to 401. Refreshing there
    /// would rotate the (single-use) refresh token and then replay revoke with
    /// the consumed one in the body — the server cannot match it, so the
    /// rotated token survives on the server while the local store is cleared.
    @Test("a 401 on revoke does not trigger a refresh")
    func signOutDoesNotRefreshOn401() async throws {
        let store = InMemorySessionStore(Session(credentials: Credentials(token: "jwt-expired", kind: .jwt), refreshToken: "r-signout"))
        let (adh, mock) = makeClient(store: store) { _ in (.unauthorized, #"{"error":{"message":"token expired"}}"#) }

        await adh.signOut()

        #expect(mock.recordedPaths == ["/auth/revoke"])
        #expect(mock.recorded.first?.operationID == ADHClient.revokeRawOperationID)
        #expect(mock.recorded.first?.body == Data(#"{"refreshToken":"r-signout"}"#.utf8))
        #expect(store.currentSession() == nil)
    }

    @Test("currentUser decodes GET /auth/me")
    func currentUser() async throws {
        let (adh, _) = makeClient(store: InMemorySessionStore(Session(credentials: Credentials(token: "jwt-1", kind: .jwt)))) { _ in (.ok, Self.userJSON) }

        let user = try await adh.currentUser()

        #expect(user.capabilities == ["x"])
    }

    @Test("wrappers refuse a credentials-only client")
    func notASessionClient() async throws {
        let adh = ADHClient(transport: .direct(transport: MockClientTransport()), credentials: InMemoryCredentialStore())

        await #expect(throws: SessionError.notASessionClient) {
            try await adh.signIn(email: "a@b.c", password: "pw")
        }
    }
}
