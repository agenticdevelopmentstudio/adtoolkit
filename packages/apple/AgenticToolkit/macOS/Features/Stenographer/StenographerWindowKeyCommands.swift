import AppKit
import KeyboardShortcuts
import AgenticToolkitCoreMacOS

/// The system-wide key commands that open the Stenographer-fed windows —
/// Sessions, Conversations, AI Oversight, AI Log — in whatever app hosts them.
///
/// One section, "Windows", under the Key Commands panel's Global heading (the
/// scope supplies that heading; the title says what the commands open). Every
/// command ships switched off: a system-wide hotkey is taken away from whatever
/// app the user is in, and that is not done to somebody without being asked.
/// Two carry a suggested chord, the ones Stenographer suggested before the
/// windows moved; ⌥ keeps them clear of a host's ⌃⌘ and ⇧⌃⌘ menu equivalents,
/// which a global chord matching one of them would fire alongside.
@MainActor
public enum StenographerWindowKeyCommands {

    public static let sectionTitle = "Windows"

    /// The storage key a window's binding lives under: `window.<windowID>`, the
    /// id Stenographer's scripting and key commands called the window by.
    public static func commandID(windowID: String) -> String {
        "window.\(windowID)"
    }

    /// One window's command. A hotkey pressed from another app is a request to
    /// come to the front — presenting a window behind whatever the user is
    /// looking at would read as the shortcut not working — so the host is
    /// activated before the window is shown.
    public static func descriptor(
        windowID: String,
        title: String,
        defaultShortcut: KeyboardShortcuts.Shortcut?,
        present: @escaping @MainActor () -> Void
    ) -> KeyCommandDescriptor {
        KeyCommandDescriptor(
            id: commandID(windowID: windowID),
            title: title,
            defaultShortcut: defaultShortcut,
            isEnabledByDefault: false,
            run: {
                NSApp.activateUnlessQuiet()
                present()
            })
    }

    public static func section(commands: [KeyCommandDescriptor]) -> KeyCommandSection {
        KeyCommandSection(title: sectionTitle, scope: .global, commands: commands)
    }

    /// Declare the window commands — at launch, not as windows open: the
    /// Settings panel lists what the registry holds, and a hotkey the user
    /// switched on has to be live whether or not its window was opened this run.
    public static func install(into registry: KeyCommandRegistry = .shared, commands: [KeyCommandDescriptor]) {
        registry.install(section(commands: commands))
    }
}
