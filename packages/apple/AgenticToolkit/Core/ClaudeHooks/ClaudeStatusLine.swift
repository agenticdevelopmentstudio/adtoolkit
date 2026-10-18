import Foundation

/// Claude Code's one `statusLine` slot, shared through claudehelpers'
/// dispatcher (`external/claudehelpers/scripts/statuslinedispatcher/docs/statusline.md`
/// is the contract). The slot runs `~/.claude/claudehelpers/statusline/dispatch.sh`;
/// each tool owns one file beside it, `renderers/<name>` (its output is shown)
/// or `taps/<name>` (it only reads the payload), whose whole content is one
/// shell command. A broken tool drops out of the line instead of blanking it,
/// so no tool ever has to refuse another's command or wrap it.
///
/// This is the file side of that contract, and depends on nothing above it.
/// `ClaudeHookInstaller` decides what a tool registers and does the
/// `settings.json` edit under the shared lock (`settingsLockName`).
struct ClaudeStatusLine: Sendable {

    enum Kind: String, CaseIterable, Sendable {
        case renderers
        case taps
    }

    struct Entry: Equatable, Sendable {
        let kind: Kind
        let name: String
        let command: String
    }

    enum Failure: Error, LocalizedError, Equatable {
        /// This build carries no readable dispatcher, and none is installed.
        case dispatcherMissing(String)
        /// The dispatcher this build carries has no version line, so it can
        /// never be ordered against an installed copy.
        case dispatcherUnversioned(String)

        var errorDescription: String? {
            switch self {
            case .dispatcherMissing(let path):
                "The status-line dispatcher this build carries is missing at \(path)."
            case .dispatcherUnversioned(let path):
                "The status-line dispatcher this build carries has no version line at \(path)."
            }
        }
    }

    /// Ends the dispatcher's `statusLine.command`, which is exactly
    /// `sh <quoted path> # claudehelpers-statusline`.
    static let marker = "# claudehelpers-statusline"

    /// The lock every `settings.json` editor that follows claudehelpers'
    /// contract holds across its read-modify-write, beside `settings.json`.
    static let settingsLockName = ".settings.lock"

    /// A command found in the slot when the dispatcher takes it over is kept
    /// as `renderers/adopted` (then `adopted-2`, …), so it keeps showing.
    static let adoptedName = "adopted"

    private static let versionPrefix = "# claudehelpers-statusline-dispatch "
    private static let nameCharacters = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    private static let asciiAlphanumerics = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    /// `~/.claude`, the directory holding `settings.json`.
    let claudeDirectory: URL
    /// The dispatcher this build carries (`Contents/Resources/dispatch.sh`).
    let bundledDispatcher: URL

    var directory: URL { claudeDirectory.appendingPathComponent("claudehelpers/statusline", isDirectory: true) }
    var dispatcherURL: URL { directory.appendingPathComponent("dispatch.sh") }

    /// The `statusLine.command` that runs the dispatcher: the same string
    /// claudehelpers' Python writes (`ShellQuoting.quoteIfNeeded` matches `shlex.quote`),
    /// so the two never fight over the slot.
    var dispatcherCommand: String {
        "sh \(ShellQuoting.quoteIfNeeded(dispatcherURL.path)) \(Self.marker)"
    }

    /// A command shaped like the dispatcher's, `sh <path> # claudehelpers-statusline`,
    /// whichever directory it runs from. A command that only mentions the
    /// marker somewhere else is some tool's own, and is adopted, not replaced.
    static func isDispatcherCommand(_ command: String) -> Bool {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("sh ") && trimmed.hasSuffix(" \(marker)")
            && trimmed.count > "sh ".count + " \(marker)".count
    }

    /// The names `adopt` gives: `adopted` and `adopted-<N>`. Another tool's
    /// entry that merely starts with the word (`adoptedtheme`) is not one.
    static func isAdoptedName(_ name: String) -> Bool {
        if name == adoptedName { return true }
        let prefix = adoptedName + "-"
        guard name.hasPrefix(prefix) else { return false }
        let number = name.dropFirst(prefix.count)
        return !number.isEmpty && number.allSatisfy { $0.isASCII && $0.isNumber }
    }

    /// The number on the first `# claudehelpers-statusline-dispatch N` line
    /// that carries one, nil when no line does: the same reading as
    /// claudehelpers' anchored, multi-line `^…(\d+)\s*$`.
    static func dispatcherVersion(_ text: String) -> Int? {
        for line in text.split(separator: "\n", omittingEmptySubsequences: false)
        where line.hasPrefix(versionPrefix) {
            let digits = line.dropFirst(versionPrefix.count).trimmingCharacters(in: .whitespaces)
            if !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }), let version = Int(digits) {
                return version
            }
        }
        return nil
    }

    static func isValidName(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first, asciiAlphanumerics.contains(first) else { return false }
        return name.unicodeScalars.allSatisfy(nameCharacters.contains)
    }

    /// What `installDispatcher` did: the version it wrote, or why it kept the
    /// installed copy (the same version, or a newer one some other tool put there).
    struct DispatcherInstall: Equatable, Sendable {
        /// The version on disk before, nil when there was none.
        let installed: Int?
        /// The version this build carries, nil when its copy is unreadable or unversioned.
        let offered: Int?
        let wrote: Bool
    }

    /// Writes the bundled dispatcher unless the installed one is the same
    /// version or newer: a newer copy came from a newer tool, and replacing it
    /// would take away what that tool relies on. A bundle whose own copy is
    /// missing or unversioned still works with a versioned dispatcher already
    /// in place, and fails only when there is none.
    @discardableResult
    func installDispatcher() throws -> DispatcherInstall {
        let installed = (try? String(contentsOf: dispatcherURL, encoding: .utf8)).flatMap(Self.dispatcherVersion)
        guard let text = try? String(contentsOf: bundledDispatcher, encoding: .utf8) else {
            if installed != nil { return DispatcherInstall(installed: installed, offered: nil, wrote: false) }
            throw Failure.dispatcherMissing(bundledDispatcher.path)
        }
        guard let offered = Self.dispatcherVersion(text) else {
            if installed != nil { return DispatcherInstall(installed: installed, offered: nil, wrote: false) }
            throw Failure.dispatcherUnversioned(bundledDispatcher.path)
        }
        if let installed, installed >= offered {
            return DispatcherInstall(installed: installed, offered: offered, wrote: false)
        }
        try write(text, to: dispatcherURL, mode: 0o755)
        return DispatcherInstall(installed: installed, offered: offered, wrote: true)
    }

    /// The dispatcher's record of `name`'s last failure (`errors/<name>`): it
    /// writes one whenever the entry exits non-zero, times out or can't run,
    /// and deletes it the next time the entry succeeds, so a record here means
    /// the entry is failing now and is missing from the line. Nil when there
    /// is none, or `name` is not a valid entry name.
    func lastError(of name: String) -> String? {
        guard Self.isValidName(name) else { return nil }
        let url = directory.appendingPathComponent("errors").appendingPathComponent(name)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func entries() -> [Entry] {
        Kind.allCases.flatMap { kind -> [Entry] in
            let folder = directory.appendingPathComponent(kind.rawValue)
            let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
            return names.sorted().filter(Self.isValidName).compactMap { read(kind, $0) }
        }
    }

    /// The entry registered under `name`, of either kind.
    func entry(named name: String) -> Entry? {
        guard Self.isValidName(name) else { return nil }
        return Kind.allCases.lazy.compactMap { read($0, name) }.first
    }

    /// Registers (or replaces) `name` as `kind`, removing it from the other
    /// kind, so switching between showing and capturing is one call. Only
    /// ever called with the calling tool's own name: a tool never edits another's.
    /// True when it changed a file, false when `name` was already exactly that.
    @discardableResult
    func register(_ kind: Kind, name: String, command: String) throws -> Bool {
        precondition(Self.isValidName(name), "invalid status-line entry name \(name)")
        var changed = false
        for other in Kind.allCases where other != kind {
            changed = try removeIfPresent(entryURL(other, name)) || changed
        }
        let url = entryURL(kind, name)
        let text = command + "\n"
        guard (try? String(contentsOf: url, encoding: .utf8)) != text else { return changed }
        try write(text, to: url, mode: 0o600)
        return true
    }

    /// Removes `name` from both kinds, and its recorded error. True when an
    /// entry was there.
    @discardableResult
    func unregister(_ name: String) throws -> Bool {
        var removed = false
        for kind in Kind.allCases {
            removed = try removeIfPresent(entryURL(kind, name)) || removed
        }
        try removeIfPresent(directory.appendingPathComponent("errors").appendingPathComponent(name))
        return removed
    }

    /// Keeps `command`, found in the slot, as a renderer under the first
    /// `adopted` name free in either kind, unless some entry already runs
    /// exactly it. The slot holds one command, so the one found there replaced
    /// whatever was adopted before: earlier `adopted*` renderers go, rather
    /// than bringing back a line the person replaced. The name it used, or nil.
    @discardableResult
    func adopt(_ command: String) throws -> String? {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = entries()
        guard !trimmed.isEmpty, !existing.contains(where: { $0.command == trimmed }) else { return nil }
        for earlier in existing where earlier.kind == .renderers && Self.isAdoptedName(earlier.name) {
            try unregister(earlier.name)
        }
        var name = Self.adoptedName
        var number = 1
        while Kind.allCases.contains(where: { FileManager.default.fileExists(atPath: entryURL($0, name).path) }) {
            number += 1
            name = "\(Self.adoptedName)-\(number)"
        }
        try write(trimmed + "\n", to: entryURL(.renderers, name), mode: 0o600)
        return name
    }

    private func read(_ kind: Kind, _ name: String) -> Entry? {
        guard let text = try? String(contentsOf: entryURL(kind, name), encoding: .utf8) else { return nil }
        return Entry(kind: kind, name: name, command: text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func entryURL(_ kind: Kind, _ name: String) -> URL {
        directory.appendingPathComponent(kind.rawValue).appendingPathComponent(name)
    }

    @discardableResult
    private func removeIfPresent(_ url: URL) throws -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        try FileManager.default.removeItem(at: url)
        return true
    }

    /// Entries can hold a command adopted from `settings.json`, which may
    /// carry a token, so the tree is owner-only: directories 0700, entries
    /// 0600, each file created at its final mode before it is visible.
    private func write(_ text: String, to url: URL, mode: mode_t) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        try AtomicFile.write(Data(text.utf8), to: url, mode: mode)
    }
}
