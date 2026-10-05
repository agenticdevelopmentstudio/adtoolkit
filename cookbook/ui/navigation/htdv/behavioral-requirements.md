
### Data model and data source contract

- **item-shape**: An item MUST expose an immutable identity, a label, an
  optional sub-label, an optional icon, a flag for whether a divider
  follows it, a leads-to designation, and an optional badge, and MUST
  support equality comparison and safe use across concurrent contexts. It
  MUST be constructible only through its own initializer, whose divider
  flag defaults to `false`, whose leads-to designation defaults to "list,"
  and whose sub-label/icon/badge default to none.
- **level-shape**: A level MUST expose an immutable identity, a title, its
  items, an empty-state message, and an optional create action, and MUST
  be safe to use across concurrent contexts. Its empty-state message MUST
  default to the literal "Nothing here yet" and its create action MUST
  default to none.
- **detail-shape**: A detail destination MUST expose an immutable
  identity, a title, and a factory that produces the destination's own
  view controller, constructible only through its own initializer, and
  MUST be safe to use across concurrent contexts.
- **child-shape**: The child - what lies beneath a selected path - MUST be
  exactly one of three things: a level, a detail destination, or nothing,
  and MUST be safe to use across concurrent contexts.
- **leads-to-shape**: An item's leads-to designation MUST be exactly one
  of two values, "list" or "detail," naming what selecting the item
  reveals to its right, and MUST support equality comparison and safe use
  across concurrent contexts.
- **badge-shape**: A badge MUST be exactly one of two kinds - a colored
  dot or a numeric count - and MUST support equality comparison and safe
  use across concurrent contexts.
- **badge-color-theme-role**: A dot badge's color MUST map red to the
  danger role, green to the success role, blue to the accent role, gray to
  the secondary-text role, and both orange and yellow to the warning role
  - the two names collapsing onto one role because the shared theme
  palette has no separate orange.
- **create-action-shape**: A create action MUST expose an immutable title
  and a callback that receives the hosting view controller (so it can
  present its own UI) and runs to completion before returning, and MUST be
  safe to use across concurrent contexts.
- **data-source-contract**: A data source MUST be an object that can fetch
  the root level and can fetch the child beneath any given path of items,
  both asynchronously and both able to fail with an error; it MUST be safe
  to use across concurrent contexts. Implementations are typically
  wrappers around a client with their own internal concurrency handling.

### Row projection

- **cell-content-projection**: The row projection MUST copy an item's
  label, sub-label, icon, and badge unchanged, and MUST mark itself as
  disclosing if and only if the item's leads-to designation is "list."
- **cell-content-equality**: The row projection MUST support equality
  comparison, hashing, and safe use across concurrent contexts, so a rail
  can key its rows by it and share it between the loading logic and the
  view layer.

### Navigation, selection, and loading state machine

- **initial-state**: A newly constructed controller MUST have no levels,
  no selection, no detail, no loading level index, and no error.
- **is-loading-derivation**: Whether the controller is loading MUST be
  true if and only if a loading level index is set; this MUST be derived,
  not tracked as a separate stored flag.
- **load-resets-then-fetches**: Loading MUST clear the levels, selection,
  detail, error, and any recorded failed request before fetching, MUST ask
  the data source for the root level, and on success MUST set the levels
  to that single returned root level.
- **select-validates-membership**: Selecting an item MUST no-op (leaving
  the levels, selection, detail, and error unchanged) unless the given
  level index is valid and the given item id names an item present in that
  level's items.
- **select-truncates-then-fetches**: On a valid selection, the controller
  MUST first truncate the levels to the levels up to and including the
  selected one and truncate the selection to the levels above it plus the
  newly selected item, clear the detail and error, and only then ask the
  data source for the child beneath the newly selected path.
- **select-applies-whatever-child-returns**: On success, the controller
  MUST apply whatever child the data source returns - appending a level to
  the levels, replacing the detail with the returned one, or doing nothing
  when the answer is empty - regardless of whether the selected item's own
  leads-to designation was "list" or "detail"; the controller does not
  validate agreement between an item's leads-to designation and the child
  the data source actually returns for it.
- **reload-root-vs-nested**: Reloading a level MUST ask the data source
  for the root level when reloading the first level, and for any deeper
  level MUST ask for the child beneath the parent path and require the
  result to be a level; a level index out of bounds for the current levels
  MUST make reloading a no-op.
- **reload-preserves-or-drops-selection**: When reloading a deeper level
  succeeds with a fresh level, the controller MUST replace that level with
  the fresh one and MUST preserve the current selection at that level if
  the selected item still appears among the fresh level's items, and MUST
  otherwise truncate the levels, selection, and detail from that level
  onward.
- **reload-parent-became-non-level**: When reloading a deeper level's
  parent lookup returns a detail destination or nothing instead of the
  expected level, reloading MUST drop the levels and selection from that
  level onward, clear the detail, and apply whatever child was actually
  returned - a detail destination is shown; nothing shows nothing - rather
  than discarding it, since a detail destination is real content the
  caller was handed, and throwing it away would show the user nothing at
  all.
- **retry-reissues-exact-failed-operation**: Retrying MUST no-op unless an
  error is present and a failed request was recorded, and when both are
  present MUST re-invoke exactly the operation that failed - a fresh load
  for a failed root load, the same selection for a failed selection, or
  the same level reload for a failed reload.
- **stale-response-dropped**: Every fetch MUST capture a monotonically
  increasing request counter's value at the moment it begins -
  incrementing the counter first, so the loading state changes before the
  fetch itself starts - and on completion, whether success or failure, the
  controller MUST discard the result and make no state change whenever the
  captured value no longer matches the current counter, because a newer
  request (or a jump back up the levels, or clearing the detail) started
  in the interim.
- **error-shape**: On a thrown error, the controller MUST set the error to
  a value carrying the failing level index and a user-facing message
  derived from the error, MUST record the failed request so retrying can
  reissue it, and MUST clear the loading level index - unless the failure
  is itself stale (see stale-response-dropped), in which case this MUST NOT happen.
- **pop-to-level-contract**: Jumping back to a level MUST no-op when the
  target index is below `-1` or at/beyond the current deepest level;
  otherwise it MUST invalidate any in-flight deeper load, truncate the
  levels to that level (or to none when the target is `-1`), truncate the
  selection to match, clear the detail, clear the error and any recorded
  failed request, clear the loading level index, and fire the change
  callback exactly once.
- **clear-detail-contract**: Clearing the detail MUST no-op when there is
  no detail already; otherwise it MUST invalidate any in-flight detail
  load, clear the detail, error, failed request, and loading level index,
  leave the levels and selection untouched, and fire the change callback
  exactly once.
- **on-change-fires-after-every-transition**: The change callback MUST be
  invoked after every state transition made by loading, selecting,
  reloading, jumping back to a level, and clearing the detail - including
  the loading-started transition at the start of a fetch, fired before the
  fetch itself begins - and MUST default to doing nothing until a host
  assigns one.
- **single-observer-callback**: The change callback MUST be a single-slot
  property, not a multicast; assigning it a second time MUST silently
  replace the first observer with no diagnostic - each controller MUST be
  driven by exactly one host, and a second host that assigns its own
  callback silently displaces the first.
- **selected-path-and-item-queries**: Reading the selected path MUST
  return the item at each selected id in the selection, skipping any
  level/id pair that no longer resolves - for example after a level was
  replaced by a reload - and reading the selected item at a given level
  MUST return none when that level index is out of bounds for the
  selection or for the levels.

### Rails-vs-stack layout decision

- **compact-always-stacks**: Deciding the layout MUST choose the
  single-pane stack mode whenever the layout is compact, regardless of the
  available width, level count, or whether a detail is shown.
- **zero-levels-shape**: When there are no levels and the layout is not
  compact, deciding the layout MUST return the side-by-side rails mode
  with zero visible rails, showing the detail exactly when one is present.
- **rails-width-budget**: When there is at least one level and the layout
  is not compact, deciding the layout MUST subtract the reserved detail
  width from the available width only when a detail is present, before
  dividing by the (clamped) rail width to decide how many rails fit.
- **rail-width-divisor-clamp**: Deciding the layout MUST clamp the
  effective rail width used as its division's divisor to a minimum of `1`,
  so a caller who has set the rail width to `0` or a negative value MUST
  NOT cause a division-by-zero or an invalid numeric conversion.
- **at-least-one-rail-when-levels-exist**: When there is at least one
  level, deciding the layout MUST return a set of visible rails containing
  at least one rail - specifically the rails nearest the end of the
  sequence, not the beginning - even when the computed available width
  would otherwise fit zero.
- **fitting-count-is-floored-and-clamped**: Deciding the layout MUST
  compute the number of rails that fit by dividing the available rails
  width by the effective rail width and rounding down, clamped between
  zero and the level count before converting to a whole number, so that an
  unbounded or extremely large available width MUST produce visible rails
  capped at the level count rather than an invalid numeric conversion.
- **layout-is-pure**: Deciding the layout MUST hold no state of its own
  beyond the rail width and reserved detail width supplied at construction
  or mutated by the caller between calls, and MUST return a value computed
  solely from its inputs (available width, level count, whether a detail
  is shown, and whether the layout is compact) and those two settings.
- **rail-width-init-precondition**: Constructing the layout engine MUST
  require a positive rail width, failing immediately at construction time
  if a non-positive value is supplied - a guarantee `rail-width-divisor-
  clamp` exists specifically because this construction-time check does not
  protect a later mutation of the rail width setting.

### Declarative form shape

- **form-spec-shape**: A form specification MUST expose mutable sections
  and the form's actions (which default to none set), and MUST expose the
  flattened list of every section's fields in section-then-field display
  order; it MUST be safe to use across concurrent contexts.
- **field-kinds**: A field MUST be exactly one of ten kinds - text,
  multi-line text, toggle, select, number, date, string set, read-only,
  markdown, and JSON - each carrying at minimum a key and a label, and MUST
  be safe to use across concurrent contexts.
- **field-key-and-label-projection**: A field's key and label MUST forward
  to that specific kind's own key/label for every kind, with no
  kind-specific transformation.
- **field-default-values**: A field's default value MUST be an empty
  string for text, multi-line text, markdown, JSON, and read-only kinds;
  `false` for a toggle; an empty set for a string set; and no value for
  select, number, and date kinds.
- **field-editability**: A field's editability MUST be `false` for the
  read-only kind and `true` for every other kind.
- **action-shapes**: An action MUST carry an identity, a title, whether it
  is destructive (defaulting to `false`), and a callback that can fail
  and, when it is the save action, receives the current, already-validated
  values. The delete action MUST carry a title, an optional confirmation
  message, and a non-parameterized callback that can fail. The form's
  actions MUST group an optional save action, an optional delete action,
  and a list of extra actions, all defaulting to none/none/empty. Every one
  of these MUST be safe to use across concurrent contexts.

### Field value type

- **form-value-shape**: A field value MUST be exactly one of six kinds - a
  string, a boolean, a number, a date, a string set, or no value - one
  value type shared by every field kind, and MUST support equality
  comparison and safe use across concurrent contexts.
- **form-value-accessors**: Reading a field value as a string, boolean,
  number, date, or string set MUST each return the wrapped value when it
  is that kind and none for every other kind (including no value); whether
  it holds no value MUST be true if and only if it is the no-value kind.

### Mutable form model and save lifecycle

- **form-state-initial-values**: Constructing the form model MUST seed
  each field's initial value from the supplied values when present, and
  MUST otherwise use that field's default value; the seeded set of values
  MUST become both the current values and the dirty-tracking baseline.
- **duplicate-field-key-detection**: Detecting duplicate field keys MUST
  return every field key the form specification declares more than once,
  each key appearing exactly once in the result in first-seen order;
  construction MUST flag each such key in a development build (without
  stopping a released build) and MUST otherwise continue constructing the
  instance with last-write-wins semantics for that key, so a shipped build
  keeps today's last-write-wins render rather than crashing on a form it
  could still mostly show.
- **is-dirty-derivation**: Whether the form is dirty MUST be true if and
  only if the current values differ from the baseline; this MUST be
  derived, not tracked as a separate stored flag.
- **can-save-derivation**: Whether the form can be saved MUST be true if
  and only if a save action is set, there is no blocked reason, a save is
  not already in progress, and either changes are not required or the
  form is dirty.
- **set-validates-the-changed-field-only**: Setting a field's value MUST
  no-op for a key not present in the form's fields; for a known key it
  MUST store the value, MUST re-run validation for that single field and
  update that field's error with the result (or clear it when valid), MUST
  clear the save error, and MUST fire the change callback.
- **validate-all-replaces-error-set**: Validating every field MUST
  re-validate every field in the form, MUST replace the error set wholesale
  with exactly the fields that failed (dropping stale errors for fields
  that now pass), MUST fire the change callback, and MUST return `true` if
  and only if no field failed.
- **save-lifecycle**: Saving MUST return `false` without side effects when
  no save action is set, a blocked reason is present, or a save is already
  in progress; otherwise it MUST validate every field and return `false`
  without invoking the save action when validation fails; on a validated
  save it MUST mark a save as in progress, fire the change callback,
  invoke the save action with a snapshot of the current values, and on
  success MUST adopt that snapshot as the new baseline, clear the
  in-progress flag, fire the change callback, and return `true`.
- **save-failure-preserves-dirty-state**: When the save action fails,
  saving MUST set the save error to a user-facing message derived from the
  failure, MUST clear the in-progress flag, MUST fire the change callback,
  MUST return `false`, and MUST NOT update the baseline - so the form
  remains dirty and the caller's edits are not lost.
- **revert-restores-baseline**: Reverting MUST reset the current values to
  the baseline, clear all errors and the save error, and fire the change
  callback.
- **mark-saved-rebaselines-without-performing**: Marking the form as saved
  MUST adopt the current values as the new baseline and fire the change
  callback, without invoking the save action or any other action.
- **blocked-reason-disables-saving**: Setting a blocked reason MUST make
  the form unsavable regardless of dirtiness, and MUST fire the change
  callback on every assignment, including reassigning the same value.
- **requires-changes-toggle**: Whether changes are required MUST default
  to `true` (an edit form disables saving until something changes);
  setting it to `false` (a create dialog with nothing to change against)
  MUST make whether the form can be saved depend only on there being no
  blocked reason and no save already in progress, relying on validating
  every field during save to reject an empty or invalid form instead.
- **concurrent-edit-during-save-stays-dirty**: Setting a field's value
  while a save is in flight MUST mutate the current values immediately
  (visible via the change callback) without affecting the in-flight
  save's already-captured snapshot; when that save later succeeds, the
  baseline MUST be set to the pre-edit snapshot it captured, not to the
  newer values, so the form MUST remain dirty after the save completes.
- **delete-and-extra-actions-are-outside-the-save-lifecycle**: The form
  model exposes no method that invokes the delete action or any extra
  action, and tracks no in-progress/error state for them; it models the
  save lifecycle specifically, and invoking delete/extra actions and
  displaying the delete action's confirmation message (or its documented
  "This cannot be undone." fallback) is the presentation layer's
  responsibility.

### Field validation rules

- **validator-is-pure**: The validator MUST be a stateless namespace whose
  sole operation is a pure function from a field and its value to an
  optional user-facing message string, with no message meaning the value
  is acceptable; the locale used for formatting MUST default to the
  current locale.
- **text-required-and-trims**: For text, multi-line text, and markdown
  fields, validation MUST trim leading/trailing whitespace and newlines
  before checking emptiness, and MUST return "<label> is required" if and
  only if the trimmed value is empty and the field is required; an
  optional field with an empty or whitespace-only value MUST validate with
  no error.
- **text-pattern-is-whole-value-anchored**: When a text field declares a
  pattern and the untrimmed value is non-empty, validation MUST match the
  pattern against the whole value by anchoring it as `^(?:<pattern>)$`
  before evaluating it as a regular expression - so a pattern that itself
  matches only a substring of the value MUST be rejected - and MUST return
  the field's custom pattern message when set, or "<label> has an invalid
  format" otherwise, when the anchored match fails.
- **json-field-validates-text-then-parse**: For a JSON field, validation
  MUST first apply the same required/trim check as a text field with no
  pattern; if that passes and the trimmed value is non-empty, it MUST then
  attempt to parse the value as JSON (including a bare literal, not only
  an object or array), and MUST return "<label> must be valid JSON" when
  parsing fails.
- **select-required-and-membership**: For a select field, validation MUST
  return "<label> is required" when the value is empty/none and the field
  is required, and otherwise, for a non-empty value, MUST return "<label>
  must be one of the listed options" unless the value equals some option's
  value.
- **number-required-bounds-and-integer**: For a number field, validation
  MUST return "<label> is required" when the value is not a number and
  the field is required; for a present number, MUST return "<label> must
  be a whole number" when the field requires an integer and the value is
  not equal to its own rounding; and MUST return a formatted "at least"/
  "at most" message when the value falls outside a declared minimum/
  maximum (inclusive bounds - a value exactly equal to the minimum or
  maximum MUST pass).
- **date-and-toggle-and-readonly**: Toggle and read-only fields MUST always
  validate with no error; a date field MUST return "<label> is required"
  when the field is required and the value holds no date, and MUST
  otherwise validate with no error.
- **string-set-required**: For a string-set field, validation MUST return
  "<label> is required" when the field is required and the value's set (or
  an empty set when absent) is empty; validation performs no per-item
  check on the set's contents.
- **bound-message-uses-locale-aware-formatting**: The numeric bound quoted
  in a number field's "at least"/"at most" message MUST be formatted as a
  plain decimal number in the supplied locale, with no grouping separator
  and up to 15 fraction digits - so a whole-number bound prints without a
  decimal point and a fractional bound renders using the locale's own
  decimal separator - falling back to a plain numeric rendering only if
  locale-aware formatting itself is unavailable.
- **bound-formatting-does-not-trap-on-extreme-values**: Formatting a bound
  MUST use a decimal-safe numeric formatter rather than converting through
  a fixed-width integer type, so a maximum or minimum far outside a normal
  whole-number range (e.g. `1e19`) MUST NOT crash while the message that
  reports the violation is being built.

### Markdown editor/viewer factory contract

- **markdown-editing-contract**: The markdown editing contract MUST
  declare two factory operations, both confined to the UI thread: one that
  produces an editor view controller for given initial text, whose change
  callback MUST be invoked with the current text on every edit, and one
  that produces a read-only viewer view controller for fixed text. It MUST
  be safe to use across concurrent contexts.
- **markdown-text-replacing-contract**: The live-text-replacement
  capability MUST declare a single operation that replaces the editor's
  displayed text, confined to the UI thread and adopted by an editor
  produced by the editing contract's editor factory, so a caller -
  documented as the revert use case - can push a restored value back into
  the live editor without knowing its concrete type.
- **plain-text-default-implementation**: The markdown editing contract's
  default implementation MUST produce monospaced, unstyled plain-text
  editing and viewing, with no markdown rendering; it is intended as an
  adequate placeholder until a richer implementation is available, and a
  host MAY inject a richer implementation of the contract instead.
- **plain-text-editor-replace-also-notifies**: On the default
  implementation, replacing the editor's text MUST set the displayed text
  to the new value AND invoke the change callback with that same value, so
  a programmatic replacement (used by revert) is observationally identical
  to the user typing it.
- **plain-text-editor-forwards-live-edits**: On the default
  implementation, every live edit in the editor MUST invoke the change
  callback with the text area's current text, falling back to an empty
  string if the platform's text-change notification reports none.
- **plain-text-editor-disables-smart-substitution**: The default
  implementation MUST disable automatic quote/dash substitution and
  autocorrection/autocapitalization in its text editor, since markdown
  source text MUST NOT be silently rewritten by text-input conveniences
  meant for prose.
- **plain-text-uses-the-theme-code-font**: Both the default editor and
  viewer MUST observe the ambient theme and set the text area's
  background, foreground, cursor/selection tint, and font from the
  theme's code role rather than the platform's system default, since the
  code role is the theme's own monospaced role, and a plain-text markdown
  pane should follow the selected theme's code font instead of the
  system's.

