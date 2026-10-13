import XCTest
@testable import AgenticToolkitMacOS

final class MCPBearerTokenTests: XCTestCase {
    private func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mcp-token-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testGenerateIs64HexCharacters() {
        let token = MCPBearerToken.generate()
        XCTAssertEqual(token.count, 64)
        XCTAssertTrue(token.allSatisfy { $0.isHexDigit })
        XCTAssertNotEqual(token, MCPBearerToken.generate())
    }

    func testLoadCreatesTheFileWithMode600AndIsStable() throws {
        let file = tempDir().appendingPathComponent("mcp-token")
        let first = try MCPBearerToken.load(from: file)
        let second = try MCPBearerToken.load(from: file)
        XCTAssertEqual(first, second)
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        XCTAssertEqual((attributes[.posixPermissions] as? Int), 0o600)
    }

    func testLoadTightensAWiderExistingFileAndKeepsItsToken() throws {
        let dir = tempDir()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("mcp-token")
        try "keepme".write(to: file, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path)
        XCTAssertEqual(try MCPBearerToken.load(from: file), "keepme")
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        XCTAssertEqual((attributes[.posixPermissions] as? Int), 0o600)
    }

    func testLoadReadsAnExistingTokenTrimmed() throws {
        let dir = tempDir()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("mcp-token")
        try "abc123\n".write(to: file, atomically: true, encoding: .utf8)
        XCTAssertEqual(try MCPBearerToken.load(from: file), "abc123")
    }

    /// Review Focus 4: a home that cannot be written surfaces as a thrown
    /// error, which the feature turns into a status line.
    func testTokenLoadFailureIsThrown() {
        let file = URL(fileURLWithPath: "/dev/null/cannot/mcp-token")
        XCTAssertThrowsError(try MCPBearerToken.load(from: file))
    }
}
