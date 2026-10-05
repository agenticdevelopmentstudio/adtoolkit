
- **adds-child-as-only-subview**: Component MUST add the child view as its
  only content during initialization.
- **fills-container-with-child**: Component MUST make the child view fill
  the container's bounds edge-to-edge, with no additional inset, for as
  long as the container exists.
- **evaluates-initial-visibility**: Component MUST evaluate the visibility
  predicate against the observed setting's current value at the end of
  initialization, before the view is ever displayed.
- **reevaluates-visibility-on-setting-change**: Component MUST re-evaluate
  the visibility predicate against the setting's new value whenever the
  observed setting reports a change.
- **hides-when-predicate-returns-false**: Component MUST hide itself when
  the visibility predicate returns `false` for the value being evaluated.
- **shows-when-predicate-returns-true**: Component MUST show itself when
  the visibility predicate returns `true` for the value being evaluated.
- **skips-redundant-visibility-writes**: Component MUST NOT change its
  shown/hidden state and MUST NOT invoke the visibility-change callback
  when the newly computed visibility equals the component's current
  visibility.
- **notifies-visibility-change-once**: Component MUST invoke the
  visibility-change callback exactly once, after its shown/hidden state
  has changed, each time the computed visibility differs from the
  previous visibility.
- **reflects-setting-change-asynchronously**: Component MUST NOT reflect a
  changed setting value in its shown/hidden state synchronously, within
  the same call frame that changed the setting: the change delivers
  asynchronously, on the main thread, so the visibility update lands on a
  following turn of the main run loop, not before.
- **exposes-child-property**: Component MUST expose the child view as a
  public, directly-accessible, read-only property.
- **exposes-visibility-change-callback**: Component MUST expose a
  visibility-change callback as a public, settable, optional property so a
  hosting container can be told when the component's own visibility
  changes.
- **requires-full-configuration-at-construction**: Component MUST NOT be
  constructible without a setting, a child view, and a visibility
  predicate; only full construction with all three together is supported.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

