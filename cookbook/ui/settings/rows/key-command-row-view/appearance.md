
- **Corner radius**: Not applicable to this component itself — the row
  sets no corner radius of its own; it only arranges four subviews in
  stacked rows. The capture field and the confirm/cancel pair each draw
  their own 5pt-corner-radius chrome, but that is those components' own
  appearance, not this file's.
- **Padding**: The main row uses the button role's default row spacing
  (8pt) between the title label and the flexible spacer inserted after it,
  with the spacer-to-field gap zeroed, so the spacer's own width is the
  only room between the label and the capture field; the capture field,
  confirm/cancel pair, and toggle then sit with that same 8pt spacing
  between each of them. The readout row is built the same way, from a
  blank value label and the status label, so its own leading gap is
  likewise the spacer's width. The outer vertical stack (main row over
  readout row) uses a spacing of 4pt, set directly in source. That outer
  stack is pinned to the component's top/leading/trailing/bottom with no
  additional constant, so the component contributes 0pt of outer padding
  beyond its internal 8pt / 4pt spacing.
- **Font**: The title label (button text role) resolves to 13pt, medium
  weight. The status label and the blank spacer label (caption text role)
  resolve to 11pt, regular weight. Neither the capture field's internal
  label nor the confirm/cancel pair's buttons are styled by this file; they
  are those components' own appearance.
- **Background**: None (transparent) on this component itself — no
  background color is set anywhere in source. The capture field and
  confirm/cancel pair each paint their own themed background layer, but
  that is their own chrome.
- **Foreground/Text**: The title label uses the primaryText role. The
  status label's role switches between secondaryText, success, and danger
  depending on pending-chord availability (see States and
  **colors-status-label-by-availability**); the blank spacer label in the
  readout row keeps its default secondaryText role, unused for display.
- **Border**: Not applicable to this component itself — no border is drawn
  or configured anywhere in source. The capture field draws its own 1pt
  border (accent-colored while recording, otherwise the theme's border
  color) and the confirm/cancel pair draws its own 1pt border; both are
  those components' own appearance.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: This component sets no explicit min/max width or
  height constraint of its own; its size is the sum of its subviews'
  intrinsic sizes plus the row/stack spacing described under Padding. Of
  its children, the capture field fixes its own height to 22pt and its own
  minimum width to 132pt, and the confirm/cancel pair fixes its own height
  to 20pt with two 24pt-wide buttons — both are those components' own
  constraints, reflected here only because they set the row's effective
  minimum width and height.

