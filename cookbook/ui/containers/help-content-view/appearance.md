
- **Corner radius**: Not applicable to this component itself — it has no
  corner radius set of its own anywhere in source. (The rounded corners
  visible on each topic card belong to a Group View's own card surface —
  10pt — which is that component's concern, not this file's.)
- **Padding**: The heading label is inset 20pt from the view's top and
  leading edges, and constrained to stay at least 20pt from the trailing
  edge. The scroll view below it has zero inset on its leading, trailing,
  and bottom edges, and starts exactly at the heading label's bottom edge
  with no additional vertical gap constant of its own — any visible gap
  between "Help" and the first topic card comes from the panel's own 20pt
  top inset inside the scrolled content, not from a spacing value in this
  component's own source (see Design Decisions).
- **Font**: The heading label uses the theme's `.heading` text role, which
  defaults to 15pt semibold and scales with the active theme's size scale.
  Topic titles and bodies are styled entirely by a Group View's own header
  (`.secondaryText`/`.caption`) and by an Explanation View
  (`.secondaryText`/`.caption`); this component sets no font of its own for
  either.
- **Background**: The view's own background color is the theme's
  `windowBackgroundColor`. The scroll panel draws no background of its
  own, so this color shows through the entire scroll area; the inner panel
  separately paints its own background with the same `windowBackgroundColor`,
  kept in sync by the same theme-change mechanism.
- **Foreground/Text**: The heading label's text color is
  `palette.primaryTextColor`.
- **Border**: None — no border is drawn or configured anywhere in this
  component's own source.
- **Shadow**: None — no shadow is drawn or configured anywhere in this
  component's own source.
- **Min/Max size**: None declared on this component itself — no explicit
  width or height constraint appears in source. The view fills whatever
  frame its container (the drawer) gives it; topic content that exceeds
  that frame's height scrolls rather than being clipped or truncated
  (`independently-scrolling-content`).

