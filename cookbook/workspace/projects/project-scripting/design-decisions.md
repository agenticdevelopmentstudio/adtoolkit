
**Decision**: `scriptableProjectWindow(uniqueID:)`, `scriptableProjectTab(uniqueID:)`
and `scriptablePane(uniqueID:)` each search a `.lazy` sequence and stop at the
first match, rather than building the full `scriptableProjectWindows`/`scriptableProjectTabs`/`scriptablePanes`
array and filtering it.
**Rationale**: The doc comment on `scriptableProjectWindow(uniqueID:)` states
the cost this avoids directly: building the full array first would construct
a wrapper "for the windows after the answer" that "are made and thrown away,"
and there is one wrapper per open project, tab, or pane
(`ProjectWindowManager+Scripting.swift`).
**Approved**: pending

**Decision**: `ScriptableProjectWindow` holds its `ComposableTabsWindowController`
weakly, while `ScriptablePane` holds its `ComposableTabsPaneViewController`
strongly (and its window weakly).
**Rationale**: `ScriptableProjectWindow.swift`'s doc comment explains the
window side: "a script can keep a reference to a window it then closes, and
a wrapper is not a reason to keep a window's whole object graph — and its
database handle — alive". `ScriptablePane.swift`'s doc comment
explains the opposite choice for its pane: the wrapper "is made fresh on
every read," Cocoa Scripting "re-resolves a specifier through `panes` rather
than holding a wrapper between events," so "nothing outlives the reply it
was built for" and a strong reference is safe for exactly that long.
**Approved**: pending

**Decision**: A tab's branch that cannot be resolved — no `ProjectController`,
no matching `BranchController`, or a detached HEAD — is reported as the
empty string, never `nil` or a thrown error.
**Rationale**: `ComposableTabsWindowController.scriptingTabs(branch:)`'s doc
comment states this is deliberate: a caller with no branch controller "passes
`{ _ in nil }`, which `ScriptableProjectTab` reports as an empty string"
(`ComposableTabsWindowController.swift`) — matching
`BranchController`'s own policy that a detached HEAD is "an answer,"
documented in `adtoolkit://cookbook/workspace/projects/branch-controller`.
**Approved**: pending

**Decision**: `ScriptableProjectTab.uniqueID` is the tab *group's* id, not
any per-edge member row's id.
**Rationale**: The type's doc comment states a project-level tab is "drawn
once on every enabled edge under one shared title," so exposing a per-edge
id "would be seeing an implementation detail rather than what is on screen"
(`ScriptableProjectTab.swift`).
**Approved**: pending

**Decision**: `ScriptablePane.init(pane:in:)` requires its enumerating
window as a parameter rather than letting the pane discover its own window.
**Rationale**: The doc comment is explicit: a pane behind a background tab
"has never been in a window's view hierarchy," so a wrapper that asked
`view.window` "names no project and no tab — for most of the panes in a real
window," while enumeration "always knows which window it is walking"
(`ScriptablePane.swift`; corroborated by the sibling doc comment
on `scriptablePanes` itself, `ProjectWindowManager+Scripting.swift`).
**Approved**: pending

**Decision**: `ScriptablePane.isInWindow` re-asks its own tagged window's
current `allPanes()` rather than re-running
`ProjectWindowManager.shared.scriptablePane(uniqueID:)`.
**Rationale**: The doc comment reasons that "a pane cannot have moved to a
*different* window between the request and this question, so one window's
walk is a complete answer, where the manager's lookup would walk every open
project to reach the same one" (`ScriptablePane.swift`).
**Approved**: pending

