import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public enum SignInOutcome: Sendable {
    case signedIn(Components.Schemas.User)
    case mfaRequired(Components.Schemas.MfaChallenge)
}

public enum MfaMethod: String, Sendable, CaseIterable {
    case sms
    case totp
    case recovery

    var payload: Operations.PostAuthLoginMfa.Input.Body.JsonPayload.MethodPayload {
        switch self {
        case .sms: .sms
        case .totp: .totp
        case .recovery: .recovery
        }
    }
}

public enum SessionError: Error, Sendable, Equatable {
    /// 401 from a sign-in route: wrong password, bad/expired code, rejected assertion.
    case invalidCredentials
    /// The client was built with `init(transport:credentials:)`; session wrappers need a `SessionStore`.
    case notASessionClient
    /// A documented-but-unexpected response (400/409/422/429 on a sign-in route); the payload is the backend's error message.
    case unexpectedResponse(String)
}

/// What `POST /auth/login/webauthn/options` and `POST /auth/login/mfa/webauthn/options`
/// return: the challenge token to send back with the assertion (for MFA the
/// backend may rotate the pending token) and the raw WebAuthn
/// `PublicKeyCredentialRequestOptionsJSON`.
public struct PasskeyOptions: Sendable {
    public let token: String
    public let options: OpenAPIObjectContainer

    public init(token: String, options: OpenAPIObjectContainer) {
        self.token = token
        self.options = options
    }
}

/// Sign-in flows for session clients. Every success path stores
/// `Session(credentials: jwt, refreshToken:)`; every 401 becomes
/// `SessionError.invalidCredentials`; other documented errors become
/// `.unexpectedResponse` carrying the backend's message.
extension ADHClient {

    private func sessionStore() throws -> any SessionStore {
        guard let session else { throw SessionError.notASessionClient }
        return session
    }

    private func adopt(_ auth: Components.Schemas.AuthResult, into store: any SessionStore) -> Components.Schemas.User {
        store.save(Session(
            credentials: Credentials(token: auth.token, kind: .jwt),
            refreshToken: auth.refreshToken
        ))
        return auth.user
    }

    /// `Components.Schemas._Error.error` is itself an optional nested payload
    /// (`{message, code}`, both optional) rather than a flat `String` — unlike
    /// what the design notes assumed. Surface `message` when present, falling
    /// back to `code`, then a generic string.
    private static func message(_ error: Components.Schemas._Error) -> String {
        error.error?.message ?? error.error?.code ?? "unknown error"
    }

    /// `email` is whatever the user typed — an email, user id or phone — and
    /// goes out as `identifier`, which the backend classifies. The legacy
    /// `email` key would pin the lookup to email only.
    public func signIn(email: String, password: String) async throws -> SignInOutcome {
        let store = try sessionStore()
        let output = try await api.postAuthLogin(body: .json(.init(identifier: email, password: password)))
        switch output {
        case .ok(let ok):
            return .signedIn(adopt(try ok.body.json, into: store))
        case .accepted(let accepted):
            return .mfaRequired(try accepted.body.json)
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    public func completeMfa(challengeToken: String, method: MfaMethod, code: String) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        let output = try await api.postAuthLoginMfa(body: .json(.init(token: challengeToken, method: method.payload, code: code)))
        switch output {
        case .ok(let ok):
            return adopt(try ok.body.json, into: store)
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .badRequest(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .conflict(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    public func sendMfaSms(challengeToken: String) async throws {
        _ = try sessionStore()
        let output = try await api.postAuthLoginMfaSmsSend(body: .json(.init(token: challengeToken)))
        switch output {
        case .accepted:
            return
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .badRequest(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .conflict(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .unprocessableContent(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .tooManyRequests(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    /// Starts a passkey sign-in: the challenge token to send to `completePasskey`
    /// plus the WebAuthn `PublicKeyCredentialRequestOptions` the platform
    /// authenticator (`ASAuthorizationPlatformPublicKeyCredentialProvider`)
    /// consumes; the options are returned raw because their shape is the
    /// WebAuthn standard's, not the hub's.
    public func passkeyOptions(identifier: String) async throws -> PasskeyOptions {
        _ = try sessionStore()
        let output = try await api.postAuthLoginWebauthnOptions(body: .json(.init(identifier: identifier)))
        switch output {
        case .ok(let ok):
            let payload = try ok.body.json
            return PasskeyOptions(token: payload.token, options: payload.options.additionalProperties)
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .unprocessableContent(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    /// `response` is the serialized `PublicKeyCredential` assertion
    /// (`id`, `rawId`, `type`, `response.{clientDataJSON,authenticatorData,signature,userHandle}` base64url).
    public func completePasskey(challengeToken: String, response: OpenAPIObjectContainer) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        let output = try await api.postAuthLoginWebauthn(
            body: .json(.init(token: challengeToken, response: .init(additionalProperties: response)))
        )
        switch output {
        case .ok(let ok):
            return adopt(try ok.body.json, into: store)
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    /// MFA step for the `webauthn` method: fetches the assertion options for
    /// the pending challenge. Send `result.token` (not the original challenge
    /// token) to `completeMfaPasskey`.
    public func mfaPasskeyOptions(challengeToken: String) async throws -> PasskeyOptions {
        _ = try sessionStore()
        let output = try await api.postAuthLoginMfaWebauthnOptions(body: .json(.init(token: challengeToken)))
        switch output {
        case .ok(let ok):
            let payload = try ok.body.json
            return PasskeyOptions(token: payload.token, options: payload.options.additionalProperties)
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .badRequest(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .unprocessableContent(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    /// Completes MFA with a platform-authenticator assertion (same `response`
    /// shape as `completePasskey`).
    public func completeMfaPasskey(challengeToken: String, response: OpenAPIObjectContainer) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        let output = try await api.postAuthLoginMfaWebauthn(
            body: .json(.init(token: challengeToken, response: .init(additionalProperties: response)))
        )
        switch output {
        case .ok(let ok):
            return adopt(try ok.body.json, into: store)
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    /// `POST /oauth/signin/exchange` — named here so the raw path below and
    /// any middleware that keys off it describe the same request.
    static let oauthExchangePath = "/oauth/signin/exchange"

    /// Redeems a browser sign-in's exchange code for a session.
    ///
    /// `userAgent` is what makes this usable from a native app. The backend's
    /// exchange store binds each code to the `User-Agent` of the client that
    /// received it (`entry.userAgent !== userAgent` → the code is consumed and
    /// refused), and the client that received it is the *browser*, not this
    /// process. A web caller redeems from that same browser and wants `nil`; a
    /// native caller captures the browser's header — the loopback sign-in flow
    /// reads it off the capture page's own request — and passes it here.
    /// Without it every native redemption 401s with a code already burned, so
    /// the retry cannot help either.
    ///
    /// The `userAgent` path goes through ``rawJSON(method:path:query:body:headers:)``
    /// rather than the generated operation: `User-Agent` is not part of the
    /// documented request, so `postOauthSigninExchange` has nowhere to put it.
    /// Both paths run the same middleware chain and store the same session.
    public func exchangeOAuthCode(_ code: String, userAgent: String? = nil) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        guard let userAgent else {
            let output = try await api.postOauthSigninExchange(body: .json(.init(code: code)))
            switch output {
            case .ok(let ok):
                return adopt(try ok.body.json, into: store)
            case .unauthorized:
                throw SessionError.invalidCredentials
            case .badRequest(let r):
                throw SessionError.unexpectedResponse(Self.message(try r.body.json))
            case .undocumented(let status, _):
                throw SessionError.unexpectedResponse("HTTP \(status)")
            }
        }
        do {
            let response = try await rawJSON(
                method: .post,
                path: Self.oauthExchangePath,
                body: try JSONEncoder().encode(["code": code]),
                headers: ["User-Agent": userAgent]
            )
            return adopt(try response.decode(Components.Schemas.AuthResult.self), into: store)
        } catch let error as RawRequestError {
            throw Self.sessionError(for: error)
        }
    }

    /// The `RawRequestError` → ``SessionError`` mapping the raw exchange needs,
    /// kept identical to the typed path's: 401 is a rejected code, anything
    /// else documented carries the backend's own message.
    private static func sessionError(for error: RawRequestError) -> SessionError {
        switch error {
        case .invalidPath(let path):
            return .unexpectedResponse("invalid path \(path)")
        case .http(401, _):
            return .invalidCredentials
        case .http(let status, let body):
            let decoded = try? JSONDecoder.adhDefault.decode(Components.Schemas._Error.self, from: body)
            return .unexpectedResponse(decoded.map(message) ?? "HTTP \(status)")
        }
    }

    /// Revokes the refresh token (best effort — a dead backend must not keep
    /// the user signed in locally) and clears the store.
    ///
    /// The revoke goes through ``rawJSON(method:path:query:body:)`` rather
    /// than the generated `postAuthRevoke`: the backend accepts (and the hub
    /// requires) a `{"refreshToken": …}` body, but the committed
    /// `openapi.json` still describes `POST /auth/revoke` as a bodiless
    /// `204`, so the generated operation cannot express the real request.
    /// The backend is the authority here; the document is stale. This is the
    /// one raw call the session layer makes, and it is exempt from
    /// refresh-and-retry (``SessionRefreshMiddleware/exemptOperationIDs``
    /// derives that exemption from ``ADHClient/revokeRawOperationID``):
    /// signing out with an already-expired access token 401s, and rotating
    /// the refresh token mid-revoke would leave the body carrying a consumed
    /// token the server can no longer match — a silent failure to revoke.
    public func signOut() async {
        guard let session else { return }
        if let refreshToken = session.currentSession()?.refreshToken,
           let body = try? JSONEncoder().encode(["refreshToken": refreshToken]) {
            _ = try? await rawJSON(method: Self.revokeMethod, path: Self.revokePath, body: body)
        }
        session.clear()
    }

    public func currentUser() async throws -> Components.Schemas.User {
        let output = try await api.getAuthMe()
        switch output {
        case .ok(let ok):
            return try ok.body.json
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }
}
