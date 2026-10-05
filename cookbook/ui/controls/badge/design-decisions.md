
- **Decision**: The restyle operation's `style` parameter defaults to
  filled independently of the badge's current, already-stored style.
  **Rationale**: This is documented here because it produces a surprising
  reset: a caller that calls the restyle operation with just text and
  color on a previously outlined badge, intending only to change its text
  or color, silently flips it back to filled. There is no state read-back
  in the restyle operation to preserve the existing style, so callers that
  want to keep outlined MUST pass `style: outlined` explicitly on every
  restyle call. (Applies to the AppKit implementation.)
  **Approved**: pending
- **Decision**: The contrasting-text-color computation returns white,
  rather than throwing or reusing the current text color, when the
  background cannot be converted to sRGB.
  **Rationale**: Keeps the component always renderable for any color a
  caller passes in (never crashes on an exotic color space, such as a
  pattern image), at the cost of a potentially poor contrast choice for
  those unusual colors. (Applies to the AppKit implementation.)
  **Approved**: pending
- **Decision**: The caller supplies `color` directly instead of the
  component deriving it from a semantic status enum of its own.
  **Rationale**: Per the component's own doc comment, it is
  "theme-agnostic: the caller supplies the color... and the badge owns the
  pill shape, padding, and text styling" — this keeps the component
  reusable across apps with different `SemanticPalette`s rather than
  baking one app's status vocabulary into the shared component. (Applies
  to the AppKit implementation.)
  **Approved**: pending
- **Decision**: The contrasting-text-color computation picks black or
  white using the perceptual-luminance formula
  `0.299·R + 0.587·G + 0.114·B` (the ITU-R BT.601 luma weights) against a
  0.6 threshold, rather than the WCAG 2.x relative-luminance formula
  (which linearizes sRGB and weights channels 0.2126/0.7152/0.0722) or a
  full WCAG contrast-ratio computation.
  **Rationale**: The BT.601 weights are a cheap, well-known heuristic for
  perceived brightness that needs no gamma-linearization step, so a black/
  white choice can be computed inline for any arbitrary caller-supplied
  color. The tradeoff is that, unlike a WCAG contrast-ratio check, this
  heuristic makes no guarantee about a specific minimum numeric contrast
  ratio against the chosen color — see the open question on
  minimum-contrast-ratio. (Applies to the AppKit implementation.)
  **Approved**: pending
- **Decision**: The component exposes no accessibility role or label
  context beyond the platform's default static-text exposure of its
  label — there is no code in the source that would let a screen reader
  announce, for example, that a badge reading "3" is a count versus a
  badge reading "dev" being a status.
  **Rationale**: The component is a plain, non-interactive label; the
  surrounding call site (e.g. a list row's other accessible elements) is
  expected to supply that context, consistent with the component owning
  only pill shape, padding, and text styling and not caller semantics.
  (Applies to the AppKit implementation.)
  **Approved**: pending
- **Decision**: The badge performs no contrast-ratio check: filled text uses a luminance heuristic and outlined text and border use `color` as given.
  **Rationale**: The component owns only shape, padding and text styling, and the caller owns the colors; the heuristic makes no ratio guarantee against the chosen color or the host background. Closing the gap means computing a WCAG ratio for the filled text choice and having the outlined style check against the host background, or auditing each app's palette pairings.
  **Approved**: pending

