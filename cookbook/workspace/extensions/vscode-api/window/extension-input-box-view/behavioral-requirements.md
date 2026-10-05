
- **optional-title-label**: Component MUST display a title, in the
  theme's `primaryText` role and `heading` text role, populated with
  `model.request.title`, when `model.request.title` is non-nil and
  non-empty. Component MUST NOT display a title otherwise.
- **optional-prompt-label**: Component MUST display a prompt, in the
  theme's `secondaryText` role and `caption` text role, populated with
  `model.request.prompt`, when `model.request.prompt` is non-nil and
  non-empty. Component MUST NOT display a prompt otherwise.
- **secure-field-selection**: Component MUST construct its field as a
  secure (masked) text field when `model.request.isPassword` is `true`,
  and as a plain text field otherwise, and MUST make that choice exactly
  once, during construction, never re-evaluating or rebuilding the field
  afterward.
- **field-placeholder-seed**: Component MUST set the field's placeholder
  text to `model.request.placeHolder`, or to an empty string when
  `model.request.placeHolder` is `nil`.
- **initial-field-value**: Component MUST seed the field's text with
  `model.value` when the view is first loaded.
- **prefill-validation-once**: Component MUST, only
  the first time the view appears for a given component instance, call
  `model.beginValidating()` followed by `onValueChanged(model.value)`.
  Component MUST NOT repeat that call on any subsequent appearance of the
  same component instance.
- **value-commit-and-revalidation**: Component MUST, on every
  change to the field's text, set `model.value` to the field's current
  text, call `model.beginValidating()`, and invoke `onValueChanged` with
  that same new value, as one round trip per edit.
- **pending-acceptance-reset**: Component MUST discard any Return held
  pending validation on every change to the field's text, before
  performing the commit-and-revalidate round trip.
- **model-gated-acceptance**: Component MUST invoke
  `onAccept(model.value)` when Return is pressed while `model.canAccept`
  is `true`. Component MUST NOT invoke `onAccept` when `model.canAccept`
  is `false`.
- **acceptance-deferral**: Component MUST, when Return is
  pressed while `model.isValidating` is `true`, record that Return as
  pending rather than accepting immediately or discarding the keystroke,
  and MUST replay it — invoking
  `onAccept(model.value)` — the next time `showValidation(_:)` runs and
  finds `model.canAccept` `true`.
- **return-drop-under-error**: Component MUST silently drop a
  Return pressed while `model.canAccept` is `false` and
  `model.isValidating` is also `false` (a standing `.error` validation),
  without recording it for later replay.
- **escape-cancellation**: Component MUST invoke `onCancel()` when Escape is
  pressed while this component's window is the active (focused) window,
  for as long as the component is on screen.
- **validation-message-shown**: Component MUST, when `showValidation(_:)`
  is called with a non-nil validation, show the validation message, set
  its text to `validation.message`, and set its color role to `danger`
  for `error` severity, `warning` for `warning` severity, or
  `secondaryText` for `information` severity.
- **validation-message-hidden**: Component MUST hide the validation
  message when `showValidation(_:)` is called with `nil`.
- **focus-then-initial-selection**: Component MUST, when
  `focusField()` is called, first give the field keyboard focus, and only
  then set the field's text selection to
  `model.initialSelectionUTF16Range()`.
- **panel-size-from-fitted-layout**: Component MUST set the panel's
  preferred size to a fixed width of 480pt and a height equal to the root
  view's fitted content height, floored at 72pt.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

