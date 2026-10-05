
- **AppKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/Features/ConversationsWindow/ConversationsKeyCommands.swift`
  as a `public enum ConversationsKeyCommands` with static constants
  `moveSelectionUpID`, `moveSelectionDownID`, `toggleShelfID`,
  `sectionTitle` and `singleModeFeatureTitle`. `section(resolve:)` takes a
  `@MainActor () -> ConversationsSplitViewController?` and returns a
  `KeyCommandSection` with `scope: .app`. Shortcuts are
  `KeyboardShortcuts.Shortcut` values: Command-0 (`.zero`), Command-Up
  (`.upArrow`) and Command-Down (`.downArrow`). Each descriptor's `perform`
  calls `resolve()?.performToggleShelfCommand() ?? false` or
  `resolve()?.performMoveSelectionCommand(by: -1 / 1) ?? false`.
- **confines-to-ui-thread**: On Apple platforms the type is `@MainActor`-isolated, so the compiler enforces the rule.
- **SwiftUI**: Declare the same commands as `.keyboardShortcut` modifiers on
  menu items bound to the window's model.
- **WinUI 3**: Register `KeyboardAccelerator`s with the same identifiers and
  resolve the window at invocation.

