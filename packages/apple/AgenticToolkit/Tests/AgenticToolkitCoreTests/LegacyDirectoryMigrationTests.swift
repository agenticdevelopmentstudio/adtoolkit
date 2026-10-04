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
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))

        #expect(try LegacyDirectoryMigration.migrate(from: legacy, to: current) == .migrated)
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("db".utf8))
    }

    @Test func nothingWhenNeitherExists() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        #expect(try LegacyDirectoryMigration.migrate(
            from: root.appendingPathComponent("old"), to: root.appendingPathComponent("new")) == .nothingToMigrate)
    }

    @Test func alreadyMigratedWhenOnlyCurrentExists() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        let current = root.appendingPathComponent("new")
        try FileManager.default.createDirectory(at: current, withIntermediateDirectories: true)
        #expect(try LegacyDirectoryMigration.migrate(
            from: root.appendingPathComponent("old"), to: current) == .alreadyMigrated)
    }

    @Test func bothExistTouchesNeither() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
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
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("old")
        let current = root.appendingPathComponent("parent/new")
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        #expect(try LegacyDirectoryMigration.migrate(from: legacy, to: current) == .migrated)
        #expect(FileManager.default.fileExists(atPath: current.path))
    }

    @Test func emptyPlaceholderIsReplaced() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
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
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))
        try Data("junk".utf8).write(to: current.appendingPathComponent("cache.tmp"))

        let outcome = try LegacyDirectoryMigration.migrate(
            from: legacy, to: current, markers: ["stenographer.db"])
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("db".utf8))
        let asides = try FileManager.default.contentsOfDirectory(atPath: root.path)
            .filter { $0.hasPrefix("new.preempted-") }
        #expect(asides.count == 1)
        let aside = root.appendingPathComponent(asides[0])
        #expect(outcome == .migratedReplacingPlaceholder(asideAt: aside))
        #expect(try Data(contentsOf: aside.appendingPathComponent("cache.tmp")) == Data("junk".utf8))
    }

    @Test func currentHoldingMarkerIsBothExist() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
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
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("junk".utf8).write(to: current.appendingPathComponent("cache.tmp"))

        #expect(try LegacyDirectoryMigration.migrate(from: legacy, to: current) == .bothExist)
        #expect(FileManager.default.fileExists(atPath: legacy.path))
        #expect(FileManager.default.fileExists(atPath: current.appendingPathComponent("cache.tmp").path))
    }

    @Test func markerInSubdirectoryDoesNotCount() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        let nested = current.appendingPathComponent("sub")
        try makeDirs(legacy, nested)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))
        try Data("nested".utf8).write(to: nested.appendingPathComponent("stenographer.db"))

        let outcome = try LegacyDirectoryMigration.migrate(
            from: legacy, to: current, markers: ["stenographer.db"])
        guard case .migratedReplacingPlaceholder(let aside) = outcome else {
            Issue.record("expected placeholder replacement, got \(outcome)")
            return
        }
        #expect(try Data(contentsOf: current.appendingPathComponent("stenographer.db")) == Data("db".utf8))
        #expect(try Data(contentsOf: aside.appendingPathComponent("sub/stenographer.db")) == Data("nested".utf8))
    }

    @Test func sameDirectoryIsAlreadyMigrated() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        let dir = root.appendingPathComponent("same")
        try makeDirs(dir)
        try Data("db".utf8).write(to: dir.appendingPathComponent("stenographer.db"))

        #expect(try LegacyDirectoryMigration.migrate(from: dir, to: dir) == .alreadyMigrated)
        #expect(try LegacyDirectoryMigration.migrate(
            from: dir, to: dir.appendingPathComponent("../same"), markers: ["x"]) == .alreadyMigrated)
        #expect(try Data(contentsOf: dir.appendingPathComponent("stenographer.db")) == Data("db".utf8))
    }

    @Test func currentSymlinkedToLegacyIsAlreadyMigrated() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))
        try FileManager.default.createSymbolicLink(at: current, withDestinationURL: legacy)

        #expect(try LegacyDirectoryMigration.migrate(
            from: legacy, to: current, markers: ["other"]) == .alreadyMigrated)
        #expect(try Data(contentsOf: legacy.appendingPathComponent("stenographer.db")) == Data("db".utf8))
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: current.path) == legacy.path)
    }

    @Test func asideNameCollisionGetsSuffix() throws {
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("junk".utf8).write(to: current.appendingPathComponent("cache.tmp"))
        // Occupy every plausible timestamped name for this and the next second.
        let stamp = DateFormatter()
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.dateFormat = "yyyyMMdd-HHmmss"
        for offset in 0...2 {
            let name = "new.preempted-\(stamp.string(from: Date().addingTimeInterval(Double(offset))))"
            try makeDirs(root.appendingPathComponent(name))
        }
        let outcome = try LegacyDirectoryMigration.migrate(
            from: legacy, to: current, markers: ["stenographer.db"])
        guard case .migratedReplacingPlaceholder(let aside) = outcome else {
            Issue.record("expected placeholder replacement, got \(outcome)")
            return
        }
        #expect(try Data(contentsOf: aside.appendingPathComponent("cache.tmp")) == Data("junk".utf8))
        #expect(aside.lastPathComponent.hasSuffix("-1"))
    }

    @Test func failedLegacyMoveRestoresPlaceholder() throws {
        try #require(geteuid() != 0)
        let root = try scratch()
        defer { try? FileManager.default.removeItem(at: root) }
        let legacyParent = root.appendingPathComponent("lp")
        let legacy = legacyParent.appendingPathComponent("old"), current = root.appendingPathComponent("new")
        try makeDirs(legacy, current)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("stenographer.db"))
        try Data("junk".utf8).write(to: current.appendingPathComponent("cache.tmp"))
        chmod(legacyParent.path, 0o555)
        defer { chmod(legacyParent.path, 0o755) }

        do {
            _ = try LegacyDirectoryMigration.migrate(from: legacy, to: current, markers: ["stenographer.db"])
            Issue.record("expected a throw")
        } catch let error as POSIXError {
            #expect(error.code == .EACCES)
        }
        #expect(try Data(contentsOf: current.appendingPathComponent("cache.tmp")) == Data("junk".utf8))
        let asides = try FileManager.default.contentsOfDirectory(atPath: root.path)
            .filter { $0.hasPrefix("new.preempted-") }
        #expect(asides.isEmpty)
        #expect(try Data(contentsOf: legacy.appendingPathComponent("stenographer.db")) == Data("db".utf8))
    }
}
