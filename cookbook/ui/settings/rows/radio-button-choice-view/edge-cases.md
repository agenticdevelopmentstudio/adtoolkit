
- Null/empty input: The view model is a non-optional, required constructor
  parameter, so a missing value is not possible; the component provides,
  and needs, no nil-handling path for its one required initializer
  parameter.
- Boundary values — empty choices: When the view model's choices are
  empty, no radio buttons are created; the controls group ends up with
  zero arranged elements. The sync pass also has nothing to iterate. No
  crash occurs; the row renders only its heading label. Source performs no
  guard against, or special-casing for, an empty choices list.
- Boundary values — single choice: When the view model has exactly one
  choice, exactly one radio button is created. Per the platform's own
  radio-button behavior, once that button is selected (either at init,
  from a sync pass, or by a user click) it cannot be deselected back to
  "no selection" by clicking it again — a radio-type control has no
  user-driven path back to unselected once selected, and source never
  deselects it from anywhere except a sync pass that finds a different
  choice's value equal to the view model's value.
- Boundary values — current value absent from choices: The sync pass
  performs the selected/not-selected comparison independently for every
  button, so a view-model value matching none of them leaves every radio
  button unselected; source performs no fallback selection and no "at
  least one must be selected" invariant.
- Concurrent access: Not applicable — the component is confined to a
  single execution context (**confines-to-ui-thread**) and its value type
  is required to be safely shareable across contexts, so all construction
  and mutation is serialized to that context.
- Error states: Not applicable — every operation in this component (each
  control's selection action and the committed write) is a synchronous,
  non-throwing call; no error-producing API appears in source.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- Overwritten external observer: The view model's change-notification
  callback is a single property. This component's initializer
  unconditionally assigns its own sync handler, replacing whatever handler
  (if any) was previously registered on that view model instance (see
  Design Decisions for this as a known limitation).
- Native mutual exclusion races the observer round trip: The platform's
  own radio-type control configures each button so that multiple such
  buttons sharing the same immediate parent group natively enforce mutual
  exclusivity — clicking one turns off its siblings in that group
  synchronously, as part of the click, before the component's own
  selection handler even fires. The view model's change-notification
  callback (which drives the sync pass) is delivered on a later turn, not
  synchronously with the write (per the underlying observer's own
  documented dispatch behavior). Between the click and that later turn,
  the visually-selected button is the one the platform toggled natively,
  not one this component set directly; the later sync pass is
  authoritative and will override that native toggle if the view model's
  value does not end up matching it (e.g., another party rejects or
  transforms the write before it reaches the view model).

