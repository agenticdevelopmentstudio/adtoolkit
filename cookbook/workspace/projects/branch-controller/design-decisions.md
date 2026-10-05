
**Decision**: `displayName` reads from `currentBranch`, which is re-read on
every `refresh()`, rather than from the `checkout` snapshot the controller
was constructed with.
**Rationale**: Per the doc comment, `checkout` is a `let` that "never
moves" — `identifier` depends on that being true, so a checkout keeps its
identity across branch switches — but a label read off that frozen snapshot
would go on naming whichever branch was checked out when the window opened.
Everything the user reads (the command palette's category, a pane's session
name) needs the live value instead (`BranchController.swift`).
**Approved**: pending

**Decision**: `refresh()` treats a successful call that resolves to `nil`
(detached HEAD) as replacing `currentBranch`, but treats a thrown error as
leaving `currentBranch` untouched — the two are not folded into one `try?`.
**Rationale**: The doc comment states this directly: "a detached HEAD is an
*answer*... a thrown error is not an answer — git could not be asked, so the
last known branch stays put," matching the policy `GitStatusProvider` applies
to a failed status; folding both into `try?` "kept a stale branch name on
screen forever, because the two cases are indistinguishable once the error
is discarded" (`BranchController.swift`).
**Approved**: pending

**Decision**: `makeTabPane(edge:tabID:)` returns the existing pane for a
given `(edge, tabID)` rather than minting a new `TabPaneViewController` on
every call.
**Rationale**: The doc comment explains the cost this avoids: "asking twice
for the same tab's item is asking the same question," and
`refreshTabItems()` asks for every tab on every checkout scan and every
branch refresh — a fresh controller per ask "built and threw away a view
controller per tab per edge per scan," leaving discards in `panes` until
AppKit released them (`BranchController.swift`).
**Approved**: pending

**Decision**: A checkout's live `displayName` is placed in each command's
`category`, never in its `title`.
**Rationale**: The doc comment gives the concrete failure this avoids: with
a bare `"Branch"` category, a two-worktree project offered six palette rows
all reading `"Refresh Status — Branch"`, and picking one was "a coin flip
over which directory it acted on." The title is what the per-pane context
menu renders alone, inside a pane that already identifies its checkout, so
repeating the name there would be redundant (`BranchController.swift`).
**Approved**: pending

**Decision**: `revealInFinder` and `copyPath` capture `directory` by value
in a local `let` rather than reaching through `self.checkout.directory` at
invocation time.
**Rationale**: The doc comment states the reason plainly: "so an unregister
that races a menu already on screen still does the right thing rather than
silently nothing" — a menu already built and shown holds closures that keep
working correctly even if the controller that built them has since been torn
down (`BranchController.swift`).
**Approved**: pending

**Decision**: The context menu's `ClosureMenuItemTarget` is assigned to both
`item.target` and `item.representedObject`.
**Rationale**: `NSMenuItem.target` is a weak reference; without a second,
strong retention the target would be deallocated before the menu is ever
shown, and "every item silently inert once its target is deallocated" —
`representedObject` is the retention point chosen to prevent that
(`BranchController.swift`).
**Approved**: pending

**Decision**: Overlapping `refresh()` calls on one controller are neither ordered nor coalesced: there is no generation counter or in-flight guard, so the call whose branch read returns last wins, even if it started first.
**Rationale**: The source's `refresh()` simply awaits the git client's current-branch read and assigns the result, then reloads panes; tests exercise only a single call. Closing it would mean a generation check or coalescing like the sibling git status provider's, once overlapping calls are shown reachable from the worktree-scan and command-dispatch call sites.
**Approved**: pending

