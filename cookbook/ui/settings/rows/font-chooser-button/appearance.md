
- **Corner radius**: Not set directly; the rounded corners come entirely
  from the component's stock rounded-button chrome (see
  **rounded-momentary-style**). No custom drawing code appears in source.
- **Padding**: Not set; the component adds no internal padding of its own
  beyond its stock control's default content insets.
- **Font**: Dynamic rather than fixed. `font` is always the font last given
  to the component (or `nil`) converted to the sample size (12pt), or the
  system font at 12pt when no font was chosen. Not theme-driven.
- **Background**: Not set; the component draws no background of its own —
  its stock rounded-button chrome.
- **Foreground/Text**: Not set; no tint or attributed-title customization
  appears in source, so the title renders in the control's stock default
  text color.
- **Border**: Not set; the border is the control's own default, unmodified
  by source.
- **Shadow**: Not set; no shadow customization appears anywhere in source.
- **Min/Max size**: No explicit width or height constraint is set by
  default (see **yields-width-under-compression** and
  **expands-to-fill-remaining-width**), so the button gives up width first
  under compression and does not hug its content horizontally. An explicit
  fixed width optionally activates one width constraint (see
  **fixed-width-constraint**); no height constraint is ever added — height
  is intrinsic to the control at the drawn font's line height.

