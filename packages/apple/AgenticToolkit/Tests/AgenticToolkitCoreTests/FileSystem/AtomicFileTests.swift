import Foundation
import Testing
@testable import AgenticToolkitCore

struct AtomicFileTests {

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AtomicFileTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test func writeCreatesTheFileAtTheRequestedMode() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("a.txt")

        try AtomicFile.write(Data("one".utf8), to: url, mode: 0o600)

        #expect(try Data(contentsOf: url) == Data("one".utf8))
        #expect(AtomicFile.mode(of: url) == 0o600)
    }

    @Test func secondWriteReplacesTheContentAndKeepsTheMode() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("a.txt")

        try AtomicFile.write(Data("one".utf8), to: url, mode: 0o640)
        try AtomicFile.write(Data("two".utf8), to: url, mode: 0o640)

        #expect(try Data(contentsOf: url) == Data("two".utf8))
        #expect(AtomicFile.mode(of: url) == 0o640)
    }

    @Test func modeOfAMissingPathIsNil() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(AtomicFile.mode(of: directory.appendingPathComponent("missing")) == nil)
    }
}
