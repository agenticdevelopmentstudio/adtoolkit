
- **renders-diagram-for-style**: Component MUST render a `frame` diagram
  (one view inside its container, four edge insets) when constructed with
  the `frame` style, and a `paneDividers` diagram (four panes, two gutters)
  when constructed with the `paneDividers` style.
- **fires-onchange-only-on-user-edit**: Component MUST invoke `onChange` when,
  and only when, `value` changes as the result of a user-initiated edit — an
  arrow click, a stepper change, a committed text field, an arrow-key press
  on a focused field, a drag, or Reset. Component MUST NOT invoke `onChange`
  when `value` is assigned directly.
- **skips-redundant-onchange**: Component MUST NOT invoke `onChange`, and
  MUST NOT redraw or re-lay-out, when a user interaction computes a value
  equal to the value already held.
- **clamps-user-edits-to-range**: Every user-driven write — an arrow click,
  a stepper change, a committed or in-progress typed number, or a drag — MUST
  be clamped to the configured range (default `0` to `40`) before it is
  applied.
- **commits-field-on-editing-end**: Component MUST commit a text field's
  typed number to the corresponding edge or gutter only when editing ends
  (Return, Tab, or clicking away), and MUST NOT commit on every keystroke.
- **recovers-unparseable-field-text**: When a field's typed text fails to
  parse as a whole number, Component MUST replace the field's displayed text
  with a valid number — the clamped typed number if any number could be
  parsed from it, otherwise the number already held for that field — so
  editing can always end.
- **repeats-held-arrow**: An arrow button MUST adjust its value once
  immediately on press, then MUST repeat that one-point adjustment starting
  `0.45` seconds after the button is pressed and every `0.06` seconds while
  it continues to be held.
- **freezes-pressed-arrow-pair**: Component MUST NOT re-seat (move) an
  arrow pair while one of its own arrows is pressed, even when a layout pass
  is triggered by some other number changing.
- **drags-edge-one-to-one**: Dragging an edge's handle MUST change that
  edge's value by one point per point the pointer has travelled along the
  edge's drag axis since the drag began, signed per that edge's gain (see
  table below), measured from the value at drag start, not accumulated step
  by step.
- **drags-gutter-two-to-one-outward**: Dragging a gutter's handle MUST
  change that gutter's value by two points per point the pointer has
  travelled along the divider's drag axis since the drag began, measured
  from the value and pointer position at drag start. The sign is fixed once,
  by which side of the divider's centre the pointer's initial grab point
  fell on: if the drag began on the negative side of centre, travel further
  in the negative direction increases the value; if it began on the
  positive side, travel further in the positive direction increases the
  value. That sign does not flip if the pointer later crosses the centre —
  travel back past centre continues to decrease the value using the same
  fixed sign.
- **arrow-points-in-line-travel-direction**: Each arrow MUST point in the
  direction the line it controls travels when pressed — the edge/pane-edge's
  growing direction for the arrow that adds room, and the opposite direction
  for the arrow that removes it.
- **resets-only-visible-numbers**: The Reset control MUST, in a single value
  update, set to zero exactly the numbers the current `style` shows — the
  four edges for `frame`, the two gutters for `paneDividers` — and MUST NOT
  change any number the current style does not show.
- **tab-order-is-picture-order**: Tab and Shift-Tab MUST move focus only
  among the control's number fields, in the order top, leading, trailing,
  bottom for `frame` or the gutter enumeration order for `paneDividers`,
  and MUST NOT include a stepper or an arrow button in that order.
- **arrow-keys-adjust-focused-field**: With a number field focused, the Up
  arrow key MUST increase and the Down arrow key MUST decrease that field's
  value by one point (clamped to the range); the Left and Right arrow keys
  MUST be left for caret movement within the field's text.
- **preserves-other-fields-mid-edit**: Component MUST NOT overwrite the
  on-screen text of a field that is currently being edited when any other
  field's number changes while this field is being edited.
- **reflects-forced-field-after-commit**: After a field's typed value is
  committed, Component MUST re-display that field's number even when the
  clamped result equals the number already held, so a typed out-of-range
  number is visibly shown snapping back.
- **group-accessibility-container**: Component MUST expose itself to
  accessibility as a single group element rather than exposing its child
  elements directly to whatever container it is placed in.
- **reports-fixed-intrinsic-size**: Component MUST report a fixed `420×250`
  point size as its natural size regardless of `style` or the current value.
- **clips-below-minimum-size**: When given less room than its minimum size
  (derived from the chrome metrics and either three field groups across or
  the diagram's own floor, whichever is larger), Component MUST stop
  shrinking its diagram and child elements at that floor rather than
  continuing to compress them, even if that places some child elements
  outside its own drawing area.
- **repaints-on-theme-change**: Component MUST re-fetch its drawn colors
  (frame fill, pane fill, borders) and its field/reset fonts from the active
  theme's palette, and redraw, whenever the active theme's palette changes —
  without being reconstructed.
- **caps-displayed-inset-at-maximum**: The diagram MUST draw any single
  edge's or gutter's extent no larger than the maximum displayed inset (`40`
  points), even when `value` holds a larger number for it.

Per-edge drag axis, gain sign, and growing direction, so a port can
implement `drags-edge-one-to-one` and `arrow-points-in-line-travel-direction`
without reading the underlying value type's source:

| Edge | Drag axis | Gain sign | Growing direction |
|------|-----------|-----------|----------------------|
| `top` | vertical | `-1` (dragging down grows the inset) | down |
| `bottom` | vertical | `+1` (dragging up grows the inset) | up |
| `leading` | horizontal | `+1` (dragging right grows the inset) | right |
| `trailing` | horizontal | `-1` (dragging left grows the inset) | left |

Both gutters use a fixed gain of `2` (not signed per gutter — the sign for a
gutter drag instead comes from which side of the divider's centre the drag
began, per `drags-gutter-two-to-one-outward`).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

