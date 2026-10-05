
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

