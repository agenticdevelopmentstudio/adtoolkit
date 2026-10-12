import XCTest
@testable import AgenticToolkitCore

final class CommandLineToolLinkTests: XCTestCase {

    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommandLineToolLinkTests-\(UUID().uuidString)", isDirectory: true)
        let app = root.appendingPathComponent("real/App", isDirectory: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let tool = app.appendingPathComponent("tool")
        FileManager.default.createFile(atPath: tool.path, contents: Data("#!/bin/sh\n".utf8),
                                       attributes: [.posixPermissions: 0o755])
        // `apps` is a symlinked folder holding the app, as a symlinked
        // ~/Applications would be.
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("apps"),
                                                   withDestinationURL: root.appendingPathComponent("real"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private var bin: URL { root.appendingPathComponent("bin", isDirectory: true) }

    func testALinkToTheResolvedToolReadsAsInstalledThroughASymlinkedFolder() throws {
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: bin.appendingPathComponent("tool"),
                                                   withDestinationURL: root.appendingPathComponent("real/App/tool"))
        let link = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("apps/App/tool"),
                                       directory: bin)
        XCTAssertEqual(link.state, .installed)
    }

    func testALinkThroughTheSymlinkedFolderReadsAsInstalledForTheResolvedTool() throws {
        let throughSymlink = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("apps/App/tool"),
                                                 directory: bin)
        try throughSymlink.install()
        let resolved = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("real/App/tool"),
                                           directory: bin)
        XCTAssertEqual(resolved.state, .installed)
    }

    func testALinkToAnotherToolIsLinkedElsewhere() throws {
        let other = root.appendingPathComponent("other")
        FileManager.default.createFile(atPath: other.path, contents: Data(), attributes: [.posixPermissions: 0o755])
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: bin.appendingPathComponent("tool"), withDestinationURL: other)
        let link = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("apps/App/tool"),
                                       directory: bin)
        XCTAssertEqual(link.state, .linkedElsewhere(other.path))
    }
}
