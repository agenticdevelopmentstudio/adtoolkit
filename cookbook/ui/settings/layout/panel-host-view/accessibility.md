
- **Role/trait**: The component itself sets no accessibility role — it is
  a plain container view with default view semantics. The help button is
  a stock push button, exposed to assistive technology with the
  platform's default push-button role; the source does not override it.
- **Keyboard / assistive technology navigation**: Satisfied — see
  **help-button-keyboard-focusable**. The source neither removes the help
  button from the keyboard focus order nor overrides its default
  activation behavior, so Tab/Shift-Tab focus traversal and Space/Return
  activation remain exactly the platform's unmodified default behavior.
- **Label requirements**: Satisfied for the help button — its
  accessibility label is always the literal string "Help"
  (**help-button-accessibility-label-fixed**), and both icon variants
  carry the same accessible description. The component sets no label on
  the content container; whatever content is installed via the set-content
  operation is responsible for its own labeling.
- **Announce state changes (e.g., loading, disabled)**: Not satisfied.
  The button-refresh operation changes the button's icon, tint, and
  tooltip when help is disclosed or dismissed, but the accessibility label
  stays the fixed string "Help" for both states, and the source issues no
  explicit accessibility-change announcement of its own — a screen reader
  is told nothing beyond whatever the platform's default image-change
  handling surfaces on its own.
- **minimum-contrast-ratio**: The help button's tint MUST come from the
  theme's accent-color role while help is disclosed and the theme's
  secondary-text-color role otherwise, and the component MUST NOT compute
  or enforce any contrast between that tint and whatever the button is
  drawn over. Whether either color reaches WCAG AA's 3:1 non-text contrast
  minimum for a given theme depends on that theme's concrete color values,
  not on this component.
- **Minimum tap target**: Not applicable in a universal touch-target
  sense — this component targets a pointer-driven desktop environment,
  where a single fixed minimum hit-target size is not established the way
  it is for a touch interface (see Platform Notes for how this plays out
  on the source's platform). The help button's actual click area is not
  set explicitly in source; it takes its size from the platform's default
  sizing for a borderless, image-only, momentary-type button showing a
  15pt icon, which the source neither overrides nor measures.

