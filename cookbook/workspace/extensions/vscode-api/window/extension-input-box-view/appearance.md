
- **Corner radius**: Not applicable — no corner radius (or other
  layer-drawing property) is set on the root view.
- **Padding**: 12pt leading/trailing padding on every subview. Vertically,
  each present subview's top is pinned 12pt below the previous one — the
  first present view (title, or prompt, or the field) sits 12pt below the
  root's top; the field sits 12pt below whichever of title/prompt is last
  present. The validation message sits 8pt below the field and is pinned
  12pt above the root's bottom edge.
- **Font**: The title resolves the theme's `heading` text style — 15pt,
  semibold, proportional font. The prompt and validation message both
  resolve the theme's `caption` text style — 11pt, regular weight; the
  validation message's text style never changes with severity, only its
  color role does. Both scale with the active theme's `sizeScale` and
  repaint on a theme change. The field itself has no font set of its
  own — it renders in the platform's stock default font for a text field,
  not driven by the theme's typography at all.
- **Background**: The root view has no background color set on it. The
  title, prompt, and validation message are all transparent, with no
  border or bezel of their own. The field's fill is the platform's stock
  control chrome; no background-color override is set on it.
- **Foreground/Text**: The title uses the theme's `primaryText` role (the
  active theme's foreground color at full strength). The prompt uses
  `secondaryText`. The validation message's role switches with severity —
  `danger`/`warning`/`secondaryText` for `error`/`warning`/`information` —
  recomputed live on every `showValidation(_:)` call and on theme change.
  The field's text color is never set of its own; it renders in the
  platform's stock default text color, not theme-driven.
- **Border**: Not applicable for the title, prompt, and validation
  message — none has a border or bezel. The field's border is the
  platform's stock control bezel; no custom border is configured.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere
  in this component.
- **Min/Max size**: The panel's preferred size fixes width at 480pt
  exactly (no min/max range around it) and sets height to the root
  content's fitted height, floored at 72pt with no explicit ceiling.

