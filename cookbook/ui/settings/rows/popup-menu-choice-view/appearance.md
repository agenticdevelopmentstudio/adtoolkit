
- **Corner radius**: Not applicable — the component adds no custom layer or
  drawing code; it only composes a stock label and a stock popup control
  into a row.
- **Padding**: The row layout inserts a flexible spacer between the label
  and the popup (label, spacer, popup, in that order) and sets the row's
  spacing to `SettingsLayout.default[.rowSpacing]` = 8pt, which applies to
  the label→spacer gap; the spacer→popup gap is explicitly zeroed, so the
  spacer's own width is the only thing between the label and the popup.
  The component additionally pins the popup's horizontal content-hugging
  priority high (see **resists-popup-stretch**), so the spacer — not the
  popup — absorbs the row's leftover width. The row is pinned to the
  component's edges with no additional constant, so the component
  contributes 0pt of its own outer padding beyond that internal 8pt/0pt
  spacing.
- **Font**: The label uses the button text role, resolving to 13pt, medium
  weight, proportional system font. The size scales with the active
  theme's size scale (`1.0` by default) and the label repaints
  automatically on a theme change. The popup is a stock control; no font
  is set on it in source, so it renders with the platform's own default
  control font.
- **Background**: None (transparent) — the label draws no background or
  border of its own, and neither the view nor the row layout sets a
  background color of its own. The popup draws no bezel background once
  borderless (see Border).
- **Foreground/Text**: The label (`.primaryText` role) resolves to the
  active theme's foreground color at full strength, recomputed live on a
  theme change. The popup's selected-item text color is the platform's own
  borderless popup rendering (the design rationale describes it reading as
  "secondary text"); this component sets no color on the popup.
- **Border**: None — the popup's borderless setting removes its default
  bezel; no other border is drawn or configured anywhere in this
  component.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  this component.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set in source; sizing is governed by the label's and the
  popup's own intrinsic content sizes, the row's 8pt spacing, the popup's
  high horizontal hugging, and the row's edge pinning.

