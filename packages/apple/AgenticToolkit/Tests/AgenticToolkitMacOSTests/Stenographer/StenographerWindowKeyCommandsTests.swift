import XCTest
@preconcurrency import KeyboardShortcuts
@testable import AgenticToolkitMacOS

/// The system-wide key commands that open the Stenographer-fed windows.
///
/// Bindings persist through `UserSettings`, which every registry shares; these
/// tests only read defaults and never record a binding, so nothing is reset.
@MainActor
final class StenographerWindowKeyCommandsTests: XCTestCase {

    private func commands() -> [KeyCommandDescriptor] {
        let service = StubDaemonService()
        let registry = CommandRegistry()
        return [
            SessionsCoordinator(service: service, commandRegistry: registry).keyCommand(),
            ConversationsCoordinator(service: service, commandRegistry: registry).keyCommand(),
            OversightCoordinator(service: service, commandRegistry: registry).keyCommand(),
            AILogCoordinator(service: service, commandRegistry: registry).keyCommand()
        ]
    }

    /// The ids are binding keys, so they are pinned: they are the names
    /// Stenographer's scripting and key commands used for the same windows.
    func testCommandIDsAreTheWindowNames() {
        XCTAssertEqual(commands().map(\.id),
                       ["window.sessions", "window.conversations", "window.ai-oversight", "window.ai-log"])
        XCTAssertEqual(StenographerWindowKeyCommands.commandID(windowID: SessionsCoordinator.windowID),
                       "window.sessions")
    }

    /// A system-wide hotkey is taken from whatever app the user is in, so
    /// every one ships off until the user switches it on.
    func testEveryCommandIsGlobalAndShipsSwitchedOff() {
        let section = StenographerWindowKeyCommands.section(commands: commands())
        XCTAssertEqual(section.title, "Windows")
        XCTAssertEqual(section.scope, .global)
        XCTAssertEqual(section.allCommands.count, 4)
        for command in section.allCommands {
            XCTAssertEqual(command.scope, .global, command.id)
            XCTAssertFalse(command.isEnabledByDefault, command.id)
        }
    }

    /// Only the two Stenographer suggested a chord for keep one; ⌥ keeps them
    /// clear of a host's ⌃⌘ / ⇧⌃⌘ menu equivalents.
    func testOnlySessionsAndConversationsSuggestAChord() {
        let chords = Dictionary(uniqueKeysWithValues: commands().map { ($0.id, $0.defaultShortcut) })
        XCTAssertEqual(chords["window.sessions"], .init(.s, modifiers: [.command, .control, .option]))
        XCTAssertEqual(chords["window.conversations"], .init(.c, modifiers: [.command, .control, .option]))
        XCTAssertNil(chords["window.ai-oversight"] ?? nil)
        XCTAssertNil(chords["window.ai-log"] ?? nil)
    }

    /// Installed at launch, every command is listed and findable whether or
    /// not its window was ever opened.
    func testInstallingListsEveryWindowUnderOneGlobalSection() {
        let registry = KeyCommandRegistry()
        let commands = commands()
        StenographerWindowKeyCommands.install(into: registry, commands: commands)
        XCTAssertEqual(registry.sections(in: .global).map(\.title), ["Windows"])
        for command in commands {
            XCTAssertNotNil(registry.descriptor(for: command.id), command.id)
        }
    }
}
