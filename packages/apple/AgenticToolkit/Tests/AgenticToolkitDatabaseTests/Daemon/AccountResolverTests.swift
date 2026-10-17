import XCTest
@testable import AgenticToolkitDatabase

final class AccountResolverTests: XCTestCase {

    private var tmpDir: String!

    override func setUpWithError() throws {
        tmpDir = NSTemporaryDirectory() + "account-resolver-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: tmpDir, withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(atPath: tmpDir)
    }

    private func writeJSON(_ contents: String) -> String {
        let path = tmpDir + "/.claude.json"
        try? contents.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    func testReturnsEmailFromOauthAccount() {
        let path = writeJSON(#"{"oauthAccount": {"emailAddress": "a@b.com"}}"#)
        let resolver = AccountResolver(claudeJSONPath: path)
        XCTAssertEqual(resolver.currentEmail(), "a@b.com")
    }

    func testMissingFileReturnsEmpty() {
        let resolver = AccountResolver(claudeJSONPath: tmpDir + "/does-not-exist.json")
        XCTAssertEqual(resolver.currentEmail(), "")
    }

    func testNoOauthAccountReturnsEmpty() {
        let path = writeJSON(#"{"numStartups": 5}"#)
        let resolver = AccountResolver(claudeJSONPath: path)
        XCTAssertEqual(resolver.currentEmail(), "")
    }

    func testMalformedJSONReturnsEmpty() {
        let path = writeJSON("not json at all {")
        let resolver = AccountResolver(claudeJSONPath: path)
        XCTAssertEqual(resolver.currentEmail(), "")
    }

    func testRereadsWhenFileChanges() throws {
        let path = writeJSON(#"{"oauthAccount": {"emailAddress": "old@b.com"}}"#)
        let resolver = AccountResolver(claudeJSONPath: path)
        XCTAssertEqual(resolver.currentEmail(), "old@b.com")

        // Rewrite with a new mtime; resolver must pick up the change.
        Thread.sleep(forTimeInterval: 1.1)
        _ = writeJSON(#"{"oauthAccount": {"emailAddress": "new@b.com"}}"#)
        XCTAssertEqual(resolver.currentEmail(), "new@b.com")
    }
}
