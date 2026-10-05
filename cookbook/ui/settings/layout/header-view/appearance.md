
- **Corner radius**: None; the component has no layer or shape of its own.
- **Padding**: Zero on all sides. The label is pinned to the component's
  top, leading, trailing, and bottom edges with no constant offset, so the
  component contributes no padding around its label; any surrounding space
  is entirely the calling container's responsibility (e.g. the Group
  View's header-to-card spacing).
- **Font**: Caption text role — 11pt, regular weight, system font family,
  scaled by the active theme's size scale, unless the active theme
  overrides the caption style.
- **Background**: None; the component draws no background of its own, and
  its label draws no background of its own either.
- **Foreground/Text**: The label's text color tracks the theme's
  `.secondaryText` role. The default derivation is the theme's foreground
  color dimmed 32% toward its background color with a 3.0 minimum-contrast
  floor, unless the active theme supplies an explicit override for that
  role.
- **Border**: None; the component and its label draw no border of their own.
- **Shadow**: None; no shadow property is set anywhere.
- **Min/Max size**: The component sets no explicit size constraint of its
  own. Its effective size is the label's intrinsic content size: the label
  does not wrap, uses single-line mode, and clips rather than truncates
  when it exceeds the width its container allows, so the component (whose
  bounds equal the label's) sizes to a single, non-wrapping, clipped line.

