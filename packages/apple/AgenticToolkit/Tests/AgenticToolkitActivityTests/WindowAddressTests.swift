import XCTest
@testable import AgenticToolkitActivity

/// The rule that decides whether the frontmost window is showing a file or a
/// web page. It is worth its own test because two things depend on getting it
/// right and neither is easy to see going wrong: the `document_path` column
/// stops meaning "a file" the moment a URL is allowed into it, and migration
/// 8's backfill splits the historical column with the same test written in SQL.
final class WindowAddressTests: XCTestCase {
    func testNothingReportedIsNoAddress() {
        XCTAssertNil(WindowAddress(rawDocument: nil))
        XCTAssertNil(WindowAddress(rawDocument: ""))
    }

    func testAFileURLIsUnwrappedToItsPath() {
        XCTAssertEqual(WindowAddress(rawDocument: "file:///Users/me/notes.md"),
                       .file("/Users/me/notes.md"))
    }

    func testAFileURLIsPercentDecoded() {
        XCTAssertEqual(WindowAddress(rawDocument: "file:///Users/me/My%20Notes.md"),
                       .file("/Users/me/My Notes.md"),
                       "the path a person reads, and the one FileManager takes")
    }

    func testAFileURLCarryingAUserAndHostKeepsOnlyThePath() {
        // The shape iTerm2 answers with on its focused session element, which
        // is where a terminal's working directory is readable without any
        // Apple Events consent. The authority is the machine we are already
        // running on, so the path alone is the whole address.
        XCTAssertEqual(
            WindowAddress(rawDocument: "file://me@my-mac.local/Users/me/projects/olylo"),
            .file("/Users/me/projects/olylo"))
    }

    func testAWebAddressIsAURL() {
        XCTAssertEqual(WindowAddress(rawDocument: "https://example.org/page"),
                       .url("https://example.org/page"))
        XCTAssertEqual(WindowAddress(rawDocument: "http://localhost:3000/"),
                       .url("http://localhost:3000/"))
    }

    func testABareTypeIsAFile() {
        XCTAssertEqual(WindowAddress(rawDocument: "/Users/me/notes.md"),
                       .file("/Users/me/notes.md"))
        XCTAssertEqual(WindowAddress(rawDocument: "notes.md"), .file("notes.md"))
    }

    /// A URL and a path are never both readable off one value — the accessors
    /// exist so a caller can ask for the one it wants without a `switch`, and
    /// each has to be empty for the other case or the caller would record the
    /// same string in two columns.
    func testEachAccessorAnswersForOnlyItsOwnCase() {
        let file = WindowAddress(rawDocument: "/tmp/a.txt")
        XCTAssertEqual(file?.filePath, "/tmp/a.txt")
        XCTAssertNil(file?.urlString)

        let url = WindowAddress(rawDocument: "https://example.org")
        XCTAssertEqual(url?.urlString, "https://example.org")
        XCTAssertNil(url?.filePath)
    }

    /// A malformed `file://` string is kept rather than dropped: the window
    /// said something about itself, and losing it entirely is worse than
    /// recording it unparsed.
    func testAnUnparseableFileURLKeepsWhatTheAppSaid() {
        let raw = "file://\u{7F}broken"
        XCTAssertEqual(WindowAddress(rawDocument: raw), .file(raw),
                       "the raw string itself, not merely something non-nil")
    }
}
