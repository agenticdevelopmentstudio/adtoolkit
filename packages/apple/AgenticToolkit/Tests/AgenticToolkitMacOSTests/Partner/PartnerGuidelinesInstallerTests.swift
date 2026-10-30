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
}
