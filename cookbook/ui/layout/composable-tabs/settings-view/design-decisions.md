
- **Decision**: Apply every setting change immediately, with no commit or
  cancel action anywhere in the sheet.
  **Rationale**: Per the source's own comment, "the edges toggle live behind
  the sheet — so there is nothing to commit and nothing to cancel"; the
  Done button only dismisses the sheet, it does not persist anything that
  was not already persisted.
  **Approved**: pending
- **Decision**: Re-read each checkbox's displayed state from `isEdgeEnabled`
  immediately after calling `setEdgeEnabled`, rather than trusting the
  click that triggered the handler.
  **Rationale**: Per the source's own comment, "the window refuses to turn off
  its last tab bar, so the checkbox is re-read rather than left showing a
  state the window does not have" — this file has no rule of its own about
  a minimum number of enabled edges; it only ever reflects what the
  injected closure reports.
  **Approved**: pending
- **Decision**: Override `contentSizedSidebar` to `true` instead of the base
  class's draggable default. (AppKit/UIKit.)
  **Rationale**: Per the source's own comment, "a sheet has no remembered
  geometry to restore, and a divider the user drags in a transient dialog
  is a setting they never asked to keep."
  **Approved**: pending
- **Decision**: Present help through a `HelpPopoverController` instead of the
  base class's drawer-style presenter. (AppKit/UIKit.)
  **Rationale**: Per the source's own comment, "a sheet has no free edge for a
  drawer to slide out of, so this split presents its help in a popover off
  the help button instead."
  **Approved**: pending
- **Decision**: Fix `detailMinimumThickness` at 420pt. (AppKit/UIKit.)
  **Rationale**: Per the source's own comment, this is "wide enough for the
  Spacing panel's diagram, which is the widest thing either topic puts in
  the detail pane" — the value is driven by the Spacing panel's content,
  not the Tabs panel's.
  **Approved**: pending
- **Decision**: Close the Tab key-view loop between the frame-spacing and
  divider-spacing controls onto themselves, rather than letting it trail
  into the Done button or the sidebar.
  **Rationale**: Per the source's own comment, the controls are "placed by
  frame, so left to itself Tab out of the bottom number went somewhere
  that looked like nowhere," and "the sheet holds nothing else to type in,
  so the loop closes on itself rather than trailing off into the sheet's
  buttons." The comment also notes this mirrors the key-view loop of "the
  Projects settings panel," so the same pair of controls owes the user a
  consistent Tab order wherever it appears.
  **Approved**: pending
- **Decision**: Scope tab-bar edge enablement to the current project (via the
  injected closures) while scoping frame/divider spacing to every window
  in the app (via the app-wide spacing settings).
  **Rationale**: Both panels' own help text states this split explicitly — the
  Tabs panel's: "these edges belong to this project, not to the app...
  Spacing... is the opposite: it belongs to every window"; the Spacing
  panel's: "Spacing belongs to the app, not to this project — every
  project window is spaced the same way." The two panels deliberately use
  two different persistence scopes side by side in the same sheet.
  **Approved**: pending

