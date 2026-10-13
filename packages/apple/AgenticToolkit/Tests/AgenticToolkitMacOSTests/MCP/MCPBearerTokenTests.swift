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

    /// A symlink at the token path is refused, not followed: neither the file
    /// it points to is read as the token, nor is a fresh token written
    /// through it, and its target is left untouched.
    func testASymlinkAtTheTokenPathIsRefused() throws {
        let dir = tempDir()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let target = dir.appendingPathComponent("elsewhere")
        try "not-a-token".write(to: target, atomically: true, encoding: .utf8)
        let file = dir.appendingPathComponent("mcp-token")
        try FileManager.default.createSymbolicLink(at: file, withDestinationURL: target)
        XCTAssertThrowsError(try MCPBearerToken.load(from: file))
        XCTAssertEqual(try String(contentsOf: target, encoding: .utf8), "not-a-token")

        let dangling = dir.appendingPathComponent("dangling-token")
        let missing = dir.appendingPathComponent("missing")
        try FileManager.default.createSymbolicLink(at: dangling, withDestinationURL: missing)
        XCTAssertThrowsError(try MCPBearerToken.load(from: dangling))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path), "nothing is written through the link")
    }
}
