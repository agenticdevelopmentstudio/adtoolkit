
- **Decision**: (AppKit) Draw the row's control as an `NSSwitch`, not a
  checkbox button, despite the type being named `CheckboxView`.
  **Rationale**: Per the source's own doc comment, the switch replaced a
  checkbox-with-title button because a checkbox puts its control on the
  left, "the one row shape that cannot line up with the popups, steppers
  and sliders beside it in the same card — and left every group looking
  like two different lists interleaved."
  **Approved**: pending
- **Decision**: (AppKit) Name the public property `toggle`, not
  `checkbox`.
  **Rationale**: Per the source's own doc comment, the control "has not
  been a checkbox since the row was restyled, and a name that lies about a
  control's class is the kind that gets `state = .on` written against the
  wrong API."
  **Approved**: pending
- **Decision**: Link the toggle's accessible name to the label rather than
  setting a separate accessibility-label string.
  **Rationale**: Per the source's own comment, a bare switch has no name
  of its own, so an assistive technology would announce it as an
  unlabelled control; the visible label is its title element.
  **Approved**: pending
- **Decision**: (AppKit) Force a fatal error from both `init(coder:)` and
  the frame-only `init(frame:)`, leaving `init(with:)` as the only usable
  initializer.
  **Rationale**: The view has no meaningful default state — it cannot
  render a title or value without a view model — so both inherited
  `NSView` initializers that could construct it without one are
  intentionally disabled rather than left to produce a half-configured
  row.
  **Approved**: pending
- **Decision**: (AppKit) Keep the public type name `CheckboxView` even
  though it draws a switch, not a checkbox.
  **Rationale**: The type is `SettingsViewProtocol`-conforming API surface
  read by callers across `ComposableSettingsWindow`; renaming it (e.g. to
  `SwitchRowView`) is a breaking rename with no behavioral upside, while the
  file's own doc comments already correct the mismatch at the
  `toggle`-vs-`checkbox` property level (see the `toggle` naming decision
  above) — callers and tests all read `toggle`, not the type name, so the
  outer name causes no runtime confusion today.
  **Approved**: pending
- **Decision**: Unconditionally overwrite the view model's external-change
  handler with the component's own handler during initialization, rather
  than chaining it after any previously registered handler.
  **Rationale**: The source's external-change property is a single
  closure/callback slot with no built-in multicast support; chaining would
  require a broader change to the shared view-model type, which is out of
  scope for this row view. The source accepts the tradeoff that one
  instance of this component (or other observer) per view model instance
  is the supported usage (see **claims-sole-onchange-observer**).
  **Approved**: pending

