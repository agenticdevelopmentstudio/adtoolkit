
- **Decision**: The caption, when supplied, is wrapped in the Explanation
  View rather than being built as a second label local to this component.
  **Rationale**: per the source's own comment on `captionView`, this is "so
  it wraps inside the panel by the one policy every settings blurb shares
  instead of a copy of it" — the wrapping, compression, and hugging behavior
  a multi-line settings caption needs is owned once, by the Explanation
  View, and reused here rather than re-implemented.
  **Approved**: pending
- **Decision**: The title label's width is never constrained to the
  stack's width, while the caption view's width is
  (**matches-caption-width-to-stack**).
  **Rationale**: not explained in source comments beyond the code itself.
  The title label keeps its default single-line, clipped configuration and
  needs no width constraint to wrap correctly; the caption view wraps by
  design (per the Explanation View's own configuration) and needs a known
  width to wrap *against* — without the constraint, a wrapping label
  reports its one-line intrinsic width instead of the width the panel
  actually gives it, the same reasoning the Explanation View recipe
  documents for that view's own horizontal-compression decision.
  **Approved**: pending
- **Decision**: (AppKit/UIKit) The gap above a Panel Heading View inside a
  panel is widened to `1.5×` the panel's group spacing by the panel's own
  add-heading operation, not by this component itself.
  **Rationale**: the panel's own source comment on that operation states
  "the gap above a heading is wider than the gap between two cards, because
  that gap is what says the heading belongs to what comes *after* it — at
  the stack's own spacing it reads as a caption trailing the card above."
  This spacing decision is recorded here for context because it is the one
  call site that constructs this component, but that call site's own
  source is not part of this recipe's source, so it is not a requirement of
  this component itself.
  **Approved**: pending

