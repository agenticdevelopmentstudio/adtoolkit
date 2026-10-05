
- **fixed-glyph-size**: The component MUST constrain both its width and
  height to a fixed 13pt, regardless of `activity` or `isSummarizing`.
- **horizontal-compression-resistance**: The component MUST resist being
  compressed narrower than its fixed width when placed in a horizontally
  constrained layout.
- **state-based-symbol-selection**: The component MUST show a sparkle glyph
  whenever `isSummarizing` is `true`, regardless of `activity`; and otherwise
  MUST show a circular double-arrow glyph for `activity == .working`, a
  filled-dot glyph for `activity == .idle`, and a circled-exclamation-mark
  glyph for `activity == .waiting`.
- **idle-visibility-suppression**: The component MUST be hidden only when
  `activity == .idle` and `isSummarizing == false`, and MUST be visible for
  every other combination of `activity` and `isSummarizing`. This is the same
  condition under which **state-based-symbol-selection** selects the
  filled-dot glyph, **state-based-tint** selects the tertiary text color
  role, and **state-based-label-and-tooltip** selects `"Idle"`; because the
  component is hidden whenever that combination holds, none of those three
  idle values is ever seen or announced by a user — they exist only so the
  glyph and accessibility state are well-defined (and inspectable in tests)
  while hidden, not because anyone perceives them.
- **state-based-tint**: The component MUST tint the glyph with the active
  theme's accent color role when `isSummarizing` is `true` or `activity ==
  .working`, with the theme's tertiary text color role when `activity ==
  .idle` and `isSummarizing` is `false`, and with the theme's warning color
  role when `activity == .waiting` and `isSummarizing` is `false`.
- **pre-theme-tint-default**: The component MUST use a system-provided
  tertiary label color as the glyph's tint until a theme has been applied
  for the first time.
- **symbol-layer-distinction**: When recoloring a glyph made of more than
  one visual layer (for example the circled-exclamation-mark glyph), the
  component MUST keep the glyph's layers visually distinct from one another
  after tinting — the exclamation mark MUST stay visually distinct from its
  enclosing circle, rather than the tint collapsing every layer into a single
  flat-colored silhouette. See the Platform Notes entry for the implemented
  platform for the mechanism used to satisfy it.
- **unresolvable-symbol-fallback**: The component MUST clear the glyph's
  rendered content when the selected glyph's image cannot be resolved by the
  platform's icon lookup.
- **in-place-state-update**: The component MUST update an existing
  instance's displayed state through a state-update operation rather than
  requiring callers to construct a new instance for a state change.
- **redundant-update-guard**: The component MUST return from the
  state-update operation without redrawing, re-describing accessibility, or
  touching any animation when neither `activity` nor `isSummarizing` differs
  from the component's current values.
- **animation-restart-on-change**: The component MUST stop any running
  glyph animation and, only if it is currently visible on screen, start the
  animation appropriate to the new state, whenever the state-update operation
  is called with a value that actually changes `activity` or `isSummarizing`.
- **waiting-or-summarizing-pulse**: The component MUST animate the glyph's
  opacity from `1.0` to `0.25` and back (autoreversing) over 0.7 seconds,
  repeating indefinitely, whenever `isSummarizing` is `true` or `activity ==
  .waiting`.
- **working-state-spin**: The component MUST rotate the glyph one full turn
  clockwise over 1.1 seconds with a linear timing function, repeating
  indefinitely, when `activity == .working` and `isSummarizing == false`.
- **animation-install-idempotence**: The component MUST NOT add a new
  pulse or rotation animation for a state that already has an animation
  installed on the glyph.
- **off-window-animation-removal**: The component MUST remove both the
  rotation and the pulse animation from the glyph when the component leaves
  the screen (is removed from its display hierarchy).
- **window-attach-animation-reinstall**: The component MUST re-render the
  glyph and start its state-appropriate animation whenever the component is
  (re)inserted into the display hierarchy.
- **appearance-change-rerender**: The component MUST re-render the glyph
  whenever the surrounding appearance (e.g. light/dark) changes, so that a
  dynamic tint color resolves against the new appearance.
- **display-scale-rerender**: The component MUST keep the rasterized glyph
  matching the display's current pixel density, re-rendering whenever that
  density changes, defaulting to a 2x density when it cannot otherwise be
  determined. See the Platform Notes entry for the implemented platform for
  the API used to read and react to that density.
- **glyph-bounds-layout**: The component MUST keep the glyph's bounds equal
  to the component's own bounds and its position centered in the component
  on every layout pass, with no animated transition for that
  resize/reposition. See the Platform Notes entry for the implemented
  platform for the mechanism used to suppress that animation.
- **image-accessibility-role**: The component MUST expose itself to
  assistive technology as an accessibility element with an image role.
- **state-based-label-and-tooltip**: The component MUST set both its
  accessibility label and its tooltip to `"Working"`, `"Idle"`, `"Waiting
  for you"`, or `"Summarizing"`, selected by the exact same
  `isSummarizing`/`activity` logic as **state-based-symbol-selection**.
- **state-based-accessibility-identifier**: The component MUST set its
  accessibility identifier to `session-panel.activity.summarizing` when
  `isSummarizing` is `true`, or to `session-panel.activity.working` /
  `session-panel.activity.idle` / `session-panel.activity.waiting`
  otherwise, matching `activity`.
- **programmatic-construction-only**: The component MUST only be
  constructible programmatically; it MUST NOT support instantiation from a
  serialized archive (for example, a visual-editor-generated layout file).
  See the Platform Notes entry for the implemented platform for the
  mechanism used to enforce that.

