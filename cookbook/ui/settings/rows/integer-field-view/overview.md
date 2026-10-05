
The integer field view is a settings row: a title label leading and a
narrow, right-aligned integer text field trailing, clamped to a range view
model's bounds. It exists because a slider is the wrong control for a
number the user already knows — "12 points on the left" is typed, not
dragged — and a stepper control makes the user click twelve times to say
it. The type is kept as a thin, forwarding wrapper around a private,
generic number field view, which does the actual work: it builds the label
and field, wires theming and accessibility, and owns the locale-aware
parse/clamp/commit logic. This component stays as its own public entry
point because a bounded integer field is still exactly this call, distinct
from the generic field it forwards to.

The wrapped number field view's own behavior — theming, activation and
delegate wiring, layout when a fixed label width is set, locale-aware
parsing, clamping, revert-on-invalid, and external-change sync — is
documented in full at
`adtoolkit://cookbook/ui/settings/rows/number-field-view`, which this
recipe depends on. This recipe documents only what this component itself
contributes: constructing and forwarding to that wrapped view, exposing
its constituent views, and the construction/thread-confinement
requirements it does not inherit from it.

