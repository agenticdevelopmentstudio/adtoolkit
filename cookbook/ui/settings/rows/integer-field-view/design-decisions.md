
- **Decision**: Keep this component as a thin, forwarding wrapper around
  the generic number field view rather than folding its logic in directly.
  **Rationale**: Per the source's own doc comment, "this name stays because
  it is public API of a framework other repos link: a bounded integer
  field is still exactly this call" — the generic view generalizes to
  optional, one-sided bounds that the range view model (which requires
  both) cannot express, so the behavior moved there (see
  `adtoolkit://cookbook/ui/settings/rows/number-field-view`) while
  this component stayed as the compatible entry point.
  **Approved**: pending
- **Decision**: Default the field width to 52pt in this component's
  initializer, rather than reusing the wrapped view's own uncalled default
  of 72pt.
  **Rationale**: This component always passes an explicit field-width
  argument to the wrapped view's initializer, so the wrapped view's 72pt
  default is never reached through this type; 52pt is this component's
  own, narrower, pre-existing default, kept for source fidelity to callers
  that relied on it.
  **Approved**: pending
- **Decision**: (AppKit) Keep this component's own end-of-editing handler
  even though the text field's editing delegate is set to the wrapped
  view, not to this component itself.
  **Rationale**: Per the source's own comment, this method is "kept because
  it was public, and forwards for the same reason" — the platform calls
  the inner view's delegate method in the normal case, but any external
  caller still holding a reference to this component as an editing
  delegate (as public API predating this refactor allowed) still reaches
  the commit path through this forwarding method.
  **Approved**: pending

