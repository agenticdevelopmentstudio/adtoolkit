
- **Decision**: Pointer movement is gated behind `activePaneFollowsMouse`,
  which defaults to `false`.
  **Rationale**: Per the source's own comment, focus that moves without being
  asked to is a preference people hold strongly in both directions, and the
  surprising answer — the keys going somewhere the user did not put them —
  is judged the wrong default.
  **Approved**: pending
- **Decision**: A click activates the hit pane directly and never itself
  calls `takeFocus`; only a pointer move calls it.
  **Rationale**: (AppKit) A click already carries its own focus through
  AppKit's ordinary hit-test-to-first-responder path, so calling `takeFocus`
  for a click would be redundant. A move carries no such focus of its own, so
  without an explicit call the outline could move to a pane the keyboard
  never followed into.
  **Approved**: pending
- **Decision**: For a pointer move, focus is taken before the pane is
  activated, and a refusal from the outgoing responder blocks the activation
  entirely — nothing is left half-changed.
  **Rationale**: (AppKit) The source notes that a text field failing
  validation in `resignFirstResponder` is AppKit's ordinary way of saying
  "finish this first"; outlining the new pane anyway would point at a pane
  the keyboard is not actually in.
  **Approved**: pending
- **Decision**: A hidden pane (for example, a collapsed split) still counts
  as "live" and still holds the active id; only removal from the window ends
  its claim.
  **Rationale**: Per the source's own comment, a collapsed split is still the
  user's pane; only a pane out of the window entirely has stopped being
  somewhere the keys can go.
  **Approved**: pending
- **Decision**: `isInActivePane(_:)` is deliberately blind to whether the
  window is key.
  **Rationale**: (AppKit) The source states this is deliberate: which pane
  the user is working in does not change because a settings window came
  forward, and a pane that dimmed itself every time Settings opened would be
  reporting the wrong thing exactly when the user was looking at it.
  **Approved**: pending
- **Decision**: The `NSEvent` monitor is local to the app's own windows, not
  global.
  **Rationale**: (AppKit) This app only needs to know about the pointer
  inside its own windows, and a local monitor sees events before the
  responder chain does without requiring the accessibility permission a
  global monitor would need.
  **Approved**: pending
- **Decision**: `NSWindow.willCloseNotification` handling and the
  `highlightActivePane` settings-change handling are both explicitly
  dispatched onto `DispatchQueue.main`, not `RunLoop.main`.
  **Rationale**: (AppKit) `RunLoop.main` enqueues only in `.default` mode, so
  anything posted while AppKit tracks a mouse-down in `.eventTracking` mode
  (for example, a checkbox being clicked) would not run until the tracking
  loop ended. `DispatchQueue.main` is drained in every mode.
  **Approved**: pending
- **Decision**: Every pane's backdrop is always outlined at a constant 2pt
  width; only the border color distinguishes the active pane.
  **Rationale**: The source states that outlining only the active pane left
  every other pane reading as an unbounded field of the window-background
  role, so two panes side by side would look like one pane with a seam down
  it. A constant width means clicking between panes recolors a line instead
  of moving one.
  **Approved**: pending
- **Decision**: The workspace's own backdrop plane (not the pane's fill) is
  what the active-pane border is drawn against, with the pane's fill inset
  inside it.
  **Rationale**: The source states that painting the border and the pane's
  fill as one plane put a hairline of window background between a tab and
  the pane it belongs to, all the way around; the two-plane structure keeps
  the tab reading as part of the workspace instead of something stuck on top
  of it.
  **Approved**: pending
- **Decision**: `paneWindows` and `paneViews` are weak `NSHashTable`
  collections rather than strong references.
  **Rationale**: (AppKit) Per the source's own comments, both are
  convenience lists, never owners; a closed window or a pane that has left
  its window needs to be able to go away without this component being told
  twice.
  **Approved**: pending
- **Decision**: The active-pane border is drawn in the theme's outline color with no contrast check against the pane backdrop.
  **Rationale**: The color values are chosen per theme outside this component, so the pairing cannot be computed here; closing the gap means auditing each shipped theme's active-pane-outline and pane-backdrop tokens against a numeric threshold such as 3:1.
  **Approved**: pending

