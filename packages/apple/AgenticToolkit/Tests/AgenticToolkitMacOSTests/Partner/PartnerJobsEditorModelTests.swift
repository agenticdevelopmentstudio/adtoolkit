import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class PartnerJobsEditorModelTests: XCTestCase {

    private var home: URL!
    private var paths: PartnerPaths!
    private var store: PartnerStore!
    private var model: PartnerJobsEditorModel!

    override func setUpWithError() throws {
        home = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerJobsEditorModelTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        paths = PartnerPaths(home: home, token: "agenticdeveloperkitchen")
        store = try PartnerStore(path: home.appendingPathComponent("Partner.db").path)
        for job in PartnerJobDefaults.all { try store.upsert(job) }
        model = PartnerJobsEditorModel(store: store, guidelines: PartnerGuidelinesInstaller(paths: paths))
    }

    override func tearDownWithError() throws {
        model = nil
        store = nil
        try? FileManager.default.removeItem(at: home)
    }

    private var reviewFile: URL { paths.jobsDirectory.appendingPathComponent("code-reviews.md") }

    func testAddStepThenMovePersistsOrder() throws {
        try model.addStep(to: "code-reviews")
        try model.moveStep(in: "code-reviews", from: 3, to: 0)
        let names = try XCTUnwrap(store.jobs().first { $0.id == "code-reviews" }).steps.map(\.name)
        XCTAssertEqual(names, ["new step", "open session", "review", "fix"])
        XCTAssertEqual(model.jobs.first { $0.id == "code-reviews" }?.steps.map(\.name), names)
    }

    func testRemoveStepAndBadIndex() throws {
        try model.removeStep(in: "code-reviews", at: 0)
        XCTAssertEqual(try store.jobs().first { $0.id == "code-reviews" }?.steps.count, 2)
        XCTAssertThrowsError(try model.removeStep(in: "code-reviews", at: 9))
        XCTAssertThrowsError(try model.addStep(to: "nope"))
    }

    func testSaveWritesGuidelinesFileAndModelReadsItBack() throws {
        var job = try XCTUnwrap(model.jobs.first { $0.id == "general" })
        job.guidelines = "Edited by the owner."
        try model.save(job)
        XCTAssertEqual(try String(contentsOf: paths.jobsDirectory.appendingPathComponent("general.md"),
                                  encoding: .utf8), "Edited by the owner.")
        XCTAssertEqual(model.jobs.first { $0.id == "general" }?.guidelines, "Edited by the owner.")
    }

    func testResetToDefaultRestoresStepsAndDeletesGuidelinesFile() throws {
        var job = try XCTUnwrap(model.jobs.first { $0.id == "code-reviews" })
        job.guidelines = "Custom."
        job.steps = []
        try model.save(job)
        XCTAssertTrue(FileManager.default.fileExists(atPath: reviewFile.path))

        try model.resetToDefault(id: "code-reviews")
        XCTAssertFalse(FileManager.default.fileExists(atPath: reviewFile.path))
        let reset = try XCTUnwrap(model.jobs.first { $0.id == "code-reviews" })
        XCTAssertEqual(reset.steps, PartnerJobDefaults.codeReviews().steps)
        XCTAssertEqual(reset.steps.count, 3)
        XCTAssertEqual(reset.guidelines, PartnerJobDefaults.codeReviews().guidelines)
        XCTAssertThrowsError(try model.resetToDefault(id: "custom"))
    }
}
