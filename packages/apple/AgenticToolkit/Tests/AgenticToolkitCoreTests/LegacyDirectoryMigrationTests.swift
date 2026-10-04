import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite struct LegacyDirectoryMigrationTests {
    private func scratch() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ldm-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeDirs(_ dirs: URL...) throws {
        for dir in dirs { try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
    }

    @Test func movesLegacyWhenOnlyLegacyExists() throws {
        let root = try scratch()
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))

        #expect(try LegacyDirectoryMigration.migrate(from: legacy, to: current) == .migrated)
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("db".utf8))
    }

    @Test func nothingWhenNeitherExists() throws {
        let root = try scratch()
        #expect(try LegacyDirectoryMigration.migrate(
            from: root.appendingPathComponent("old"), to: root.appendingPathComponent("new")) == .nothingToMigrate)
    }

    @Test func alreadyMigratedWhenOnlyCurrentExists() throws {
        let root = try scratch()
        let current = root.appendingPathComponent("new")
        try FileManager.default.createDirectory(at: current, withIntermediateDirectories: true)
        #expect(try LegacyDirectoryMigration.migrate(
            from: root.appendingPathComponent("old"), to: current) == .alreadyMigrated)
    }

    @Test func bothExistTouchesNeither() throws {
        let root = try scratch()
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("old".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))
        try Data("new".utf8).write(to: current.appendingPathComponent("stenographer.db"))

        #expect(try LegacyDirectoryMigration.migrate(from: legacy, to: current) == .bothExist)
        #expect(try Data(contentsOf: legacy.appendingPathComponent("stenographer.db")) == Data("old".utf8))
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("new".utf8))
    }

    @Test func createsMissingParentOfCurrent() throws {
        let root = try scratch()
        let legacy = root.appendingPathComponent("old")
        let current = root.appendingPathComponent("parent/new")
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        #expect(try LegacyDirectoryMigration.migrate(from: legacy, to: current) == .migrated)
        #expect(FileManager.default.fileExists(atPath: current.path))
    }

    @Test func emptyPlaceholderIsReplaced() throws {
        let root = try scratch()
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))

        #expect(try LegacyDirectoryMigration.migrate(
            from: legacy, to: current, markers: ["stenographer.db"]) == .migrated)
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("db".utf8))
    }

    @Test func nonEmptyPlaceholderIsMovedAside() throws {
        let root = try scratch()
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))
        try Data("junk".utf8).write(to: current.appendingPathComponent("cache.tmp"))

        #expect(try LegacyDirectoryMigration.migrate(
            from: legacy, to: current, markers: ["stenographer.db"]) == .migrated)
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("db".utf8))
        let asides = try FileManager.default.contentsOfDirectory(atPath: root.path)
            .filter { $0.hasPrefix("new.preempted-") }
        #expect(asides.count == 1)
        let aside = root.appendingPathComponent(asides[0])
        #expect(try Data(contentsOf: aside.appendingPathComponent("cache.tmp")) == Data("junk".utf8))
    }

    @Test func currentHoldingMarkerIsBothExist() throws {
        let root = try scratch()
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("old".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))
        try Data("new".utf8).write(to: current.appendingPathComponent("stenographer.db"))

        #expect(try LegacyDirectoryMigration.migrate(
            from: legacy, to: current, markers: ["stenographer.db"]) == .bothExist)
        #expect(try Data(contentsOf: legacy.appendingPathComponent("stenographer.db")) == Data("old".utf8))
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("new".utf8))
    }

    @Test func emptyMarkersBothExistIsBothExist() throws {
        let root = try scratch()
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("junk".utf8).write(to: current.appendingPathComponent("cache.tmp"))

        #expect(try LegacyDirectoryMigration.migrate(from: legacy, to: current) == .bothExist)
        #expect(FileManager.default.fileExists(atPath: legacy.path))
        #expect(FileManager.default.fileExists(atPath: current.appendingPathComponent("cache.tmp").path))
    }
}
