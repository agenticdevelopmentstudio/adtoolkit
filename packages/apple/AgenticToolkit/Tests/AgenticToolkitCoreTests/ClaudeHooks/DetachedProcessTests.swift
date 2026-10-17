@testable import AgenticToolkitCore
import XCTest
import Foundation

/// The status-line feed leaves the dispatcher's reach: `DetachedProcess` hands
/// it to launchd, `FeedLock` keeps one per session, and the token walk starts
/// from the pid the dispatcher names.
final class DetachedProcessTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("detached-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testTheCommandGetsThePayloadAndEnvironmentAndHangsOffLaunchd() throws {
        let out = directory.appendingPathComponent("out")
        // The child waits a moment so its parent is the one it ends up with,
        // not the trampoline it started under.
        let script = "sleep 0.3; cat > '\(out.path).tmp'; echo \"$MARK $PPID\" >> '\(out.path).tmp';"
            + " mv '\(out.path).tmp' '\(out.path)'"
        let started = DetachedProcess.spawn(executable: "/bin/sh", arguments: ["-c", script],
                                            environment: ["MARK": "marked", "PATH": "/usr/bin:/bin"],
                                            stdin: Data("payload\n".utf8))
        XCTAssertTrue(started)
        let deadline = Date().addingTimeInterval(10)
        while !FileManager.default.fileExists(atPath: out.path) && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        let text = try String(contentsOf: out, encoding: .utf8)
        XCTAssertEqual(text, "payload\nmarked 1\n")
    }

    func testANonexistentCommandStillReturnsAtOnce() {
        let started = Date()
        _ = DetachedProcess.spawn(executable: "/nonexistent/steno", arguments: [], environment: [:],
                                  stdin: Data())
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
    }

    func testASecondFeedForTheSameSessionIsRefusedUntilTheFirstEnds() throws {
        let first = try XCTUnwrap(FeedLock.acquire(sessionID: "s-1", name: "stenographer", directory: directory))
        XCTAssertNil(FeedLock.acquire(sessionID: "s-1", name: "stenographer", directory: directory))
        let other = FeedLock.acquire(sessionID: "s-2", name: "stenographer", directory: directory)
        XCTAssertNotNil(other, "another session's feed is not held up")
        other?.release()
        first.release()
        let again = FeedLock.acquire(sessionID: "s-1", name: "stenographer", directory: directory)
        XCTAssertNotNil(again)
        again?.release()
    }

    func testASessionIDNeverEscapesTheLockDirectory() throws {
        let lock = try XCTUnwrap(FeedLock.acquire(sessionID: "../../x/é", name: "stenographer", directory: directory))
        defer { lock.release() }
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(names, ["stenographer-statusline-feed-______x__.lock"])
    }

    func testAnUnwritableLockDirectoryDoesNotStopTheFeed() {
        let lock = FeedLock.acquire(sessionID: "s", name: "stenographer", directory: directory.appendingPathComponent("absent"))
        XCTAssertNotNil(lock)
        lock?.release()
    }

    func testTheWalkStartsFromTheDispatchersParent() {
        let variable = StatusLineCapture.parentPIDVariable
        XCTAssertEqual(StatusLineCapture.parentPID(environment: [variable: "4242"]), 4242)
        XCTAssertEqual(StatusLineCapture.parentPID(environment: [:]), getppid())
        XCTAssertEqual(StatusLineCapture.parentPID(environment: [variable: "1"]), getppid())
        XCTAssertEqual(StatusLineCapture.parentPID(environment: [variable: "junk"]), getppid())
    }
}
