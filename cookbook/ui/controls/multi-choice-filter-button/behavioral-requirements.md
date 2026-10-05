
- **builds-fixed-menu-structure**: Component MUST build one menu whose
  items are, in order: an item titled `label` with no action (item 0, the
  pull-down's own displayed-title slot, per platform convention never
  itself invoked), an "Any" item that clears the selection, a separator,
  then one item per entry in `choices`, each titled with that choice's
  `title`.
- **sets-choice-tooltip**: For each choice whose `detail` is non-empty, the
  corresponding menu item MUST have its tooltip set to that `detail`.
  Component MUST NOT set a tooltip on a choice item whose `detail` is
  empty.
- **clears-selection-on-any**: Selecting the "Any" item MUST set `selection`
  to the empty set.
- **toggles-choice-on-select**: Selecting a choice's menu item MUST add that
  choice's `id` to `selection` if it is absent, or remove it if it is
  present.
- **restricts-selection-to-known-ids**: The selection-setting operation
  MUST set `selection` to the intersection of the ids it is given with the
  ids of `choices`; any id not present in `choices` MUST be discarded
  silently.
- **reflects-checkmarks**: After every call to the choice toggle action, the
  "Any" action, or the selection-setting operation, each choice's menu item
  MUST be resynchronized to checked when that item's id is a member of the
  current `selection` and unchecked otherwise — this resync MUST happen
  even when the call left `selection` unchanged in value (see
  **fires-on-change-on-actual-change** and Edge Cases).
- **label-and-any-never-checked**: Item 0 (the label item) and the "Any"
  item MUST NOT ever show a checkmark; only a per-choice item's checked
  state reflects `selection` membership. Neither item carries an id of its
  own, so the checkmark-resync operation's membership test skips both of
  them on every resync.
- **fires-on-change-on-actual-change**: `onChange` MUST be invoked with the
  new `selection` whenever `selection`'s value changes as a result of the
  choice toggle action, the "Any" action, or the selection-setting
  operation. `onChange` MUST NOT be invoked when one of those operations
  leaves `selection` equal in value to what it was before the call.
- **initializes-selection-empty**: At construction, `selection` MUST be the
  empty set, and `onChange` MUST NOT be invoked as a result of that initial
  value being set — `onChange` is nil until the caller assigns it after
  construction returns anyway. See Platform Notes
  for why the initial assignment itself triggers no side effect.
- **formats-title-none-selected**: When `selection` is empty, the button's
  displayed title MUST be `"<label>: Any"`.
- **formats-title-few-selected**: When `selection` contains exactly one or
  exactly two ids, the button's displayed title MUST be
  `"<label>: <titles>"`, where `<titles>` is the `title` of each selected
  choice, in the order those choices appear in `choices`, joined with
  `", "`.
- **formats-title-many-selected**: When `selection` contains three or more
  ids, the button's displayed title MUST be `"<label>: <n> selected"`, where
  `<n>` is `selection.count`.
- **refreshes-title-synchronously**: On every `selection` change, the
  button's on-screen displayed title MUST match the newly computed summary
  before the triggering call (the choice toggle action, the "Any" action,
  or the selection-setting operation) returns — never a stale title left
  over until some later, unrelated redraw. See Platform Notes for the specific API call this requires.
- **resizes-for-longer-titles**: After every title change, the button's
  measured natural size MUST already reflect the new title's length, so a
  longer summary is never laid out — and truncated — inside a width
  computed for the previous, shorter title. See Platform Notes for the specific API call this requires.
- **exposes-readonly-selection**: `selection` MUST be readable from outside
  the type and MUST NOT be settable from outside the type except through
  the selection-setting operation.
- **themes-text-appearance**: The component MUST set its foreground tint
  color to the active theme's `SemanticPalette.primaryTextColor` and its
  font to the active theme's `SemanticPalette.font(.body)`, applying both
  immediately at initialization and reapplying both every time the active
  theme changes.
- **rejects-coder-initialization**: The control MUST be constructible only in code. Constructing it from a serialized or archived representation (such as a nib or storyboard) MUST be refused as a programmer error that terminates, producing no instance.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **disables-autoresizing-mask-translation**: The control MUST be positioned only by explicit layout constraints supplied by its container; it MUST NOT have constraints generated implicitly from its frame.

