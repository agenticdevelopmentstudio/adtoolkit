import Foundation

/// Everything that makes one daemon's Claude Code hook registration its own:
/// the marker its entries carry, the helper they run, the drop directory the
/// helper writes to, and the files beside `settings.json` that belong to it.
///
/// Claude Code runs every matching hook entry, so two daemons install their
/// own configuration into the same `settings.json` and coexist: each
/// recognises, updates and removes only the entries carrying its own marker.
public struct ClaudeHookConfiguration: Sendable, Equatable {

    /// Short identifier of the owner (`"stenographer"`, `"adkd"`). Names the
    /// marker files `.<name>-tracking-disabled` and `.<name>-status-line-off`
    /// beside `settings.json`, and the status-line feed lock files.
    public var name: String
    /// Stamped as the first line of every `command` hook this configuration
    /// registers (`"# stenographer-hook"`). A prefix of every earlier marker
    /// version, so one `contains` finds every registration of the owner.
    public var marker: String
    /// Absolute path of the helper executable hooks run.
    public var hookBinaryPath: String
    /// Arguments after the helper for a hook (`["hook", "--event"]`); the
    /// event name is appended.
    public var hookArguments: [String]
    /// Arguments after the helper for the status-line command
    /// (`["statusline"]`); `--capture-only` is appended when the display is off.
    public var statusLineArguments: [String]
    /// True: always register with the status-line dispatcher as a tap with
    /// `--capture-only`, never as a renderer.
    public var statusLineTapOnly: Bool
    /// The drop directory the helper writes envelopes into, in the tilde form
    /// hooks use (`"~/.claude/stenographer-events"`).
    public var dropDirectory: String
    /// The `settings.json` to edit.
    public var settingsURL: URL
    /// Lock file beside `settings.json`, taken AFTER the shared
    /// `.settings.lock` (`".stenographer-hooks.lock"`).
    public var ownLockName: String
    /// This owner's file name under the status-line dispatcher's `renderers`
    /// or `taps` directory.
    public var statusLineEntryName: String
    /// The dispatcher a bundle carries; nil means
    /// `<helper>/../../Resources/dispatch.sh`.
    public var bundledDispatcher: URL?
    /// Event types registered for passive observation.
    public var hookedEvents: [HookEventType]
    /// Earlier forms of this owner's registrations to recognise and replace.
    public var legacy: LegacyHookForms

    public init(name: String,
                marker: String,
                hookBinaryPath: String,
                hookArguments: [String] = ["hook", "--event"],
                statusLineArguments: [String] = ["statusline"],
                statusLineTapOnly: Bool = false,
                dropDirectory: String,
                settingsURL: URL = ClaudeHookConfiguration.defaultSettingsURL,
                ownLockName: String? = nil,
                statusLineEntryName: String? = nil,
                bundledDispatcher: URL? = nil,
                hookedEvents: [HookEventType] = ClaudeHookConfiguration.defaultHookedEvents,
                legacy: LegacyHookForms = .none) {
        self.name = name
        self.marker = marker
        self.hookBinaryPath = hookBinaryPath
        self.hookArguments = hookArguments
        self.statusLineArguments = statusLineArguments
        self.statusLineTapOnly = statusLineTapOnly
        self.dropDirectory = dropDirectory
        self.settingsURL = settingsURL
        self.ownLockName = ownLockName ?? ".\(name)-hooks.lock"
        self.statusLineEntryName = statusLineEntryName ?? name
        self.bundledDispatcher = bundledDispatcher
        self.hookedEvents = hookedEvents
        self.legacy = legacy
    }

    /// `~/.claude/settings.json`.
    public static var defaultSettingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
    }

    /// Every event type except the ones Claude Code cannot take as passive
    /// hooks (`ClaudeHookInstaller.excludedEventTypes`).
    public static var defaultHookedEvents: [HookEventType] {
        HookEventType.allCases.filter { !ClaudeHookInstaller.excludedEventTypes.contains($0.rawValue) }
    }

    /// `<bundle>/Contents/Helpers/<helperName>`, found from the running
    /// executable: `Contents/MacOS/…` for a daemon or app, `Contents/Helpers/…`
    /// for the helper itself. Symlinks on the executable are resolved first, so
    /// a link into a bundle names the bundle's real helper. Hooks run it by this
    /// absolute path, so they follow the bundle wherever it lives.
    public static func bundledHelperPath(named helperName: String,
                                         executable: URL = Bundle.main.executableURL!) -> String {
        let directory = executable.resolvingSymlinksInPath().deletingLastPathComponent()
        if directory.lastPathComponent == "Helpers" {
            return directory.appendingPathComponent(helperName).path
        }
        return directory.deletingLastPathComponent()
            .appendingPathComponent("Helpers/\(helperName)").path
    }

    /// The dispatcher a bundle carries, beside the helper's `Contents/Helpers`:
    /// `Contents/Resources/dispatch.sh`.
    public var resolvedBundledDispatcher: URL {
        bundledDispatcher ?? URL(fileURLWithPath: hookBinaryPath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/dispatch.sh")
    }
}

/// Retired registration forms an owner still recognises, so an install
/// replaces them and an uninstall removes them. `.none` recognises nothing.
public struct LegacyHookForms: Sendable, Equatable {
    /// Base of the retired `http` hook url (`http://127.0.0.1:<port>/hook`).
    public var httpHookURLBase: String?
    /// File name of a retired capture script beside `settings.json`, deleted
    /// on install when it is the owner's.
    public var captureScriptName: String?
    /// Exact starts of line 2 of each shipped capture script.
    public var captureScriptSecondLinePrefixes: [String]
    /// Earlier `statusLine` commands, upgraded on install.
    public var statusLineCommands: Set<String>
    /// Endings of an earlier renderer's `statusLine` command that count as the
    /// owner's own (a hasSuffix match, never contains).
    public var statusLineCommandSuffixes: [String]

    public init(httpHookURLBase: String? = nil,
                captureScriptName: String? = nil,
                captureScriptSecondLinePrefixes: [String] = [],
                statusLineCommands: Set<String> = [],
                statusLineCommandSuffixes: [String] = []) {
        self.httpHookURLBase = httpHookURLBase
        self.captureScriptName = captureScriptName
        self.captureScriptSecondLinePrefixes = captureScriptSecondLinePrefixes
        self.statusLineCommands = statusLineCommands
        self.statusLineCommandSuffixes = statusLineCommandSuffixes
    }

    public static let none = LegacyHookForms()
}
