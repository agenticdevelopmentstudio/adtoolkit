import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class PartnerGuidelinesInstallerTests: XCTestCase {

    private var home: URL!
    private var paths: PartnerPaths!

    override func setUpWithError() throws {
        home = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerGuidelinesInstallerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        paths = PartnerPaths(home: home, token: "agenticdeveloperkitchen")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: home)
    }

    private func job(enabled: Bool) -> PartnerJob {
        PartnerJob(id: "general", name: "General coding partner", isEnabled: enabled,
                   guidelines: "Be useful.", steps: [])
    }

    func testInstallSkillsCreatesAndRemoves() throws {
        let installer = PartnerGuidelinesInstaller(paths: paths)
        try installer.installSkills(jobs: [job(enabled: true)])
        let file = home.appendingPathComponent(".claude/skills/adkitchen-partner-general/SKILL.md")
        let text = try String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(text.components(separatedBy: "\n").first, "---")
        XCTAssertTrue(text.contains("name: adkitchen-partner-general"))

        try installer.installSkills(jobs: [job(enabled: false)])
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path))
    }

    func testWritesSystemPromptAndJobFiles() throws {
        let installer = PartnerGuidelinesInstaller(paths: paths)
        let url = try installer.writeSystemPrompt(jobs: [job(enabled: true)])
        XCTAssertEqual(url, paths.systemPrompt)
        XCTAssertTrue(try String(contentsOf: url, encoding: .utf8).contains("## Job: General coding partner"))

        try installer.writeJobFiles(jobs: [job(enabled: false)])
        let body = try String(contentsOf: paths.jobsDirectory.appendingPathComponent("general.md"), encoding: .utf8)
        XCTAssertEqual(body, "Be useful.")
    }

    func testEditedFileSurvivesWriteJobFilesAndLoadReturnsIt() throws {
        let installer = PartnerGuidelinesInstaller(paths: paths)
        try installer.writeJobFiles(jobs: [job(enabled: true)])
        try installer.saveGuidelines(jobID: "general", text: "Edited.")
        try installer.writeJobFiles(jobs: [job(enabled: true)])
        XCTAssertEqual(installer.loadGuidelines(jobs: [job(enabled: true)]).first?.guidelines, "Edited.")
    }

    func testResetRestoresDefaultAndMissingFileIsFine() throws {
        let installer = PartnerGuidelinesInstaller(paths: paths)
        try installer.resetGuidelines(jobID: "general")
        try installer.saveGuidelines(jobID: "general", text: "Edited.")
        try installer.resetGuidelines(jobID: "general")
        XCTAssertEqual(installer.loadGuidelines(jobs: [job(enabled: true)]).first?.guidelines, "Be useful.")
    }

    func testInvalidJobIDThrows() {
        let installer = PartnerGuidelinesInstaller(paths: paths)
        for id in ["", "../x", "a/b"] {
            let bad = PartnerJob(id: id, name: "x", isEnabled: true, guidelines: "g", steps: [])
            XCTAssertThrowsError(try installer.installSkills(jobs: [bad]))
            XCTAssertThrowsError(try installer.writeJobFiles(jobs: [bad]))
        }
    }

    func testRemovesOrphanedPartnerSkillsOnly() throws {
        let skills = paths.skillsDirectory
        let orphan = skills.appendingPathComponent("adkitchen-partner-gone")
        let other = skills.appendingPathComponent("someone-elses")
        for dir in [orphan, other] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        try PartnerGuidelinesInstaller(paths: paths).installSkills(jobs: [job(enabled: true)])
        XCTAssertFalse(FileManager.default.fileExists(atPath: orphan.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: other.path))
    }
}
