import AgenticDeveloperHubClient
import XCTest
@testable import AgenticToolkitHubService

final class SignInConfigurationTests: XCTestCase {
    func testDefaultsAndCallbackURL() {
        let config = SignInConfiguration(clientID: "adh-cli")
        XCTAssertEqual(config.callbackScheme, "adh")
        XCTAssertEqual(config.callbackURL, URL(string: "adh://auth-callback"))
        XCTAssertEqual(config.backendURL, DaemonContract.backendURL)
    }

    /// The backend allow-lists these three origins verbatim for `adh-cli`; a
    /// fourth port would be refused with `return URL origin not allowed for
    /// this client`, so the list is a contract, not a preference.
    func testLoopbackPortsMatchTheBackendAllowList() {
        XCTAssertEqual(SignInConfiguration.loopbackPorts, [8517, 8518, 8519])
    }

    func testSocialStartURLCarriesClientProviderAndReturn() throws {
        let config = SignInConfiguration(clientID: "adh-cli", backendURL: URL(string: "https://api.example.com")!)
        let url = config.socialStartURL(
            provider: .github,
            returnURL: URL(string: "http://127.0.0.1:8517/cb?n=abc")!
        )
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.host, "api.example.com")
        XCTAssertEqual(components.path, "/oauth/signin/start")
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(items["clientId"], "adh-cli")
        XCTAssertEqual(items["providerId"], "github")
        XCTAssertEqual(items["return"], "http://127.0.0.1:8517/cb?n=abc")
    }

    /// `/oauth/signin/start` rejects any `return` that is not `http(s)://`,
    /// so the start URL must never carry the custom scheme again.
    func testSocialStartURLNeverReturnsToTheCustomScheme() throws {
        let config = SignInConfiguration(clientID: "adh-cli")
        let url = config.socialStartURL(
            provider: .google,
            returnURL: URL(string: "http://127.0.0.1:8519/cb?n=xyz")!
        )
        XCTAssertFalse(url.absoluteString.contains("adh%3A%2F%2F"))
        XCTAssertFalse(url.absoluteString.contains("adh://auth-callback"))
    }

    /// The hosted page takes exactly `clientId` and `return` — the query the
    /// `adh` CLI sends (`adh-tools/adh/scripts/auth/browser.py`).
    func testWebSignInStartURLOpensTheHostedPage() throws {
        let config = SignInConfiguration(clientID: "adh-cli", backendURL: URL(string: "https://api.example.com")!)
        let url = config.webSignInStartURL(returnURL: URL(string: "http://127.0.0.1:8518/cb?n=abc")!)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.host, "api.example.com")
        XCTAssertEqual(components.path, "/oauth/signin/authorize")
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(items, ["clientId": "adh-cli", "return": "http://127.0.0.1:8518/cb?n=abc"])
    }

    func testFromBundlePrefersEnvironmentOverPlistOverDefault() {
        let bundle = Bundle(for: SignInConfigurationTests.self)   // has no ADHSignInClientId
        XCTAssertEqual(SignInConfiguration.fromBundle(bundle, environment: [:]).clientID, "adh-cli")
        XCTAssertEqual(
            SignInConfiguration.fromBundle(bundle, environment: ["HUB_SIGNIN_CLIENT_ID": "adh-dev"]).clientID,
            "adh-dev"
        )
    }

    func testProviderLabels() {
        XCTAssertEqual(SocialProvider.google.label, "Google")
        XCTAssertEqual(SocialProvider.github.label, "GitHub")
        XCTAssertEqual(SocialProvider.gitlab.label, "GitLab")
        XCTAssertEqual(SocialProvider.bitbucket.label, "Bitbucket")
        XCTAssertEqual(SocialProvider.apple.label, "Apple")
    }
}
