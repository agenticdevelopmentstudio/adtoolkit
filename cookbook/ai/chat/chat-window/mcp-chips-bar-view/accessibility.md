
- **Role/trait**: Not explicitly set anywhere in source — no explicit
  accessibility role override is applied in this file. The button, each
  toggle, each icon, and each text label carry the platform's own default
  role for their kind (button, switch/toggle, image, static text)
  automatically.
- **Label requirements**: The toggle button's accessible label comes from
  its visible label text, which is used as the default accessibility label;
  no separate label override is set. Neither the rack icon nor the
  chevron-down icon carries an explicit accessibility label or hidden flag
  in source; the platform supplies a system default description for each
  named icon, and the two icons are separate accessibility elements from the
  button rather than grouped into one. Each picker row's label comes from
  the server's name, falling back to "Unknown" when missing.
- **Announce state changes**: Not applicable beyond the platform's own
  default — source posts no explicit accessibility change notification when
  the button's label text or a row's toggle state changes; the button label
  and each toggle are standard framework controls whose accessible value
  updates are surfaced by the framework itself when their bound content
  changes, with no bespoke announcement code in this file either way.
- **Minimum tap target**: Not applicable — this targets pointer and
  trackpad input, not touch. Source sets no explicit minimum width or
  height on the button or on a picker row; the 44×44pt (iOS) / 48×48dp
  (Android) minimum described in Platform Notes applies to the touch-
  platform translations, not to this pointer-based control.
- **icon-grouping**: Neither the rack icon nor the chevron-down icon in the
  button's label is marked hidden from assistive technology or folded into
  the button's label as a single element, so each remains its own,
  separately-spoken image element to the screen reader.

