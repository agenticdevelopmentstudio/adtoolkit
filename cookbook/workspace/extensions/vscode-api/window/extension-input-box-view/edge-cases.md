
- Null/empty input — title/prompt: `model.request.title`/`prompt` being
  `nil` or `""` suppresses that label entirely (see
  `optional-title-label`/`optional-prompt-label`). MUST.
- Null/empty input — value: `model.value` may be `""` (an empty pre-filled
  or typed value). Per `ExtensionInputBoxModel.onAccept`'s own contract,
  "an empty string is a value, and Return accepts it" — Return with an
  empty field and `model.canAccept == true` MUST invoke `onAccept("")`,
  not be treated as "nothing entered." MUST.
- Boundary values — initial selection: `model.initialSelectionUTF16Range()`
  (called directly by `focusField()`) clamps an out-of-bounds
  `valueSelection` to the value's length, and falls back to a zero-length
  range at the very end of the value when it cannot resolve a requested
  offset within the value. `focusField()` MUST apply whatever range this
  returns without additional validation of its own. MUST.
- Concurrent access: Not applicable — access to the component's state is
  serialized onto a single, consistent execution context, so all field
  change notifications, keyboard dispatch, and validation replies happen
  one at a time; there is no code path by which two threads mutate the
  component's state simultaneously.
- Error states: The only failure mode that reaches this component is an
  error-severity validation, which it MUST always render via
  `validation-message-shown` and MUST always block acceptance for via
  `model-gated-acceptance`/`return-drop-under-error`. This component
  performs no throwing or networked call itself; the extension's
  `validateInput` call and any failure within it are owned by the
  presenter above this component, not by the component itself. MUST.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; validation answers arrive as already-resolved
  values passed into `showValidation(_:)`.
- Return held, then superseded by a further edit: a Return pressed while
  `model.isValidating` is `true` is held pending validation (see
  `acceptance-deferral`); if the user types again before the answer
  lands, `pending-acceptance-reset` discards that held Return, so it is
  never replayed against a value the field no longer holds. MUST.
- Repeated appearance for one component instance: the pre-filled value is
  validated once per component instance, not once per appearance of the
  view (see `prefill-validation-once`). MUST.
- `isPassword` cannot change mid-presentation: the field's kind is fixed
  at construction from `model.request.isPassword`; nothing rebuilds or
  reclasses the field afterward, so a hypothetical later change to that
  flag on the same model has no effect. MUST NOT re-evaluate.
- Arrow keys (up/down) inside the field are consumed with no visible
  effect: every keyboard command is routed through a shared
  keyboard-dispatch helper, which also recognizes move-up/move-down and
  reports them handled (a move-selection handler is invoked and the key
  is treated as consumed). This component never assigns that
  move-selection handler, so pressing the up or down arrow while the
  field has focus is swallowed (marked handled, so it does not fall
  through to the field's default behavior) but produces no observable
  change. MAY — this is a documented known quirk of reusing the shared
  helper, not a contract this component defines; whether it is wanted is
  the open question in Design Decisions, not a requirement every port
  must reproduce.

