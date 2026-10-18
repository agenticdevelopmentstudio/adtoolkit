import Darwin
import Foundation
import OSLog

/// Installs and removes one daemon's Claude Code hooks in `settings.json`,
/// driven by a `ClaudeHookConfiguration`. Each registration is a `command`
/// hook that runs the configuration's helper (`<helper> hook --event <Event>`),
/// which writes the payload as a drop file into the configuration's drop
/// directory and exits 0 — no socket, no port, no daemon. A running daemon
/// watching that directory ingests the event at once and a stopped one on its
/// next start. Nothing a hook does can fail while the daemon is down, so no
/// Claude session ever shows a hook error because of the daemon's state.
///
/// Every earlier form is legacy and is replaced on install (see
/// `LegacyHookForms`). Registrations are identified by their marker so they
/// coexist with other tools' hooks, including another daemon's installer
/// using a different configuration against the same file.
public final class ClaudeHookInstaller: Sendable {

    // MARK: - Constants

    /// Hook event types that Claude Code treats as delegations: registering any hook
    /// under these names hands the action off to the hook entirely. A passive logging
    /// hook that produces no stdout causes the owning tool (e.g. EnterWorktree) to fail
    /// with "no successful output". Those operations stay observable through the
    /// PreToolUse/PostToolUse hooks, which match every tool call.
    public static let delegationEventTypes: Set<String> = ["WorktreeCreate", "WorktreeRemove"]

    /// Event types a daemon ingests but Claude Code does not deliver as hooks.
    /// Registering a hook under one of these names triggers an "Unknown hook event"
    /// warning at every session start. `StatusLine` is synthesized by the
    /// status-line dispatcher rather than emitted by Claude, so it must not be
    /// registered as a Claude Code hook.
    public static let nonHookEventTypes: Set<String> = ["StatusLine"]

    /// Union of all event types excluded from Claude Code hook registration.
    public static let excludedEventTypes: Set<String> = delegationEventTypes.union(nonHookEventTypes)

    // MARK: - Properties

    public let configuration: ClaudeHookConfiguration
    /// The shared status-line slot's files (`ClaudeStatusLine`).
    let statusLine: ClaudeStatusLine
    /// How long `withSettingsLock` waits for a lock another tool holds.
    let lockTimeout: TimeInterval
    /// Whether the helper is something a hook can run. Injected so tests need
    /// no real bundle; the default is a regular, executable file.
    private let helperIsExecutable: @Sendable (String) -> Bool

    /// The default `helperIsExecutable`: a regular file (not a directory) the
    /// process may execute.
    public static let defaultHelperIsExecutable: @Sendable (String) -> Bool = { path in
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
            && FileManager.default.isExecutableFile(atPath: path)
    }

    public var settingsURL: URL { configuration.settingsURL }
    public var dropDirectory: String { configuration.dropDirectory }
    /// The helper every registration runs.
    public var helperPath: String { configuration.hookBinaryPath }

    /// Claude Code hook event types this installer registers for passive
    /// observation: the configuration's `hookedEvents`, minus
    /// `excludedEventTypes` (delegation types would break the owning tool,
    /// non-hook types would produce a settings warning).
    public var hookedEventTypes: [String] {
        configuration.hookedEvents.map(\.rawValue).filter { !Self.excludedEventTypes.contains($0) }
    }

    /// Cross-process signal that the user has disabled tracking. An app writes
    /// or removes this file when the user toggles the setting; the daemon
    /// checks it at boot before deciding whether to install or uninstall
    /// hooks. Lives next to settings.json so it shares the same parent
    /// directory the lock already creates.
    public var trackingDisabledMarkerURL: URL {
        settingsURL.deletingLastPathComponent()
            .appendingPathComponent(".\(configuration.name)-tracking-disabled")
    }

    /// Cross-process signal that the user switched the status-line display off.
    /// Beside `trackingDisabledMarkerURL`, modelled exactly on it.
    public var statusLineDisplayOffMarkerURL: URL {
        settingsURL.deletingLastPathComponent()
            .appendingPathComponent(".\(configuration.name)-status-line-off")
    }

    /// The retired capture script's home, next to `settings.json`, when the
    /// configuration names one.
    var legacyCaptureScriptURL: URL? {
        configuration.legacy.captureScriptName.map {
            settingsURL.deletingLastPathComponent().appendingPathComponent($0)
        }
    }

    // MARK: - Init

    public init(configuration: ClaudeHookConfiguration,
                lockTimeout: TimeInterval = 5,
                helperIsExecutable: @escaping @Sendable (String) -> Bool =
                    ClaudeHookInstaller.defaultHelperIsExecutable) {
        self.configuration = configuration
        self.lockTimeout = lockTimeout
        self.statusLine = ClaudeStatusLine(
            claudeDirectory: configuration.settingsURL.deletingLastPathComponent(),
            bundledDispatcher: configuration.resolvedBundledDispatcher)
        self.helperIsExecutable = helperIsExecutable
    }

    // MARK: - Commands

    /// The command this owner registers with the shared status-line dispatcher
    /// (`ClaudeStatusLine`) as its entry `statusLineEntryName`. Claude Code
    /// delivers the status-line payload (the only carrier of `rate_limits`)
    /// through the dispatcher to this command. The `statusLine` config slot —
    /// NOT the `hooks` map — so `StatusLine` stays excluded from hook
    /// registration (no "Unknown hook event"). Names the helper by absolute
    /// path, so it follows the bundle. With the display switched off, or for a
    /// tap-only configuration, it adds `--capture-only` and is registered as a
    /// tap: Claude Code still feeds the payload but nothing is rendered.
    public var statusLineCommand: String {
        ([ShellQuoting.quoteIfNeeded(helperPath)] + configuration.statusLineArguments).joined(separator: " ")
            + (isStatusLineDisplayWanted ? "" : " --capture-only")
    }

    func isPreviousStatusLineCommand(_ command: String) -> Bool {
        configuration.legacy.statusLineCommands.contains(command)
    }

    // MARK: - Status-line display marker

    /// The user's choice alone: true unless they switched the display off (a
    /// tap-only configuration never displays). It picks the form of
    /// `statusLineCommand`; whether Claude Code actually draws our line is
    /// `isStatusLineDisplayed`.
    var isStatusLineDisplayWanted: Bool {
        !configuration.statusLineTapOnly
            && !FileManager.default.fileExists(atPath: statusLineDisplayOffMarkerURL.path)
    }

    /// True only when the display is wanted AND Claude Code draws our line:
    /// `settings.json`'s `statusLine` is exactly the command that runs this
    /// install's dispatcher, the dispatcher is on disk, and this owner is
    /// registered with it as a renderer. Anything
    /// else reads false, so Manage Tools never shows the display as installed
    /// while Claude Code runs something else.
    public var isStatusLineDisplayed: Bool {
        guard isStatusLineDisplayWanted, let settings = try? loadSettings() else { return false }
        return isDrawingOurStatusLine(settings)
    }

    /// Why Claude Code's line is missing this owner's part right now: the
    /// dispatcher's record of our renderer's last failure. The dispatcher keeps
    /// any other renderer drawing and drops ours, so `isStatusLineDisplayed`
    /// alone cannot see it. Nil while the renderer succeeds.
    public var statusLineError: String? {
        statusLine.lastError(of: configuration.statusLineEntryName)
    }

    private func isDrawingOurStatusLine(_ settings: [String: Any]) -> Bool {
        Self.statusLineSlotCommand(settings).trimmingCharacters(in: .whitespacesAndNewlines)
            == statusLine.dispatcherCommand
            && FileManager.default.fileExists(atPath: statusLine.dispatcherURL.path)
            && statusLine.entry(named: configuration.statusLineEntryName).map {
                $0.kind == .renderers && !$0.command.hasSuffix(" --capture-only")
            } == true
    }

    private static func statusLineSlotCommand(_ settings: [String: Any]) -> String {
        ((settings["statusLine"] as? [String: Any])?["command"] as? String) ?? ""
    }

    /// Writes or removes the display-off marker and re-reconciles
    /// `settings.json`, both under the settings lock, so no other process sees
    /// the new marker before the `statusLine` command has followed it. The
    /// command is only rewritten when `helperPath` is runnable.
    ///
    /// With tracking on, the switch re-registers this owner with the
    /// dispatcher (a renderer when on, a `--capture-only` tap when off) and
    /// takes the slot if it is not the dispatcher's yet: the first-run setup
    /// asks for the line before the daemon's own install may have registered
    /// it. With tracking off nothing of ours is registered, and the switch
    /// only records the choice.
    ///
    /// Turning the display ON throws when, afterwards, Claude Code still does
    /// not draw our line, naming what blocked it (tracking off, a missing
    /// the helper, the status-line step's own error), so the caller reports a
    /// failure instead of a silent success. Turning it off never throws for
    /// those: the choice is recorded, and there is nothing of ours to stop
    /// drawing.
    public func setStatusLineDisplay(_ enabled: Bool) throws {
        // A tap-only configuration never displays: nothing to switch.
        guard !configuration.statusLineTapOnly else { return }
        try withSettingsLock {
            let url = statusLineDisplayOffMarkerURL
            let fileManager = FileManager.default
            if enabled {
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                    logger.info("Status-line display turned on")
                }
            } else if !fileManager.fileExists(atPath: url.path) {
                try Data().write(to: url, options: .atomic)
                logger.info("Status-line display turned off; the capture tap stays")
            }
            var settings = try loadSettings()
            var failure: Error?
            if helperIsExecutable(helperPath), !isTrackingDisabled() {
                do {
                    if let updated = try settingsRegisteringStatusLine(settings) {
                        try saveSettings(updated)
                        settings = updated
                    }
                } catch {
                    logger.error("Status line not registered: \(error.localizedDescription, privacy: .public)")
                    failure = error
                }
            }
            guard enabled, !isDrawingOurStatusLine(settings) else { return }
            if let failure { throw failure }
            if !helperIsExecutable(helperPath) { throw ClaudeHookInstallerError.helperNotExecutable(helperPath) }
            throw ClaudeHookInstallerError.statusLineNotRegistered(
                entry: configuration.statusLineEntryName, trackingDisabled: isTrackingDisabled())
        }
    }

    // MARK: - Tracking marker

    public func isTrackingDisabled() -> Bool {
        FileManager.default.fileExists(atPath: trackingDisabledMarkerURL.path)
    }

    public func setTrackingDisabled(_ disabled: Bool) throws {
        let url = trackingDisabledMarkerURL
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if disabled {
            if !fileManager.fileExists(atPath: url.path) {
                try Data().write(to: url, options: .atomic)
            }
        } else if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Install

    public enum InstallResult: Equatable {
        case installed
        case alreadyInstalled
        case failed(String)
    }

    @discardableResult
    public func installHooks() -> InstallResult {
        do {
            return try withSettingsLock { try installHooksLocked() }
        } catch {
            logger.error("Install failed: \(error.localizedDescription, privacy: .public)")
            return .failed(error.localizedDescription)
        }
    }

    private func installHooksLocked() throws -> InstallResult {
        // Never point a hook at a the helper that is not there (a build directory
        // since cleaned, a path that was never a bundle): every hook would then
        // fail silently behind its `exit 0` and capture would stop with no error
        // anywhere. Leave what is registered alone instead.
        guard helperIsExecutable(helperPath) else {
            let helperName = URL(fileURLWithPath: helperPath).lastPathComponent
            let message = "\(helperName) is not an executable file at \(helperPath); hooks left as they are"
            logger.error("\(message, privacy: .public)")
            return .failed(message)
        }
        let result = try reconcileLocked()
        // Only once settings.json no longer names it (a failed save throws past
        // here), so a failure never leaves hooks pointing at a deleted script.
        removeLegacyCaptureScript()
        return result
    }

    private func reconcileLocked() throws -> InstallResult {
        var settings = try loadSettings()
        var mutated = false

        // Prior versions registered hooks under event types Claude Code doesn't
        // accept — either delegation types (WorktreeCreate, WorktreeRemove) that
        // broke the owning tools, or non-hook types (StatusLine) that triggered
        // an "Unknown hook event" warning. Scrub any hook of ours — current
        // marker or legacy — from those slots on every install.
        if hasStaleExcludedHooks(in: settings) {
            settings = scrubExcludedHooks(from: settings)
            mutated = true
            logger.info("Removed stale hooks for excluded event types")
        }

        // Upgrade: remove every registration of ours that is not the current
        // rendering for its event — `http`, v1–v7 bash, or a stale v8 command —
        // so the reconciliation pass below re-adds it in the current form.
        if hasLegacyHooks(in: settings) {
            settings = removeLegacyHooks(from: settings)
            mutated = true
            logger.info("Removed legacy hooks before upgrade")
        }

        // Register with the shared status-line dispatcher — the only way
        // anything sees the StatusLine payload (and thus rate_limits).
        // Registering it next to the hooks makes the daemon's feed
        // renderer-independent. Another tool's command in the slot is kept as
        // a dispatcher entry, never dropped. Any status-line failure (no
        // dispatcher in the bundle, an unwritable claudehelpers directory, a
        // full disk) loses only the status line, never event capture; turning
        // the display on reports why.
        do {
            if let registered = try settingsRegisteringStatusLine(settings) {
                settings = registered
                mutated = true
                logger.info("Pointed statusLine at the shared dispatcher")
            }
        } catch {
            logger.error("""
                Status line not registered, statusLine left as it was: \
                \(error.localizedDescription, privacy: .public)
                """)
        }

        // Reconciliation pass: any EventType in hookedEventTypes that doesn't
        // already have our marker gets added. This handles both first install
        // (nothing registered yet) and subsequent additions of new EventType
        // cases — additive registration is idempotent and doesn't require
        // bumping the marker.
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        var added: [String] = []
        for eventType in hookedEventTypes where !isMarkerPresent(for: eventType, in: hooks) {
            hooks = appendHook(eventType: eventType, to: hooks)
            added.append(eventType)
        }

        if added.isEmpty {
            if mutated {
                // No new hook event types, but settings DID change (statusLine
                // adopted, or a stale/legacy hook scrubbed) — persist and report
                // .installed so callers see the mutation, not .alreadyInstalled.
                try saveSettings(settings)
                logger.info("Hooks up to date; statusLine/scrub changes saved")
                return .installed
            }
            logger.info("Hooks already installed")
            return .alreadyInstalled
        }

        settings["hooks"] = hooks
        try saveSettings(settings)
        logger.info("Installed hooks for \(added.count) event type(s): \(added.joined(separator: ", "))")
        return .installed
    }

    @discardableResult
    public func uninstallHooks() -> Bool {
        do {
            return try withSettingsLock { try uninstallHooksLocked() }
        } catch {
            logger.error("Uninstall failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func uninstallHooksLocked() throws -> Bool {
        var settings = try loadSettings()
        var removed = false

        // Scan all hook types in the settings file, not just our known list
        if var hooks = settings["hooks"] as? [String: Any] {
            for (eventType, value) in hooks {
                guard var groups = value as? [[String: Any]] else { continue }
                let before = groups.count
                groups = groups.filter { !isOurGroup($0) }
                if groups.count < before { removed = true }
                hooks[eventType] = groups.isEmpty ? nil : groups
            }
            if removed {
                // Remove keys with nil values
                hooks = hooks.compactMapValues { $0 }
                settings["hooks"] = hooks.isEmpty ? nil : hooks
            }
        }

        let release = statusLineRelease(settings)
        if let released = release.settings {
            settings = released
            removed = true
        }

        if removed {
            try saveSettings(settings)
            logger.info("Hooks removed")
        }
        if let released = release.settings {
            let restored = Self.statusLineSlotCommand(released)
            if restored.isEmpty {
                logger.info("Removed the statusLine slot")
            } else {
                logger.info("Handed the statusLine slot back to \(restored, privacy: .public)")
            }
        }
        // Only after the save: a failed save leaves the slot and every entry
        // as they were, never a slot pointing at entries already deleted. A
        // status-line file error costs only those files, never the hooks.
        for name in release.entriesToRemove {
            do {
                if try statusLine.unregister(name) {
                    removed = true
                    logger.info("Removed status-line entry \(name, privacy: .public)")
                }
            } catch {
                logger.error("""
                    Could not remove status-line entry \(name, privacy: .public): \
                    \(error.localizedDescription, privacy: .public)
                    """)
            }
        }
        return removed
    }

    /// Removes the retired capture script next to `settings.json`,
    /// but only a file that is ours: a regular file (never a symlink or FIFO),
    /// whose first line carries the hook marker or whose second line starts with
    /// a shipped script's exact docstring. Only the first 4 KiB is read.
    /// Anything else by that name is left alone.
    func removeLegacyCaptureScript() {
        guard let url = legacyCaptureScriptURL else { return }
        // O_NOFOLLOW|O_NONBLOCK: a symlink fails to open and a FIFO never
        // blocks; the fstat on the opened descriptor closes the check/open race.
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { return }
        var info = stat()
        guard fstat(descriptor, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else {
            close(descriptor)
            return
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        let head = (try? handle.read(upToCount: 4096)) ?? nil
        try? handle.close()
        guard let head else { return }
        let lines = (String(bytes: head, encoding: .utf8) ?? "")
            .split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: false)
        let first = lines.first.map(String.init) ?? ""
        let second = lines.count > 1 ? String(lines[1]) : ""
        guard first.contains(configuration.marker)
                || configuration.legacy.captureScriptSecondLinePrefixes
                    .contains(where: second.hasPrefix) else { return }
        do {
            try FileManager.default.removeItem(at: url)
            logger.info("Removed retired capture script at \(url.path, privacy: .public)")
        } catch {
            logger.error("Could not remove capture script: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Registers this owner with the dispatcher (a renderer while the display
    /// is wanted, else a tap), installs the bundled dispatcher unless a newer
    /// one is there, and returns `settings` with the slot running the
    /// dispatcher, or nil when the slot already does. A command of another
    /// tool's found in the slot is adopted as a renderer, so it keeps showing;
    /// one of our own earlier forms is simply replaced, and one some other
    /// installer already adopted is removed, so our line is never drawn twice.
    ///
    /// Our entry is written first, so switching the display on or off takes
    /// effect even when this bundle's dispatcher cannot be installed.
    private func settingsRegisteringStatusLine(_ settings: [String: Any]) throws -> [String: Any]? {
        let kind: ClaudeStatusLine.Kind = isStatusLineDisplayWanted ? .renderers : .taps
        let command = statusLineCommand
        if try statusLine.register(kind, name: configuration.statusLineEntryName, command: command) {
            logger.info("""
                Registered with the status-line dispatcher as \(kind.rawValue, privacy: .public): \
                \(command, privacy: .public)
                """)
        }
        for name in ownAdoptedEntryNames() {
            try statusLine.unregister(name)
            logger.info("Removed our own earlier statusLine command, adopted as \(name, privacy: .public)")
        }
        logDispatcherInstall(try statusLine.installDispatcher())
        let current = Self.statusLineSlotCommand(settings)
        guard current != statusLine.dispatcherCommand else { return nil }
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !ClaudeStatusLine.isDispatcherCommand(trimmed), !isOwnStatusLineCommand(trimmed),
           let name = try statusLine.adopt(trimmed) {
            logger.info("""
                Kept the previous statusLine command as dispatcher renderer \(name, privacy: .public): \
                \(trimmed, privacy: .public)
                """)
        }
        let replaced = trimmed.isEmpty ? "an empty slot" : trimmed
        logger.info("Pointed the statusLine slot at the dispatcher, replacing \(replaced, privacy: .public)")
        var slot = settings["statusLine"] as? [String: Any] ?? [:]
        slot["type"] = "command"
        slot["command"] = statusLine.dispatcherCommand
        var result = settings
        result["statusLine"] = slot
        return result
    }

    /// One line for what `installDispatcher` did, none when this build's copy
    /// was already the one installed.
    private func logDispatcherInstall(_ install: ClaudeStatusLine.DispatcherInstall) {
        let offered = install.offered.map(String.init) ?? "none"
        let installed = install.installed.map(String.init) ?? "none"
        if install.wrote {
            logger.info("""
                Installed status-line dispatcher \(offered, privacy: .public), \
                replacing \(installed, privacy: .public)
                """)
        } else if install.installed != install.offered {
            logger.info("""
                Kept the installed status-line dispatcher \(installed, privacy: .public); \
                this build carries \(offered, privacy: .public)
                """)
        }
    }

    /// `adopted*` renderers that hold one of this owner's own commands:
    /// left there when another installer took the slot from an earlier build.
    private func ownAdoptedEntryNames(in entries: [ClaudeStatusLine.Entry]? = nil) -> [String] {
        (entries ?? statusLine.entries())
            .filter { $0.kind == .renderers && ClaudeStatusLine.isAdoptedName($0.name)
                && isOwnStatusLineCommand($0.command) }
            .map(\.name)
    }

    /// What uninstalling does to the status line, decided without touching a
    /// file: `settings` with the slot handed back (nil when unchanged), and our
    /// entries, to delete once that is saved.
    ///
    /// The slot is handed back only when our entry was there, so it is our
    /// leaving that frees it: with nothing else registered the slot is emptied;
    /// with only one adopted renderer left, its command goes back into the
    /// slot. That entry is not ours, so it stays where it is, inert. Any other
    /// tool still registered keeps the dispatcher, and with tracking already
    /// off a daemon start never undoes another tool's install. One of our own
    /// earlier forms in the slot is removed, so an uninstall never leaves the
    /// slot on a script `uninstall.sh` deletes.
    private func statusLineRelease(_ settings: [String: Any]) -> (settings: [String: Any]?, entriesToRemove: [String]) {
        let entries = statusLine.entries()
        let ownAdopted = ownAdoptedEntryNames(in: entries)
        let registered = entries.contains { $0.name == configuration.statusLineEntryName }
        let entriesToRemove = (registered ? [configuration.statusLineEntryName] : []) + ownAdopted
        let current = Self.statusLineSlotCommand(settings).trimmingCharacters(in: .whitespacesAndNewlines)
        var result = settings
        if ClaudeStatusLine.isDispatcherCommand(current) {
            guard registered else { return (nil, entriesToRemove) }
            let remaining = entries.filter { !entriesToRemove.contains($0.name) }
            if remaining.isEmpty {
                result["statusLine"] = nil
            } else if remaining.count == 1, let only = remaining.first, only.kind == .renderers,
                      ClaudeStatusLine.isAdoptedName(only.name) {
                var slot = settings["statusLine"] as? [String: Any] ?? [:]
                slot["command"] = only.command
                result["statusLine"] = slot
            } else {
                return (nil, entriesToRemove)
            }
        } else if !current.isEmpty, isOwnStatusLineCommand(current) {
            result["statusLine"] = nil
        } else {
            return (nil, entriesToRemove)
        }
        return (result, entriesToRemove)
    }

    /// A statusLine command that is exactly a bundle's own the helper, wherever
    /// that bundle has since moved: the whole trimmed command is an (optionally
    /// single-quoted) path ending in `/Contents/Helpers/<helper>`, then
    /// ` statusline`, then optionally ` --capture-only` — nothing else, so a
    /// wrapper around it (`mine.sh && …/<helper> statusline`) stays foreign.
    func isBundleStatusLineCommand(_ command: String) -> Bool {
        var rest = command.trimmingCharacters(in: .whitespaces)
        if rest.hasSuffix(" --capture-only") { rest.removeLast(" --capture-only".count) }
        let statusLineSuffix = " " + configuration.statusLineArguments.joined(separator: " ")
        guard rest.hasSuffix(statusLineSuffix) else { return false }
        rest.removeLast(statusLineSuffix.count)
        var path = rest
        if rest.hasPrefix("'") && rest.hasSuffix("'") && rest.count >= 2 {
            path = String(rest.dropFirst().dropLast())
                .replacingOccurrences(of: "'\"'\"'", with: "'", options: .literal)
        }
        // The token must round-trip through ShellQuoting exactly (or be that
        // path always-quoted), so a quoted wrapper such as
        // `'/opt/my tool' && '…/<helper>'` can never pass for one quoted path.
        let alwaysQuoted = "'" + path.replacingOccurrences(of: "'", with: "'\"'\"'", options: .literal) + "'"
        guard rest == ShellQuoting.quoteIfNeeded(path) || rest == alwaysQuoted else { return false }
        return path.hasPrefix("/")
            && path.hasSuffix("/Contents/Helpers/" + URL(fileURLWithPath: helperPath).lastPathComponent)
    }

    /// Holds an exclusive `flock` on the lock files next to `settings.json`
    /// for the duration of `work`: claudehelpers' shared `.settings.lock`,
    /// which every tool following that contract takes, then
    /// the owner's own lock, the only one earlier builds take, so
    /// an older app or daemon still running across an update is shut out too.
    /// Always in that order, so two holders can never deadlock. `flock` is
    /// process-scoped and released automatically on close — the `defer`
    /// covers normal return, early throw, and process crash alike.
    ///
    /// The shared lock is one any other tool can hold, so it is never waited
    /// on without end: past `lockTimeout` the call throws `lockAcquireFailed`
    /// and the caller reports it, instead of the daemon hanging on a script
    /// someone stopped in a debugger. Opened read-only, since `flock` needs no
    /// write access and the file may belong to another tool.
    private func withSettingsLock<T>(_ work: () throws -> T) throws -> T {
        let parent = settingsURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        var descriptors: [Int32] = []
        defer { descriptors.forEach { close($0) } }
        let deadline = Date().addingTimeInterval(lockTimeout)
        for name in [ClaudeStatusLine.settingsLockName, configuration.ownLockName] {
            let path = parent.appendingPathComponent(name).path
            let descriptor = open(path, O_RDONLY | O_CREAT | O_CLOEXEC, 0o644)
            guard descriptor >= 0 else {
                throw ClaudeHookInstallerError.lockOpenFailed(String(cString: strerror(errno)))
            }
            descriptors.append(descriptor)
            while flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
                guard errno == EWOULDBLOCK || errno == EINTR else {
                    throw ClaudeHookInstallerError.lockAcquireFailed(String(cString: strerror(errno)))
                }
                guard Date() < deadline else {
                    throw ClaudeHookInstallerError.lockAcquireFailed(
                        "\(path) is still held by another process after \(Int(lockTimeout.rounded(.up)))s")
                }
                usleep(50_000)
            }
        }
        return try work()
    }

    // MARK: - Detection

    func isInstalled(in settings: [String: Any]) -> Bool {
        guard let hooks = settings["hooks"] as? [String: Any] else { return false }
        for eventType in hookedEventTypes where isMarkerPresent(for: eventType, in: hooks) {
            return true
        }
        return false
    }

    /// True if the current marker (not just any earlier marker) is registered
    /// for `eventType`. Used by the reconciliation loop in `installHooks` so that
    /// adding a new `EventType` case is enough to register a hook for it on the
    /// next daemon start — no marker bump required.
    private func isMarkerPresent(for eventType: String, in hooks: [String: Any]) -> Bool {
        guard let groups = hooks[eventType] as? [[String: Any]] else { return false }
        return groups.contains { isCurrentGroup($0, eventType: eventType) }
    }

    /// A `statusLine` command that is one of this owner's own, current or
    /// earlier: replaced outright when the dispatcher takes the slot, where
    /// another tool's command is adopted instead.
    ///
    /// A marker-bearing command counts as ours: an earlier build's install
    /// swapped this slot onto the capture script with `StatusLine`
    /// for the length of an install, and that script renders nothing. So does
    /// the legacy status-line renderer, whose command always ends
    /// in `... -m statusline.dispatcher` — hasSuffix, not contains, so a
    /// foreign command that merely embeds that substring (e.g.
    /// ".../statusline.dispatcher-v2", or a wrapper that runs it as one step)
    /// is adopted, not dropped.
    /// Compared trimmed, the same way install reads the slot, so uninstall
    /// recognises exactly what install would have replaced.
    private func isOwnStatusLineCommand(_ command: String) -> Bool {
        let command = command.trimmingCharacters(in: .whitespacesAndNewlines)
        return command.contains(configuration.marker)
            || command == statusLineCommand
            || isBundleStatusLineCommand(command)
            || isPreviousStatusLineCommand(command)
            || configuration.legacy.statusLineCommandSuffixes.contains { command.hasSuffix($0) }
    }

    private func hasStaleExcludedHooks(in settings: [String: Any]) -> Bool {
        guard let hooks = settings["hooks"] as? [String: Any] else { return false }
        for eventType in Self.excludedEventTypes {
            guard let groups = hooks[eventType] as? [[String: Any]] else { continue }
            if groups.contains(where: isOwnGroup) {
                return true
            }
        }
        return false
    }

    private func scrubExcludedHooks(from settings: [String: Any]) -> [String: Any] {
        guard var hooks = settings["hooks"] as? [String: Any] else { return settings }
        for eventType in Self.excludedEventTypes {
            guard var groups = hooks[eventType] as? [[String: Any]] else { continue }
            groups = groups.filter { !isOwnGroup($0) }
            hooks[eventType] = groups.isEmpty ? nil : groups
        }
        hooks = hooks.compactMapValues { $0 }
        var result = settings
        result["hooks"] = hooks.isEmpty ? nil : hooks
        return result
    }

    /// Event types with a current or legacy hook of ours in `settings`.
    public func installedEventTypes(in settings: [String: Any]) -> Set<String> {
        guard let hooks = settings["hooks"] as? [String: Any] else { return [] }
        var result: Set<String> = []
        for (event, value) in hooks {
            guard let groups = value as? [[String: Any]] else { continue }
            if groups.contains(where: isOwnGroup) {
                result.insert(event)
            }
        }
        return result
    }

    /// A single hook entry in the legacy `http` form: `type: "http"` with a url
    /// under `httpHookURLBase`. The url path segment is the event type.
    func isHTTPHook(_ hook: [String: Any]) -> Bool {
        guard let base = configuration.legacy.httpHookURLBase else { return false }
        return (hook["type"] as? String) == "http" && ((hook["url"] as? String)?.hasPrefix(base) == true)
    }

    /// A single hook entry that is ours in any form: the legacy `http`
    /// hook, or a `command` carrying `marker` (which every marker version
    /// starts with). Whether it is current is `isCurrentHook`'s call alone.
    func isOwnHook(_ hook: [String: Any]) -> Bool {
        isHTTPHook(hook) || (hook["command"] as? String)?.contains(configuration.marker) == true
    }

    /// True when `hook` is exactly what this installer registers for `eventType`.
    func isCurrentHook(_ hook: [String: Any], eventType: String) -> Bool {
        (hook["type"] as? String) == "command"
            && (hook["command"] as? String) == makeCommand(eventType: eventType)
    }

    /// A group carrying our *current* registration for `eventType`.
    func isCurrentGroup(_ group: [String: Any], eventType: String) -> Bool {
        guard let hookList = group["hooks"] as? [[String: Any]] else { return false }
        return hookList.contains { isCurrentHook($0, eventType: eventType) }
    }

    /// A group that is ours in any form — current, `http`, or legacy
    /// bash. Drives scrub / enumerate / uninstall so the migration cleans up all.
    private func isOwnGroup(_ group: [String: Any]) -> Bool {
        guard let hookList = group["hooks"] as? [[String: Any]] else { return false }
        return hookList.contains(where: isOwnHook)
    }

    private func hasLegacyHooks(in settings: [String: Any]) -> Bool {
        guard let hooks = settings["hooks"] as? [String: Any] else { return false }
        for (eventType, value) in hooks {
            guard let groups = value as? [[String: Any]] else { continue }
            for group in groups where isLegacyGroup(group, eventType: eventType) {
                return true
            }
        }
        return false
    }

    /// Drops each of OUR stale entries from its matcher group (a foreign hook
    /// sharing the group survives), and the group itself only once it is empty.
    private func removeLegacyHooks(from settings: [String: Any]) -> [String: Any] {
        guard let hooks = settings["hooks"] as? [String: Any] else { return settings }
        var updated = [String: Any]()
        for (eventType, value) in hooks {
            guard let groups = value as? [[String: Any]] else {
                updated[eventType] = value
                continue
            }
            var kept = [[String: Any]]()
            for var group in groups {
                guard var hookList = group["hooks"] as? [[String: Any]],
                      isLegacyGroup(group, eventType: eventType) else {
                    kept.append(group)
                    continue
                }
                hookList.removeAll { isOwnHook($0) && !isCurrentHook($0, eventType: eventType) }
                if hookList.isEmpty { continue }
                group["hooks"] = hookList
                kept.append(group)
            }
            if !kept.isEmpty { updated[eventType] = kept }
        }
        var result = settings
        result["hooks"] = updated.isEmpty ? nil : updated
        return result
    }

    /// Every group of ours — current, `http` or legacy bash. Uninstall
    /// removes all of them, so a machine upgraded across migrations is left clean.
    private func isOurGroup(_ group: [String: Any]) -> Bool {
        isOwnGroup(group)
    }

    /// A group holding a hook of ours that is not the current rendering for
    /// `eventType` — an `http` hook, a v1–v7 bash hook, the retired python
    /// capture-script hook, or a hook whose path has gone stale (the
    /// bundle moved).
    private func isLegacyGroup(_ group: [String: Any], eventType: String) -> Bool {
        guard let hookList = group["hooks"] as? [[String: Any]] else { return false }
        return hookList.contains {
            isOwnHook($0) && !isCurrentHook($0, eventType: eventType)
        }
    }

    // MARK: - Hook Command Generation

    private func appendHook(eventType: String, to hooks: [String: Any]) -> [String: Any] {
        var result = hooks
        var groups = (hooks[eventType] as? [[String: Any]]) ?? []
        groups.append(makeMatcherGroup(eventType: eventType))
        result[eventType] = groups
        return result
    }

    /// The `settings.json` entry registered per event: a `command`
    /// hook running the bundled the helper (`makeCommand`). `async: true` keeps it
    /// off Claude's critical path; `timeout: 10` bounds it.
    private func makeMatcherGroup(eventType: String) -> [String: Any] {
        [
            "hooks": [
                [
                    "type": "command",
                    "command": makeCommand(eventType: eventType),
                    "async": true,
                    "timeout": 10
                ]
            ]
        ]
    }

    /// The rendered `command` body: marker line, `'<helper>' hook --event
    /// <Event>`, `exit 0`. The bundle's the helper by absolute path, so it runs
    /// under the minimal PATH a GUI-launched session hands its hooks; each word
    /// shell-quoted (`shellQuote`), because a bundle path may hold spaces
    /// (`/Users/Jane Smith/…`). The trailing `exit 0` means even a the helper that
    /// fails to start never surfaces as a hook error. No `--ppid $PPID`:
    /// the hook helper finds the `claude` pid itself, so
    /// the command `isCurrentHook` compares against stays this one line.
    public func makeCommand(eventType: String) -> String {
        ([configuration.marker + "\n" + ShellQuoting.quoteIfNeeded(helperPath)] + configuration.hookArguments
            + [ShellQuoting.quoteIfNeeded(eventType)]).joined(separator: " ") + "\nexit 0"
    }

    // MARK: - Settings I/O

    func loadSettings() throws -> [String: Any] {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: settingsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        guard fileManager.fileExists(atPath: settingsURL.path) else { return [:] }
        let data = try Data(contentsOf: settingsURL)
        if data.isEmpty { return [:] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudeHookInstallerError.invalidFormat
        }
        return json
    }

    /// Atomic, and keeps the file's permissions (`0600` for a new one), as
    /// claudehelpers' settings contract asks: `settings.json` may hold tokens.
    /// The new file is created at that mode before it replaces the old one,
    /// and a symlinked `settings.json` keeps its link (`AtomicFile`).
    func saveSettings(_ settings: [String: Any]) throws {
        try FileManager.default.createDirectory(
            at: settingsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
        )
        try AtomicFile.write(data, to: settingsURL, mode: AtomicFile.mode(of: settingsURL) ?? 0o600)
    }
}

public enum ClaudeHookInstallerError: Error, LocalizedError {
    case invalidFormat
    case lockOpenFailed(String)
    case lockAcquireFailed(String)
    case helperNotExecutable(String)
    case statusLineNotRegistered(entry: String, trackingDisabled: Bool)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat: "settings.json is not a valid JSON object"
        case .lockOpenFailed(let msg): "Failed to open settings lock file: \(msg)"
        case .lockAcquireFailed(let msg): "Failed to acquire settings lock: \(msg)"
        case .helperNotExecutable(let path):
            "\(URL(fileURLWithPath: path).lastPathComponent) is not an executable file at \(path), "
                + "so the status line was not registered."
        case .statusLineNotRegistered(let entry, let trackingDisabled):
            trackingDisabled
                ? "Claude Code tracking is off, so no \(entry.capitalized) status line is registered. "
                    + "Turn tracking on first."
                : "No \(entry.capitalized) status line is registered in ~/.claude/settings.json."
        }
    }
}

extension ClaudeHookInstaller: Loggable {
    public static nonisolated let logger = makeLogger()
}
