---
id: 143b0352-49d4-46a9-a922-bb45c4cc0e7e
title: "Conversations Key Commands"
domain: adtoolkit://cookbook/ai/chat/conversations/conversations-key-commands
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Declares the Conversations window's bindable key commands, with default shortcuts, as a section the key-command registry installs at launch."
platforms:
  - swift
  - macos
tags:
  - chat
  - key-commands
  - conversations
depends-on: []
related:
  - adtoolkit://cookbook/ui/controls/key-command-capture-field
  - adtoolkit://cookbook/ui/settings/rows/key-command-row-view
references: []
approved-by: ""
approved-date: ""
---

# Conversations Key Commands

## Overview

The Conversations window's key commands are declared by the window, not by
the settings panel that lists them. The panel is shared and knows nothing
about conversations, and only the window can actually perform them. This
component produces one section of command descriptors that the key-command
registry installs. The registry's single app-wide key monitor performs the
commands; each one asks the live window controller whether the keystroke is
its to take (the Conversations window is key, and the caret is not in a text
field) and passes the key on when it is not. The controller is resolved when
a command runs, not when the section is installed, so the host can declare
the commands at launch, before any Conversations window exists, and the
settings panel lists what the app can do even for a person who has never
opened that window.

## Behavioral Requirements

- **section-identity**: Component MUST produce one section titled
  "Conversations Window" with application-wide scope.
- **command-identifiers**: Component MUST identify its three commands with the
  stable identifiers `conversations.toggleShelf`,
  `conversations.moveSelectionUp` and `conversations.moveSelectionDown`.
- **toggle-shelf-command**: The section MUST list, directly under its title, a
  command titled "Show Conversation List" with the default shortcut
  Command-0, which asks the window to toggle its conversation list.
- **single-mode-feature**: The section MUST group the two selection commands
  under a feature titled "Single Conversation Mode", because they mean
  nothing when several conversations are on screen at once.
- **move-selection-commands**: The feature MUST list "Previous Conversation"
  with the default shortcut Command-Up, which asks the window to move the
  selection by -1, and "Next Conversation" with the default shortcut
  Command-Down, which asks the window to move it by +1.
- **resolve-at-run-time**: Component MUST resolve the window controller each
  time a command runs, not when the section is built, so the section can be
  built and installed while no window exists.
- **absent-window-passes-key-on**: A command MUST do nothing and report that it
  did not take the key when the resolver returns no controller.
- **window-decides-ownership**: A command MUST report whatever the controller
  reports, so the key passes on when the controller declines it.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

Not applicable: this component renders nothing. The settings panel draws the
section; the visible text is the section title, the feature title and the
three command titles named above.

- **Corner radius**: Not applicable.
- **Padding**: Not applicable.
- **Font**: Not applicable.
- **Background**: Not applicable.
- **Foreground/Text**: Not applicable.
- **Border**: Not applicable.
- **Shadow**: Not applicable.
- **Min/Max size**: Not applicable.

## States

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: no visual output of its own |
| Pressed | Not applicable |
| Disabled | Not applicable: a command with no window simply declines the key |
| Focused | Not applicable |
| Loading | Not applicable |
| No window | Commands remain listed and decline every key |
| Window up | Commands act on the window when it is key and no text field has the caret |

## Accessibility

- **Role/trait**: Not applicable; the settings panel supplies controls.
- **Label requirements**: Each command's title is its label: "Show Conversation
  List", "Previous Conversation" and "Next Conversation".
- **Announce state changes**: Not applicable.
- **keyboard-only-operation**: The commands MUST be usable from the keyboard
  alone, which is their whole purpose; each has a default shortcut.
- **Minimum tap target**: Not applicable.
- **Minimum contrast ratio**: Not applicable.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversations-key-commands-001 | section-identity | Build the section | One section titled "Conversations Window" with application-wide scope |
| conversations-key-commands-002 | command-identifiers | Read the identifiers of the three commands | `conversations.toggleShelf`, `conversations.moveSelectionUp`, `conversations.moveSelectionDown` |
| conversations-key-commands-003 | toggle-shelf-command | Read the section's direct commands | Exactly one, titled "Show Conversation List", default Command-0 |
| conversations-key-commands-004 | single-mode-feature | Install the section in a registry and read the settings panel outline | The two selection commands appear under a "Single Conversation Mode" heading, after the toggle command |
| conversations-key-commands-005 | move-selection-commands | Read the feature's commands and run each against a stub controller | "Previous Conversation" is Command-Up and moves by -1; "Next Conversation" is Command-Down and moves by +1 |
| conversations-key-commands-006 | resolve-at-run-time | Build the section with a resolver that counts calls, install it, then run a command | The resolver is not called before the command runs, and is called each time one runs |
| conversations-key-commands-007 | absent-window-passes-key-on | Run each command with a resolver that returns no controller | Each reports that it did not take the key; nothing else happens |
| conversations-key-commands-008 | window-decides-ownership | Run a command against a controller that declines, then one that accepts | The command reports declined, then taken |
| conversations-key-commands-009 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

## Edge Cases

- **Null/empty input**: A resolver that returns no controller is the normal
  case before a window exists (per `absent-window-passes-key-on`).
- **Boundary values**: Moving the selection past either end is the window's
  rule, not this component's; it forwards -1 and +1 only.
- **Concurrent access**: Not applicable: commands run on the UI thread from
  the registry's key monitor.
- **Error states (dependency/network failure)**: Not applicable: no I/O.
- **Offline/disconnected state**: Not applicable.
- **Window closed and reopened** (MUST): because the controller is resolved
  at run time (per `resolve-at-run-time`), commands act on whichever window
  is up when the key is pressed, with no re-installation.
- **Typing in a text field** (MUST): a keystroke the window does not own is
  passed on (per `window-decides-ownership`), so Command-Up in a text field
  keeps its text-editing meaning.

## Configuration

The component takes one input, a resolver returning the live window
controller or none. It exposes the three identifier constants, the section
title and the feature title as fixed values; none is configurable. Shortcut
rebinding belongs to the registry and the settings panel.

## Deep Linking

Not applicable: key commands are not addressable by URL.

## Localization

The section title, the feature title and the three command titles are
English literals in the source with no localization mechanism.

## Accessibility Options

- **Reduce Motion**: Not applicable.
- **Increase Contrast**: Not applicable.
- **Differentiate Without Color**: Not applicable.

## Feature Flags

Not applicable: the section is always declared.

## Analytics

Not applicable: no tracking call exists in the source.

## Privacy

- **Data collected**: None.
- **Storage**: None; chosen shortcuts are stored by the registry.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the source contains no logging call.

## Platform Notes

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

## Reference Implementations

| Platform | Path |
|----------|------|
| apple | `packages/apple/AgenticToolkit/macOS/Features/ConversationsWindow/ConversationsKeyCommands.swift` |

## Design Decisions

**Decision**: The window declares its commands instead of the settings panel.
**Rationale**: The source's doc comment says the panel "is shared and knows
nothing about conversations" and only the window can perform the commands.
**Approved**: pending

**Decision**: The controller is resolved when a command runs, not when the
section is installed.
**Rationale**: The source's doc comment says binding to a live instance would
list the commands only for someone who had already opened the window, "the
wrong way round: the panel is where you go to find out what the app can do."
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because the component only declares commands;
the registry performs them and the window decides ownership.
`no-hardcoded-strings` fails because the titles are English literals with no
localization. `unit-test-coverage` is `partial`: in
`KeyCommands/KeyCommandsPanelHierarchyTests.swift`,
`testTheConversationsWindowListsItsSingleModeCommandsUnderTheMode` installs
the section with a resolver returning `nil` and checks the panel outline
(section title, the toggle command, the "Single Conversation Mode" heading and
the two selection commands in order), which covers section-identity,
toggle-shelf-command and single-mode-feature and uses the identifier
constants. No test checks default shortcuts, what each command passes to the
controller, run-time resolution, or the declined-key behavior.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial spec for the Conversations window key commands, split out of the mock chat session spec where it was misattributed. |
