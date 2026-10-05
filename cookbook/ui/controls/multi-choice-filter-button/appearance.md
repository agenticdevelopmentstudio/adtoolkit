
- **Corner radius**: Not applicable — the component draws nothing of its
  own and sets no layer or corner-radius property; its corner rounding, if
  any, is the platform's native pull-down bezel.
- **Padding**: Not applicable — no content-inset or padding value is set in
  source; the button's internal padding is the platform's native control
  metrics.
- **Font**: `SemanticPalette.font(.body)` resolves the active theme's
  `.body` role, whose default style is a 13pt, regular-weight, proportional
  system font, scaled by the theme's `sizeScale` and by the reader's live
  text-size setting; an active theme MAY override `.body` with its own
  family/size/weight. Applied at initialization and reapplied on every
  theme change, via an observer that falls back to the Solarized Dark
  theme when no active theme manager exists (e.g. previews or tests run
  without an app host).
- **Background**: Not applicable — the foreground tint color is the only
  color this file sets; the button's fill is the platform's native control
  bezel.
- **Foreground/Text**: The foreground tint color is set to
  `SemanticPalette.primaryTextColor`, which resolves the theme's
  `primaryText` role (an explicit override if the active theme declares
  one, else a value derived from the theme's palette). Reapplied live on
  every theme change via the same observer.
- **Border**: Not applicable — no border is drawn or configured in source;
  the button keeps the platform's native control border.
- **Shadow**: Not applicable — no shadow is drawn or configured in source.
- **Min/Max size**: Not applicable — no explicit width/height constraint is
  set in source; the button's size is the platform's native measured size
  for this control, recomputed on every title change (see
  **resizes-for-longer-titles**).

