import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The file-backed half of the quarantine: counts, listing and clearing work
/// from the errors directory and its sidecars alone, with no database attached.
final class QuarantineServiceTests: XCTestCase {

    private var errorsDir: URL!

    override func setUpWithError() throws {
        errorsDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quarantine-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: errorsDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: errorsDir)
    }

    private func quarantineFile(_ name: String) throws -> URL {
        let url = errorsDir.appendingPathComponent(name)
        try Data("{}".utf8).write(to: url)
        return url
    }

    func testAQuarantinedEventIsCountedListedAndNotYetExhausted() throws {
        let service = QuarantineService(errorsDirectory: errorsDir)
        let url = try quarantineFile("error-one.json")

        service.recordInitialQuarantine(eventURL: url, reason: "constraint failed", code: 19, parsed: nil)

        XCTAssertEqual(service.count(), 1, "the sidecar is not a second entry")
        XCTAssertEqual(service.exhaustedCount(), 0)
        let listed = service.list()
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.filename, "error-one.json")
        XCTAssertEqual(listed.first?.reason, "constraint failed")
    }

    func testAnEventQuarantinedWithItsBudgetSpentIsExhausted() throws {
        let service = QuarantineService(errorsDirectory: errorsDir)
        let first = try quarantineFile("error-one.json")
        let second = try quarantineFile("error-two.json")

        service.recordInitialQuarantine(eventURL: first, reason: "r", code: nil, parsed: nil)
        service.recordInitialQuarantine(eventURL: second, reason: "r", code: nil, parsed: nil, retryCount: 3)

        XCTAssertEqual(service.count(), 2)
        XCTAssertEqual(service.exhaustedCount(), 1)
        XCTAssertEqual(service.counts().exhausted, 1)
    }

    func testClearRemovesEveryEventAndSidecar() throws {
        let service = QuarantineService(errorsDirectory: errorsDir)
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)

        service.clear()

        XCTAssertEqual(service.count(), 0)
        let left = try FileManager.default.contentsOfDirectory(atPath: errorsDir.path)
        XCTAssertTrue(left.isEmpty, "nothing, sidecars included, may survive: \(left)")
    }
}
