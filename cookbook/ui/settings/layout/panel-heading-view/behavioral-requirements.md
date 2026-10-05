
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **exposes-title-label**: The component MUST expose its heading label as
  a public, immutable stored property.
- **exposes-caption-label**: The component MUST expose a public, read-only
  computed property that returns the caption view's own label when a
  caption view exists, and nothing when it does not.
- **styles-title-as-primary-heading**: The component MUST style its
  heading label with the primary-text color role and the heading text
  role.
- **sets-title-text-from-caller**: The component MUST initialize its
  heading label's displayed text to the caller-supplied title parameter,
  unmodified.
- **creates-caption-view-when-caption-given**: When the caller-supplied
  caption parameter is non-empty/present, the component MUST construct a
  caption view (see the Explanation View recipe) built from that string.
- **omits-caption-view-when-caption-nil**: When the caller-supplied
  caption parameter is absent, the component MUST NOT construct a caption
  view; the internal caption-view reference MUST be absent too.
- **stacks-title-and-caption-vertically-leading-aligned**: The component
  MUST arrange the title label, followed by the caption view when one
  exists, in that order, as the children of a vertical stack with
  leading alignment.
- **spaces-title-from-caption**: The component MUST set the stack's
  spacing to the standard caption-spacing value (6pt), regardless of
  whether a caption view is present.
- **matches-caption-width-to-stack**: When the caption view exists, the
  component MUST constrain its width equal to the stack's width. No
  equivalent width constraint is applied to the title label.
- **fills-bounds-with-zero-inset**: The component's content MUST fill the
  view's own bounds, with zero inset on every side. (See the Platform
  Notes for the source's constraint-based mechanism.)
- **requires-title-at-construction**: The component MUST NOT be usable
  without a title supplied at construction. A bare/default construction
  path with no title, and a deserializing/decoding-based construction
  path, MUST both fail rather than produce a usable instance with no
  title (see Platform Notes for the source's exact mechanism and
  messages).

