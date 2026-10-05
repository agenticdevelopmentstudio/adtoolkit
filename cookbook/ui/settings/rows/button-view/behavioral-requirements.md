
- **creates-button-with-view-model-title**: The component MUST initialize
  its button with a title equal to the view model's `title`, with no press
  action wired yet at creation time.
- **reads-title-once-at-init**: The component MUST read the view model's
  `title` only once, at initialization, to set the button's title; it
  never re-reads `title` afterward. The view model's `title` is immutable,
  so there is no later point at which a changed value could exist to
  re-read.
- **retains-view-model-strongly**: The component MUST hold a strong
  reference to its view model for its own lifetime, keeping the view model
  — and any callback it holds, including `wasPressedCallback` — alive at
  least as long as the component itself.
- **exposes-button-publicly**: The component MUST expose the underlying
  button as a public, read-only property.
- **defaults-placement-to-fill**: The component MUST default its placement
  parameter to fill when the caller supplies none.
- **placement-fixed-at-init**: The component MUST fix placement's effect
  on the button's position at initialization; it exposes no property or
  method to change placement, or to re-run the placement logic, after
  construction.
- **fills-view-in-fill-placement**: WHEN placement is fill, the component
  MUST pin all four edges of the button to the corresponding edges of the
  component, so the button occupies the component's full bounds (see
  Platform Notes for the mechanics the source uses).
- **constrains-vertical-edges-in-non-fill-placement**: WHEN placement is
  leading or centered, the component MUST constrain the button's top and
  bottom edges to equal the component's top and bottom edges.
- **caps-trailing-edge-in-non-fill-placement**: WHEN placement is leading
  or centered, the component MUST constrain the button's trailing edge to
  be less than or equal to the component's trailing edge, so the button
  never extends past the component.
- **aligns-leading-edge-in-leading-placement**: WHEN placement is leading,
  the component MUST constrain the button's leading edge to equal the
  component's leading edge.
- **floors-leading-edge-in-centered-placement**: WHEN placement is
  centered, the component MUST constrain the button's leading edge to be
  greater than or equal to the component's leading edge.
- **centers-button-in-centered-placement**: WHEN placement is centered,
  the component MUST constrain the button's horizontal center to equal
  the component's horizontal center.
- **wires-button-action**: The component MUST route the button's press
  interaction through its own press-handling logic rather than a callback
  attached directly to the button (see Platform Notes for the mechanism
  the source uses).
- **invokes-pressed-callback**: WHEN the button is pressed AND the view
  model's `wasPressedCallback` is set, the component MUST invoke it.
- **takes-no-action-without-callback**: WHEN the button is pressed AND the
  view model's `wasPressedCallback` is unset, the component MUST NOT
  perform any action beyond the button's own native press feedback.
- **requires-view-model-at-construction**: Component MUST be constructible
  only with a view model supplied at construction time; construction paths
  that could produce an instance without one (e.g. a bare/default
  construction path or a serialization/decoding-based construction path)
  MUST be rejected (see Platform Notes for the mechanism the source uses).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

