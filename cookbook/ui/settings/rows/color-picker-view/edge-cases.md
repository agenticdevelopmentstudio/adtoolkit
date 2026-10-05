
- Null/empty input: the view model is a non-optional parameter; nil is
  ruled out by the platform's type system. The component provides, and
  needs, no nil-handling path for its one initializer parameter.
- Boundary values — out-of-range or out-of-gamut color: the component
  performs no clamping or validation of the reported color before writing
  it to the view model's color. Clamping happens one layer down: the view
  model's color setter converts the incoming color to the storage type,
  and that type's initializer clamps each channel to [0, 1] — so an
  out-of-gamut or malformed color is always normalized before it reaches
  storage, but that normalization is the storage type's behavior, not
  this component's. See **delegates-color-clamping**.
- Concurrent access: Not applicable — the component is confined to the UI
  thread, so all access is serialized to that thread; there is no code
  path by which two threads can mutate the view simultaneously.
- Error states: Not applicable — every operation in this file (the color
  well's activation and the view-model write) is a synchronous,
  non-throwing call; no error-producing path appears in source.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- Overwritten external observer: the view model's external-change handler
  is a single property. The component's initializer unconditionally
  assigns its own handler, replacing whatever handler (if any) was
  previously registered on that view model. See **owns-on-change**.

