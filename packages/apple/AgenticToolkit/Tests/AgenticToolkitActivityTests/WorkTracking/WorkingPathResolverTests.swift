import XCTest
@testable import AgenticToolkitActivity

final class WorkingPathResolverTests: XCTestCase {
    private let locator = RepoLocator(fileSystem: .init(
        kind: { ["/src/app/.git", "/src/other/.git"].contains($0) ? .directory : .missing },
        read: { $0.hasSuffix("/HEAD") ? "ref: refs/heads/main\n" : nil }))
    private func resolver(_ roots: [String] = ["/src/app", "/src/other"]) -> WorkingPathResolver {
        WorkingPathResolver(locator: locator, knownRoots: { roots })
    }
    func testDocumentAppUsesAXDocument() {
        let r = resolver().attribution(kind: .document, documentPath: "/src/app/a.swift", title: "a.swift")
        XCTAssertEqual(r.path, "/src/app/a.swift"); XCTAssertEqual(r.repo?.root, "/src/app")
    }
    func testFileURLDocumentIsConverted() {
        XCTAssertEqual(resolver().workingPath(kind: .document, documentPath: "file:///src/app/a.swift", title: ""),
                       "/src/app/a.swift")
    }
    func testEditorFallsBackToTitleFolder() {
        let r = resolver().attribution(kind: .editor, documentPath: nil, title: "main.swift — other")
        XCTAssertEqual(r.path, "/src/other"); XCTAssertEqual(r.repo?.root, "/src/other")
    }
    func testJetBrainsEnDashTitle() {
        XCTAssertEqual(resolver().workingPath(kind: .editor, documentPath: nil, title: "app – Build.kt"), "/src/app")
    }
    func testTerminalUsesItsCwd() {
        XCTAssertEqual(resolver().workingPath(kind: .terminal, documentPath: "/src/app/Sources", title: "zsh"),
                       "/src/app/Sources")
    }
    func testNoneKindMatchesTitleOrIsEmpty() {
        XCTAssertEqual(resolver().workingPath(kind: .none, documentPath: nil, title: "Simulator"), "")
        XCTAssertEqual(resolver().workingPath(kind: .none, documentPath: nil, title: "other — main"), "/src/other")
    }
    func testUnknownTitleIsUnresolved() {
        let r = resolver().attribution(kind: .editor, documentPath: nil, title: "Welcome")
        XCTAssertEqual(r.path, ""); XCTAssertNil(r.repo)
    }
    func testFileURLWithUnescapedSpaceIsKept() {
        XCTAssertEqual(resolver().workingPath(kind: .document, documentPath: "file:///src/my app/a.swift", title: ""),
                       "/src/my app/a.swift")
    }
    func testPercentSequencesInSpacedFileURLDoNotCrash() {
        // On macOS 14+ `URL(string:)` escapes spaces and stray `%` itself, so the plain-path
        // fallback is unreachable for path-shaped input; the primary branch decodes.
        XCTAssertEqual(resolver().workingPath(kind: .document, documentPath: "file:///src/my%20app/a.swift",
                                              title: ""), "/src/my app/a.swift")
        XCTAssertEqual(resolver().workingPath(kind: .document, documentPath: "file:///src/my app/100%zz/a.swift",
                                              title: ""), "/src/my app/100%zz/a.swift")
    }
    func testFileURLThatCannotParseAndIsNotAPathIsUnresolved() {
        // `URL(string:)` returns nil (bad host bracket) and the remainder is not absolute.
        XCTAssertNil(URL(string: "file://[/a b"))
        XCTAssertEqual(resolver().workingPath(kind: .document, documentPath: "file://[/a b", title: ""), "")
    }
    func testLongestRootWinsOnTie() {
        let r = resolver(["/a/app", "/a/deeper/app"])
        XCTAssertEqual(r.workingPath(kind: .editor, documentPath: nil, title: "f.swift - app"), "/a/deeper/app")
    }
    func testEmptyDocumentPathFallsBackToTitle() {
        XCTAssertEqual(resolver().workingPath(kind: .editor, documentPath: "", title: "x — app"), "/src/app")
    }
}
