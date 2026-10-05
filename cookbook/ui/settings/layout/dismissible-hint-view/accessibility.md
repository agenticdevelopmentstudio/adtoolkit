
- **Role**: the hint label is a standard read-only, multi-line label,
  exposed to assistive technology as static text by default; the dismiss
  button is exposed as a button. The component sets no custom
  accessibility role of its own.
- **Label requirements**: the hint label's accessible content is exactly
  the text string passed at construction (text-label); the dismiss
  button's accessible name is the button title (dismiss-button-title,
  default `"Got It"`). Neither carries an additional accessibility-label
  assignment.
- **Announce state changes**: Not applicable beyond the platform's own
  default behavior — hiding the component removes it, and its children,
  from the accessibility tree automatically; no custom screen-reader
  announcement is made.
- **Keyboard navigation**: Inherited from the platform's standard button
  control — Tab/Shift-Tab moves focus onto and off the dismiss button, and
  Space or Return activates it through the action wired in
  dismiss-button-action. The component adds no custom key handling.
- **Minimum tap target**: the dismiss button is deliberately rendered
  small and compact (see dismiss-button-style) — smaller than the
  platform's default push-button size — and the pointer-driven source
  platform applies no touch-target minimum to a control at this size.
  Ports to touch platforms MUST give the equivalent control at least the
  platform minimum (44×44pt on iOS, 48×48dp on Android, 40×40epx on
  WinUI 3).

