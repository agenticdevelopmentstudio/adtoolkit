@testable import AgenticToolkitCore
import Foundation

/// Fixtures shared by the status-line and HookInstaller tests. Each one
/// throws, so a fixture that cannot be made fails the test that needed it
/// instead of quietly turning into a missing dispatcher.
enum StatusLineTestSupport {

    /// A stand-in for the dispatcher a bundle carries: a script whose second
    /// line is the version line.
    static func makeBundledDispatcher(in directory: URL, version: Int = 1) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("bundled-dispatch-\(version).sh")
        try "#!/bin/sh\n# claudehelpers-statusline-dispatch \(version)\n"
            .write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// The checkout that carries `external/claudehelpers`, found by walking up
    /// from this file. The toolkit builds standalone too, where there is no
    /// such checkout; `requireSubmodule` then fails with a message naming the fix.
    static var repositoryRoot: URL {
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while directory.path != "/" {
            if FileManager.default.fileExists(
                atPath: directory.appendingPathComponent("external/claudehelpers").path) {
                return directory
            }
            directory.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    }

    /// The claudehelpers submodule's status-line directory, which holds the
    /// dispatcher this build bundles and the settings contract.
    static var dispatcherSource: URL {
        repositoryRoot.appendingPathComponent("external/claudehelpers/scripts/statuslinedispatcher")
    }

    /// The dispatcher this build bundles (project.yml copies the same file).
    static var realDispatcher: URL { dispatcherSource.appendingPathComponent("dispatch.sh") }

    /// The conformance fixtures both claudehelpers' pytest suite and these
    /// tests run, so the Swift and Python halves agree case for case.
    static var conformanceFixtures: URL {
        repositoryRoot.appendingPathComponent("external/claudehelpers/tests/fixtures/statusline_conformance.json")
    }

    /// Fails with a message that names the fix when the claudehelpers
    /// submodule was never checked out, instead of a bare missing-file error.
    static func requireSubmodule(_ url: URL) throws -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SubmoduleMissing(path: url.path)
        }
        return url
    }

    struct SubmoduleMissing: Error, CustomStringConvertible {
        let path: String
        var description: String {
            "\(path) is missing: check out the claudehelpers submodule "
                + "(git submodule update --init external/claudehelpers)"
        }
    }
}

/// `statusline_conformance.json`, the cases claudehelpers' Python and this
/// Swift code must agree on.
struct StatusLineConformance: Decodable {

    struct Quote: Decodable { let word: String; let quoted: String }
    struct CommandCase: Decodable { let command: String; let expected: Bool }
    struct NameCase: Decodable { let name: String; let expected: Bool }
    struct VersionCase: Decodable { let text: String; let version: Int? }
    /// `entries` and `renderers` are `[kind, name, command]` and `[name, command]`.
    struct AdoptCase: Decodable {
        let about: String
        let entries: [[String]]
        let command: String
        let name: String?
        let renderers: [[String]]
    }
    /// `slot` is `removed`, `dispatcher`, or the command handed back.
    struct ReleaseCase: Decodable {
        let about: String
        let remaining: [[String]]
        let slot: String
    }

    let shellQuote: [Quote]
    let isDispatcherCommand: [CommandCase]
    let isAdoptedName: [NameCase]
    let isValidName: [NameCase]
    let dispatcherVersion: [VersionCase]
    let adopt: [AdoptCase]
    let release: [ReleaseCase]

    static func load() throws -> StatusLineConformance {
        let url = try StatusLineTestSupport.requireSubmodule(StatusLineTestSupport.conformanceFixtures)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StatusLineConformance.self, from: Data(contentsOf: url))
    }

    /// Writes one `[kind, name, command]` entry file the way another tool would.
    static func write(_ entry: [String], under directory: URL) throws {
        let url = directory.appendingPathComponent(entry[0]).appendingPathComponent(entry[1])
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data((entry[2] + "\n").utf8).write(to: url)
    }
}

// MARK: - Hook configurations used across the hook tests

extension ClaudeHookConfiguration {

    /// The values a macOS menu-bar session daemon installs with: the reference
    /// fixture whose rendered commands and settings the installer tests pin.
    static func stenographerFixture(
        helperPath: String = "/Applications/Stenographer.app/Contents/Helpers/steno",
        settingsURL: URL,
        dropDirectory: String = "~/.claude/stenographer-events",
        bundledDispatcher: URL? = nil
    ) -> ClaudeHookConfiguration {
        let binDirectory = "/usr/local/bin"
        return ClaudeHookConfiguration(
            name: "stenographer",
            marker: "# stenographer-hook",
            hookBinaryPath: helperPath,
            dropDirectory: dropDirectory,
            settingsURL: settingsURL,
            ownLockName: ".stenographer-hooks.lock",
            statusLineEntryName: "stenographer",
            bundledDispatcher: bundledDispatcher,
            legacy: LegacyHookForms(
                httpHookURLBase: "http://127.0.0.1:22847/hook",
                captureScriptName: "stenographer-capture.py",
                captureScriptSecondLinePrefixes: [
                    "\"\"\"stenographer-capture.py \u{2014} the hook entry point that survives an install.",
                    "\"\"\"stenographer-capture.py \u{2014} the hook entry point stenographer registers."
                ],
                statusLineCommands: [
                    "\(binDirectory)/steno statusline",
                    "\(binDirectory)/steno statusline --capture-only",
                    "stenographer statusline",
                    "\(binDirectory)/stenographer statusline",
                    "snog statusline",
                    "\(binDirectory)/snog statusline"
                ],
                statusLineCommandSuffixes: ["statusline.dispatcher"]))
    }

    /// A second daemon's configuration: its own marker, helper and drop
    /// directory, a tap-only status line and no legacy forms.
    static func adkdFixture(
        helperPath: String = "/Applications/Kitchen.app/Contents/Helpers/adk",
        settingsURL: URL,
        dropDirectory: String = "~/.claude/adkd-events",
        bundledDispatcher: URL? = nil
    ) -> ClaudeHookConfiguration {
        ClaudeHookConfiguration(
            name: "adkd",
            marker: "# adkd-hook",
            hookBinaryPath: helperPath,
            statusLineTapOnly: true,
            dropDirectory: dropDirectory,
            settingsURL: settingsURL,
            bundledDispatcher: bundledDispatcher,
            legacy: .none)
    }
}

extension ClaudeHookInstaller {

    /// Mirrors the argument shape the installer tests were written against.
    convenience init(settingsURL: URL, dropDirectory: String, stenoPath: String,
                     bundledDispatcher: URL? = nil, lockTimeout: TimeInterval = 5,
                     stenoIsExecutable: @escaping @Sendable (String) -> Bool
                        = ClaudeHookInstaller.defaultHelperIsExecutable) {
        self.init(
            configuration: .stenographerFixture(helperPath: stenoPath, settingsURL: settingsURL,
                                                dropDirectory: dropDirectory,
                                                bundledDispatcher: bundledDispatcher),
            lockTimeout: lockTimeout, helperIsExecutable: stenoIsExecutable)
    }
}
