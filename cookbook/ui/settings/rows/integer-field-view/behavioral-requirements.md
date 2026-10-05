
The wrapped number field view's own requirements — label/field
construction, theming, activation and delegate wiring, fixed-label-width
layout, locale-aware parsing, clamping, revert-on-invalid, and
external-change sync — are documented at
`adtoolkit://cookbook/ui/settings/rows/number-field-view#behavioral-requirements`. The requirements
below are this component's own: what it does to construct, forward to, and
expose that wrapped view.

- **wraps-number-field-view**: Component MUST construct a private, generic
  number field view, passing the supplied range view model as its view
  model and the view model's minimum/maximum values as its own
  minimum/maximum bounds.
- **exposes-constituent-views**: Component MUST expose the label and text
  field as public properties, set to the wrapped view's own label and
  text-field instances.
- **arranges-single-child**: Component MUST add the wrapped view as its
  only subview and pin it to its own top, leading, trailing, and bottom
  edges, contributing no additional outer padding of its own.
- **forwards-editing-end-to-wrapped-field**: WHEN the component is
  notified that editing of its text field has ended, it MUST commit that
  edit on the wrapped view.
- **default-field-width**: Component's initializer MUST default the field
  width to 52 points when the caller supplies none — narrower than the
  wrapped view's own uncalled default of 72 points (see Design Decisions)
  — and MUST pass that value through to the wrapped view's own field-width
  parameter.
- **forwards-label-width**: Component's initializer MUST pass its own
  label-width parameter (default none) through unchanged to the wrapped
  view.
- **requires-view-model-at-construction**: Component MUST be constructible
  only with a view model supplied at construction time; construction paths
  that could produce an instance without one (e.g. a bare/default
  construction path or a serialization/decoding-based construction path)
  MUST be rejected (see Platform Notes for the mechanism the source uses).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

