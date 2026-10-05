
- **Null/empty input**: The view model's progress value is optional;
  absence is the documented indeterminate case, not an error (per the view
  model's own doc comment). The view model's title is a non-optional,
  non-empty-guarded string; an empty string has no observable effect on
  this component itself, since the view never reads title (see Design
  Decisions).
- **Boundary values**: The indicator's minimum/maximum values are never
  set by this component, leaving the indicator's default 0–100 range in
  effect. The component neither validates nor clamps the progress value
  before assigning it to the indicator; a value at exactly `0.0` or
  `100.0` renders as fully empty or fully filled, and a value outside that
  range (negative, or greater than `100.0`) is passed through to the
  indicator unmodified — any resulting clamp or visual boundary is the
  indicator's own native display behavior, not something this component
  governs.
- **Concurrent access**: Not applicable — both the component and its view
  model are confined to a single execution context
  (**confines-to-ui-thread**); that confinement is enforced at compile
  time on platforms that support it, and serializes construction,
  subscription delivery, and progress mutation at runtime.
- **Error states**: Not applicable — the component performs no network,
  database, or file-system access of its own. It only reflects whatever
  value the view model's progress reports; any error signaling for the
  underlying operation the progress represents is the caller's
  responsibility, outside this component.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking.
- **View deallocated mid-progress**: The subscription is held in a stored
  property with no explicit teardown override in source; when the view is
  deallocated, the platform's own reference-counting releases that
  property, which cancels the subscription through its own default
  teardown behavior — not custom code in this component.
- **Rapid successive progress updates**: Each published value is delivered
  synchronously, in order, on the same execution context the progress
  value is mutated from (the UI thread, per **confines-to-ui-thread**); the
  indicator is updated once per published value, with no debouncing,
  throttling, or coalescing in source.

