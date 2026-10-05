
- **Corner radius**: 8pt
- **Padding**: icon leading 12pt from the row's leading edge, top 12pt; the
  title/description/status column's leading edge sits 10pt from the icon's
  trailing edge; the action button's trailing edge sits 12pt from the row's
  trailing edge; the status row's bottom edge sits 10pt from the row's
  bottom edge; description-to-button gap is 12pt; title-to-description gap
  is 2pt; description-to-status-row gap is 6pt
- **Font**: title 13pt medium; description 11pt regular; status label 11pt
  medium; drawn with the platform's system font
- **Background**: white at 3% opacity, rendered with a backing layer
- **Foreground/Text**: title uses the platform's default label text color
  (unset by source); description uses the secondary label color; status
  label color tracks the current status (success color / warning color /
  secondary label color)
- **Border**: 0.5pt, white at 6% opacity
- **Shadow**: none — not set anywhere in source
- **Min/Max size**: row height `>= 72pt` (no maximum); icon fixed 24×24pt;
  status dot fixed 8×8pt; action button fixed width equal to the widest of
  `"Open Settings"` and `"Allow…"`, measured once by the sizing probe
  described above

