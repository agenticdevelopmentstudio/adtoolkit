import AppKit
@preconcurrency import KeyboardShortcuts
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// Keyboard control of the newest notice on screen, from any app. Notice
/// panels never take key focus, so these global commands are how a keyboard
/// user acts on them. They are a section of the shared key-command registry,
/// which owns the chords, the off-by-default policy for global commands, the
/// conflict checks and the Keyboard settings panel.
///
/// - act: the notice's primary action
/// - archive
/// - snooze: 15 minutes when the set offers it, else its first option
/// - history
public enum NoticeHotkeys {

    public static let sectionTitle = "Notifications"

    /// The binding the ids are stored under; do not rename.
    enum CommandID {
        static let act = "notice.act"
        static let archive = "notice.archive"
        static let snooze = "notice.snooze"
        static let history = "notice.history"
        static let all = [act, archive, snooze, history]
    }

    /// Marker in the host's defaults: the legacy switch is carried over once.
    static let migratedMarkerKey = "notice_hotkeys_migrated_v1"

    private static let modifiers: NSEvent.ModifierFlags = [.control, .option, .command]

    private static let defaultChords: [String: KeyboardShortcuts.Shortcut] = [
        CommandID.act: .init(.return, modifiers: modifiers),
        CommandID.archive: .init(.delete, modifiers: modifiers),
        CommandID.snooze: .init(.s, modifiers: modifiers),
        CommandID.history: .init(.h, modifiers: modifiers)
    ]

    /// Declares the commands to `registry`. Installing again replaces them.
    @MainActor
    public static func install(center: NoticePresentationCenter, registry: KeyCommandRegistry = .shared) {
        registry.install(section(center: center))
    }

    @MainActor
    static func section(center: NoticePresentationCenter) -> KeyCommandSection {
        func command(_ id: String, _ title: String, perform: @escaping @MainActor (String) -> Bool)
            -> KeyCommandDescriptor {
            KeyCommandDescriptor(id: id, title: title, defaultShortcut: defaultChords[id], perform: {
                // Registry callbacks arrive on the main thread.
                MainActor.assumeIsolated {
                    guard let newest = center.newestShownID else { return false }
                    return perform(newest)
                }
            })
        }
        return KeyCommandSection(
            title: sectionTitle,
            caption: "Act on the newest notification from any app.",
            scope: .global,
            commands: [
                command(CommandID.act, "Act on newest notification") { center.act(id: $0); return true },
                command(CommandID.archive, "Archive newest notification") { center.archive(id: $0); return true },
                command(CommandID.snooze, "Snooze newest notification") { id in
                    let options = center.snoozeOptions(of: id)
                    guard let option = options.contains(.fifteenMinutes) ? .fifteenMinutes : options.first
                    else { return false }
                    center.snooze(id: id, option: option)
                    return true
                },
                KeyCommandDescriptor(
                    id: CommandID.history, title: "Show notification history",
                    defaultShortcut: defaultChords[CommandID.history],
                    run: { MainActor.assumeIsolated { center.showHistory() } })
            ])
    }

    /// Carries the old "global hotkeys" switch over, once. A user who had them
    /// on keeps them on: each command is written with its default chord and
    /// enabled, unless the user already authored that id. Anyone else
    /// (switch off, or never stored) starts with the registry's policy: off.
    /// Run before `install`, so the chords are applied from the start.
    @MainActor
    public static func migrateLegacyHotkeys(
        enabled: Bool?,
        store: SettingsStore = UserSettings.shared,
        defaults: UserDefaults
    ) {
        guard !defaults.bool(forKey: migratedMarkerKey) else { return }
        defer { defaults.set(true, forKey: migratedMarkerKey) }
        guard enabled == true else { return }
        var bindings = store.get(UserSettings.keyCommandBindings)
        for id in CommandID.all where bindings[id] == nil {
            bindings[id] = KeyCommandBinding(shortcut: defaultChords[id], isEnabled: true)
        }
        store.set(bindings, for: UserSettings.keyCommandBindings)
    }
}
