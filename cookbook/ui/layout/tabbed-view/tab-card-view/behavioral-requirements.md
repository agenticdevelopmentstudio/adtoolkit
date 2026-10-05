
- **accessibility-ids-assigned-per-instance**: On construction, the component
  MUST assign a distinct accessibility identifier to itself (`tab-pane.<uuid>`)
  and to the agent label, session label, directory label, branch label,
  summary label, and close control (each `tab-pane.<field>.<uuid>`), using
  the tab ID passed to it, so two tabs never share an identifier.
- **labels-truncate-by-middle-default**: The agent label, session label, and
  branch label MUST truncate overflowing text in their middle (the other two
  text labels start there too, before **directory-label-truncates-head** and
  **summary-label-truncates-tail** override them).
- **labels-resist-compression-at-low-priority**: The agent, session,
  directory, branch, and summary labels MUST each be given the lowest
  priority for resisting horizontal compression, so they are the first
  elements to shrink when space is limited.
- **directory-label-truncates-head**: The directory label MUST override its
  truncation to occur at the head (start) of the text.
- **summary-label-truncates-tail**: The summary label MUST override its
  truncation to occur at the tail (end) of the text.
- **labels-not-selectable**: All five text labels MUST NOT be selectable, so
  a pointer-down on a label's own area is not consumed by beginning a text
  selection and instead reaches whatever hosts this card's tab-selection
  handling.
- **summary-label-hidden-by-default**: The summary label MUST start hidden
  when the view is set up.
- **close-button-configuration**: The close control MUST display a close
  ("x" in a circle) icon only, with no border or bezel, in a fixed `14×14pt`
  frame.
- **close-action-forwards-to-onclose**: Component MUST invoke the close
  callback, and nothing else, when the close control's action fires.
- **header-close-button-placement**: The header MUST place the close control
  at its leading end when the card is on the left edge and at its trailing
  end for every other edge.
- **header-gap-absorbs-extra-width**: The invisible spacer between the
  agent/status group and the close control MUST be the element that absorbs
  any extra width in the header, rather than the agent label or the status
  row stretching.
- **content-padding**: The content column's edge insets MUST equal `top: 12,
  left: 14, bottom: 12, right: 14`.
- **content-stack-order**: The content column's arranged elements MUST be, in
  order: the header, the session label, the directory label, the branch
  label, the summary label, and a trailing spacer.
- **header-width-matches-content**: Component MUST constrain the header's
  width equal to the content column's width minus `26pt` (the sum of the
  content column's own left and right edge insets).
- **spacer-absorbs-extra-height**: The trailing spacer in the content column
  MUST be the element that absorbs any extra height the card has beyond what
  its content needs, rather than the five text lines growing.
- **self-not-pinned-either-axis**: Component MUST NOT constrain its own width
  or height to a fixed or computed value; both axes are left to the hosting
  bar (cross axis) and to the host's own preferred-size mechanism (length
  axis).
- **content-size-floors**: The card's content size MUST be no narrower than
  `240pt` (a minimum width), no wider than `340pt` (a maximum width), and no
  shorter than `136pt` (a minimum height), regardless of the content's own
  measured size.
- **content-size-grows-with-recession-slack**: The card's content size MUST
  add `2 × deepestRecession` (twice the recession at the maximum stack depth)
  to the content's natural width and height before applying the floors
  above.
- **front-card-defined-by-zero-depth**: The card MUST be considered the front
  card if and only if its stack depth is `0`.
- **depth-change-applies-only-on-change**: Setting the stack depth to its
  current value MUST NOT re-run the depth-change logic; only an actual
  change of value MUST trigger it.
- **depth-recession-flat-on-horizontal-edge**: On a top or bottom edge, the
  recession at any depth greater than zero MUST be exactly `4pt`, however
  large that depth is.
- **depth-recession-accumulates-on-vertical-edge**: On a left or right edge,
  the recession MUST grow `4pt` per step of depth: `4pt` at depth `1`, `8pt`
  at depth `2`, `12pt` at depth `3`.
- **depth-recession-clamps-past-max-stack-depth**: On a left or right edge,
  the recession MUST be the same `12pt` for any depth of `3` or greater.
- **front-card-overhangs-workspace**: When the card is the front card, its
  painted background MUST extend `1pt` (the workspace overlap) past the
  card's own bounds on the side facing the workspace.
- **text-stays-inset-on-workspace-side**: The card's text column MUST remain
  inset by the recession on the workspace-facing side even while the card is
  the front card and its painted background overhangs that side.
- **front-card-palette**: When the card is the front card, its background
  fill MUST use the resolved theme's `projectPaneBackdrop` color and its
  border MUST use `projectPaneOutline`.
- **behind-card-palette**: When the card is not the front card, its
  background fill MUST use the `windowBackground` role and its border MUST
  use the `border` role.
- **front-card-agent-label-role**: The agent label's role MUST be `.accent`
  when the card is the front card and `.primaryText` when it is not.
- **front-card-session-label-role**: The session label's role MUST be
  `.primaryText` when the card is the front card and `.secondaryText` when
  it is not.
- **front-card-secondary-label-roles**: The directory, branch, and summary
  labels' roles MUST each be `.secondaryText` when the card is the front
  card and `.tertiaryText` when it is not.
- **close-button-tint-follows-depth**: The close control's tint MUST be the
  `.secondaryText` role color when the card is the front card and the
  `.tertiaryText` role color when it is not.
- **theme-change-repaints-card**: Component MUST recompute its appearance
  whenever the active theme changes, so the card's colors track the palette
  live.
- **animated-only-when-in-window**: Depth-change animation MUST be enabled
  only while the card is on screen (attached to a window).
- **depth-animation-duration-and-curve**: An animated depth change MUST run
  over `0.16s` using an ease-out timing curve.
- **depth-animation-settles-pending-layout-first**: Before starting an
  animated depth change, component MUST force any outstanding layout to
  complete before opening the animation, so the animation does not start
  from a stale, pre-layout frame.
- **context-menu-delegates-to-provider**: Requesting a context menu MUST
  return the context-menu provider's menu when a provider is set and returns
  non-nil, and MUST fall back to the platform's default context menu
  otherwise.
- **status-symbols-replace-existing**: Replacing the status symbols MUST
  remove every previously added status icon from the status row before
  adding the icons for the new symbol list.
- **status-symbol-view-configuration**: Each status symbol's icon MUST render
  at `11pt`, regular weight, in a fixed `14×14pt` frame, and MUST carry the
  symbol's accessibility label as its own accessibility label.
- **status-symbol-missing-image-fallback**: Replacing the status symbols MUST
  substitute an empty placeholder image when a symbol name fails to resolve
  to an icon, rather than crashing or leaving a nil image.
- **zero-size-card-draws-nothing**: The card's background painting MUST draw
  nothing when its stroke bounds have zero or negative width or height.
- **card-path-omits-workspace-side**: The card's painted fill and stroke MUST
  trace only the three sides other than the one facing the workspace; the
  workspace-facing side MUST remain visually open, with no stroke drawn along
  it.
- **stroke-inset-by-half-point**: The card's three stroked sides MUST be
  inset `0.5pt` from the view's bounds, so the `1pt` stroke lands fully
  inside the card.
- **reaches-over-workspace-restores-half-point**: When the card reaches over
  the workspace, the workspace-facing side of the stroke bounds MUST be
  extended back out by that same `0.5pt`, so the fill and the two side
  strokes run flush through the overhang with no seam against the
  workspace's own line.
- **card-fill-and-border-color-accessors**: The card's reported fill and
  border colors MUST always report exactly the colors currently painted on
  the card's background.
- **workspace-overhang-accessor**: The card's reported workspace overhang
  MUST report `0` before layout has run and MUST otherwise report the card's
  current overhang.
- **running-move-animations-accessor** (formerly `animation-keys-accessor`):
  The card's set of in-progress move animations MUST report the union of the
  move animations currently running on its background and its content
  column.
- **onclose-is-optional**: Component MAY be left with no close callback set;
  a press of the close control then has no observable effect beyond calling
  nothing.
- **context-menu-provider-is-optional**: Component MAY be left with no
  context-menu provider set, in which case requesting a context menu always
  falls back to the platform's default context menu.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

