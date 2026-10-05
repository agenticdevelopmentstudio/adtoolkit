
- **Decision**: Choose the field's concrete class (`NSSecureTextField` vs.
  `NSTextField`) once, in `init(model:)`, from
  `model.request.isPassword`, rather than allowing it to change later.
  **Rationale**: Source's own comment: a field that changes class after
  gaining focus loses its caret and typed text, and `isPassword` cannot
  change during one `showInputBox` request, so there is exactly one
  moment this decision needs to be made.
  **Approved**: pending
- **Decision**: Hold a Return pressed while `model.isValidating` is `true`
  and replay it once validation lands, rather than accepting it
  immediately or dropping the keystroke.
  **Rationale**: Source's own comment on `choose()`: a Return pressed
  mid-validation is "not yet," not "no" — replaying it once the answer
  arrives lets a slow validator delay acceptance instead of silently
  swallowing the user's keystroke.
  **Approved**: pending
- **Decision**: Validate the pre-filled `model.value` once, on the first
  `viewDidAppear` after the controller instance is created, via the guard
  described in `prefill-validation-once`, rather than in `viewDidLoad`.
  **Rationale**: Source's own comment: `viewDidAppear` can run more than
  once for one panel, so the guard keeps a re-appearance from
  re-triggering a validation round trip for a value that never changed;
  `viewDidLoad` was rejected because the presenter assigns
  `onValueChanged` only after `viewDidLoad` can already have run, leaving
  nothing to call yet.
  **Approved**: pending
- **Decision**: Route the field's `doCommandBy:` selectors through the
  shared `PickerKeyboardController`, which also recognizes
  `moveUp`/`moveDown` (arrow keys), even though this controller never
  sets `onMoveSelection`.
  **Rationale**: `PickerKeyboardController` is shared byte-for-byte with
  the picker views that do use `onMoveSelection` to move a row selection;
  reusing it here consumes the up/down arrow key events (marked handled,
  so they do not propagate further) but produces no visible effect in
  this single-field panel, since `onMoveSelection` is left at its default
  no-op closure.
  **Approved**: pending

