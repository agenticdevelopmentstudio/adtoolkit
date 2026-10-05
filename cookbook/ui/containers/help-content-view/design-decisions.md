
- **Decision**: This component composes a Group View and an Explanation
  View — types that still live under the `ComposableSettings` namespace —
  for help content, not settings.
  **Rationale**: the source's own doc comment states this is "the same two
  views the settings panels are built from," so help reads in the same
  type and rhythm as the controls it describes, and states plainly that the
  `ComposableSettings` naming for these shared views "is a naming debt, not
  a layering one (it is all one framework), and paying it off is a larger
  change than this file should make." (Applies to the AppKit implementation.)
  **Approved**: pending**
- **Decision**: When the content-setting operation is given no content or
  an empty topics list, the view shows a fixed "No Help Yet" group instead
  of closing the drawer or leaving the scroll area blank.
  **Rationale**: the source's own doc comment on `emptyTitle`/`emptyBody`
  explains that the drawer previously closed itself in this case, which
  "made it slam shut on the way to a panel with nothing to say and slide
  open again on the way out, an animation nobody asked for that reads as
  the window flinching," and concludes "an honest sentence beats an empty
  pane that reads as a rendering failure." (Applies to the AppKit
  implementation.)
  **Approved**: pending**
- **Decision**: The view's background is painted with
  `palette.windowBackgroundColor` — the same color as the window and drawer
  around it — rather than a distinct background.
  **Rationale**: the source's inline comment states this is deliberate so
  that "the cards are what should stand out" and a heading-shaped band of a
  second near-identical grey above them "only reads as a misprint."
  (Applies to the AppKit implementation.)
  **Approved**: pending**
- **Decision**: The content-setting operation always tears down and
  rebuilds the entire panel from scratch, with no comparison against the
  previously stored content, even though the content type supports
  equality comparison.
  **Rationale**: not stated in source; inferred from the absence of any
  equality check or partial-update path. The content-setting operation is
  called only when the panel/topic selection changes — `SplitViewController.show(_:)` and
  `refreshHelp()`, in
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/SplitViewController/SplitViewController.swift`,
  are the only call sites (reached through `PanelHostView` and
  `HelpDrawerController.setHelp(_:)`), and both fire from the reader
  changing which panel or topic is selected — not on a hot or
  performance-sensitive path, so a full rebuild is the simplest correct
  behavior rather than a documented optimization trade-off. (Applies to the
  AppKit implementation.)
  **Approved**: pending**
- **Decision**: The heading is drawn in the theme's primary text color with no enforced minimum-contrast floor against the window background.
  **Rationale**: The palette resolves the primary text role as the theme's raw foreground color and this view adds no contrast logic, so each shipped theme's contrast for the heading is unverified. Closing the gap means auditing each shipped theme's resolved foreground and window-background colors, or adding a contrast floor to the palette's primary text resolution.
  **Approved**: pending

