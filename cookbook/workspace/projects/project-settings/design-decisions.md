
**Decision**: `activePaneFollowsMouse` defaults to `false`.
**Rationale**: the source's own doc comment states this directly: focus that moves without being asked to is a preference people hold strongly in both directions, and having keys go somewhere the user did not put them is "the wrong default" (`UserSettings+Projects.swift`).
**Approved**: pending

**Decision**: `GitRepoScanner` receives `projectScanSkipPatterns` as a constructor parameter rather than reading the setting itself.
**Rationale**: the source's own doc comment states the reasoning directly — the scanner runs off the main actor, and a pure walk that is told what to skip is testable without a settings store (`UserSettings+Projects.swift`).
**Approved**: pending

**Decision**: `highlightActivePane` lives alongside the other project settings, and a per-project `ThemeProjectOptions.highlightActivePane` can override it.
**Rationale**: the source's own doc comment states the setting belongs here rather than with the appearance settings because it concerns a project window's panes specifically, and names the override directly (`UserSettings+Projects.swift`); the precedence is confirmed in the consumer, `ComposableTabsActivePane.swift`.
**Approved**: pending

**Decision**: the three storage keys use two different naming conventions — `projectScanSkipPatterns` is camelCase, while `highlight_active_pane` and `active_pane_follows_mouse` are snake_case.
**Rationale**: not stated in the source. The doc comments explain each setting's behavior and default but give no reason for the differing key format between the three (`UserSettings+Projects.swift`).
**Approved**: pending

