import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

final class TranscriptTitleScannerTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("title-scanner-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func titleLine(_ title: String) -> String {
        #"{"type":"custom-title","customTitle":"\#(title)","sessionId":"s"}"# + "\n"
    }

    private let chatter = #"{"type":"assistant","message":{"content":[]}}"# + "\n"

    private func append(_ text: String, to url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(text.utf8))
    }

    /// Each Stop reads only what was appended since the last one, and a title
    /// found earlier survives a scan of lines that carry none.
    func testResumesWhereTheLastScanStopped() throws {
        let url = dir.appendingPathComponent("t.jsonl")
        try (titleLine("first") + chatter).write(to: url, atomically: false, encoding: .utf8)
        let scanner = TranscriptTitleScanner()

        XCTAssertEqual(scanner.title(path: url.path), "first")
        let size = try XCTUnwrap(
            (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value
        )
        XCTAssertEqual(scanner.resumeOffset(path: url.path), size, "the next scan starts at the end")

        try append(chatter, to: url)
        XCTAssertEqual(scanner.title(path: url.path), "first", "no new title keeps the old one")

        try append(titleLine("second") + chatter, to: url)
        XCTAssertEqual(scanner.title(path: url.path), "second")
        XCTAssertEqual(scanner.title(path: url.path), SessionEnricher.transcriptCustomTitle(path: url.path),
                       "the resumed scan agrees with a full one")
    }

    /// A replaced or shrunken file is not the one the cursor describes.
    func testARewrittenFileIsScannedFromTheStart() throws {
        let url = dir.appendingPathComponent("t.jsonl")
        try (titleLine("old") + chatter + chatter).write(to: url, atomically: false, encoding: .utf8)
        let scanner = TranscriptTitleScanner()
        XCTAssertEqual(scanner.title(path: url.path), "old")

        try chatter.write(to: url, atomically: true, encoding: .utf8)   // new inode
        XCTAssertNil(scanner.title(path: url.path))

        try (titleLine("new") + chatter).write(to: url, atomically: true, encoding: .utf8)
        XCTAssertEqual(scanner.title(path: url.path), "new")
    }

    /// Rewritten in place — same inode, same length, a different title before
    /// the cursor. Inode and size cannot tell; the content fingerprint can.
    func testAFileRewrittenInPlaceAtTheSameLengthIsScannedAgain() throws {
        let url = dir.appendingPathComponent("t.jsonl")
        try (titleLine("old") + chatter).write(to: url, atomically: false, encoding: .utf8)
        let scanner = TranscriptTitleScanner()
        XCTAssertEqual(scanner.title(path: url.path), "old")
        let inode = try FileManager.default.attributesOfItem(atPath: url.path)[.systemFileNumber] as? NSNumber

        try (titleLine("new") + chatter).write(to: url, atomically: false, encoding: .utf8)

        XCTAssertEqual(
            try FileManager.default.attributesOfItem(atPath: url.path)[.systemFileNumber] as? NSNumber, inode,
            "the premise: the same file, rewritten"
        )
        XCTAssertEqual(scanner.title(path: url.path), "new")
    }

    /// Growing it in place keeps the inode and passes the size check too.
    func testAFileRewrittenInPlaceLongerIsScannedAgain() throws {
        let url = dir.appendingPathComponent("t.jsonl")
        try (titleLine("old") + chatter).write(to: url, atomically: false, encoding: .utf8)
        let scanner = TranscriptTitleScanner()
        XCTAssertEqual(scanner.title(path: url.path), "old")

        try (chatter + titleLine("renamed") + chatter).write(to: url, atomically: false, encoding: .utf8)

        XCTAssertEqual(scanner.title(path: url.path), "renamed")
    }

    func testTheTitlePrefilterMatchesOnlyLinesNamingTheMarker() {
        XCTAssertTrue(SessionEnricher.mentionsCustomTitle(titleLine("x")))
        XCTAssertTrue(SessionEnricher.mentionsCustomTitle("é🙂 custom-title"), "non-ASCII before the marker")
        XCTAssertTrue(SessionEnricher.mentionsCustomTitle(String(titleLine("x").dropFirst(2))),
                      "a substring-backed line")
        XCTAssertFalse(SessionEnricher.mentionsCustomTitle(chatter))
        XCTAssertFalse(SessionEnricher.mentionsCustomTitle("custom-titl"))
        XCTAssertFalse(SessionEnricher.mentionsCustomTitle(""))
    }

    func testAMissingFileHasNoTitle() {
        XCTAssertNil(TranscriptTitleScanner().title(path: dir.appendingPathComponent("absent.jsonl").path))
    }
}
