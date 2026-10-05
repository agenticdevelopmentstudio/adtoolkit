
- Null/empty input: The view model is a required, non-optional constructor
  parameter, so a missing value is not possible. An empty choices list is
  handled per **tolerates-empty-choices**: the component constructs
  without crashing, adds zero menu items, and no item is selected — the
  popup renders the platform's native empty-menu appearance.
- Boundary values: Not applicable — choices is an ordered, arbitrary-length
  list of discrete label/value pairs with no numeric minimum or maximum to
  bound.
- Concurrent access: Not applicable — the component is confined to a
  single execution context (see **confines-to-ui-thread**), so all
  construction and mutation is serialized to that context.
- Error states: Not applicable — every operation in this component (menu
  item construction, the popup's selection handling, and the committed
  write) is a synchronous, non-throwing call; no error-producing API
  appears in source. The one failure-shaped path — an unresolvable
  selected value — is handled by a silent guard, not an error, and is
  documented as MUST (**ignores-unresolvable-selection**), not as an error
  state.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- Non-matching current value: When the view model's value does not equal
  any choice's value, no matching entry is found and no selection call is
  made — see **leaves-unmatched-selection**. The popup's displayed
  selection is left uncorrected: whatever item it selects by default (its
  first added item), rather than being cleared or forced to a fallback.
- Overwritten external observer: The view model's change-notification
  callback is a single property. This component's initializer
  unconditionally assigns its own sync handler — see
  **replaces-onchange-handler** and the corresponding Design Decision.
  Constructing a second instance of this component (or any other observer)
  against the same view model instance silently drops whatever handler was
  previously registered there.

