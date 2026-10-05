
- **arranges-row-layout**: Component MUST arrange the label and the button
  into a single horizontal row, and MUST pin that row to all four edges of
  the view with no additional constant.
- **initializes-label-from-view-model-title**: Component MUST, during
  initialization, build the label from the view model's title.
- **initializes-button-without-fixed-width**: Component MUST construct the
  button without an explicit fixed width, so no width constraint is added
  on the button's behalf.
- **tags-button-with-a-fixed-accessibility-identifier**: Component MUST set
  the button's accessibility identifier to the literal
  `"settings.font-picker.choose"` during initialization.
- **commits-picked-font-through-view-model**: WHEN the button's change
  callback fires with the font the user picked, the component MUST commit
  that font to the view model.
- **resyncs-synchronously-after-a-pick**: WHEN the button's change callback
  fires, the component MUST resynchronize its display synchronously,
  immediately after committing the picked font to the view model,
  regardless of whether that commit actually changed the view model's
  stored name or size.
- **observes-external-view-model-changes**: Component MUST register a
  handler with the view model's external-change notification that
  resynchronizes its display; that handler MUST discard the font value it
  receives and let resynchronization re-read state from the view model
  directly.
- **overwrites-existing-view-model-observer**: Component MUST register that
  handler unconditionally at construction, replacing whatever handler (if
  any) was already registered on that view model instance.
- **syncs-once-at-construction**: Component MUST resynchronize its display
  exactly once at the end of initialization, after the label, the button,
  the row, and both change-notification handlers are all wired up.
- **redraws-label-text-on-every-sync**: WHEN the component resynchronizes,
  it MUST set the label's displayed text to the view model's title,
  unconditionally, even though the view model's title cannot change after
  construction.
- **updates-button-sample-on-every-sync**: WHEN the component
  resynchronizes, it MUST give the button the view model's current font
  and a title built from the font's name and installed status.
- **describes-font-name-and-rounded-point-size**: WHEN the component
  resynchronizes, the button's title MUST read `"<name> — <size> pt"`,
  where `<name>` is the font's display name (falling back to its
  underlying font name) and `<size>` is the font's point size rounded to
  the nearest integer (see the source platform's note for the mechanism
  that computes this string).
- **flags-an-uninstalled-font-in-its-title**: WHEN the component
  resynchronizes and the view model reports the font as not installed, the
  button's title MUST end with the literal suffix `" (not installed)"`.
- **delegates-font-resolution-fallback**: Component MUST NOT perform its
  own validation, clamping, or fallback substitution on the view model's
  underlying stored font name or size before giving it to the button;
  resolving an uninstalled font name or an out-of-range stored size to a
  fallback font is the view model's responsibility, one layer below this
  component.
- **dims-and-disables-the-row**: WHEN the row is disabled, the component
  MUST disable the button and dim the label to 40% opacity. WHEN the row is
  enabled, the component MUST enable the button and restore the label to
  full opacity.
- **defaults-to-enabled**: Component MUST initialize itself enabled.
- **exposes-constituent-views**: Component MUST expose the label and the
  button as public, directly-accessible, read-only properties.
- **requires-view-model-at-construction**: Component MUST be constructible
  only with a view model supplied at construction time; construction paths
  that could produce an instance without one (e.g. a bare/default
  construction path or a serialization/decoding-based construction path)
  MUST be rejected (see Platform Notes for the mechanism the source uses).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

