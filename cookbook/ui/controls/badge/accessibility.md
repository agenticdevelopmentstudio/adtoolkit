
- Role: the component itself has no explicit accessibility role override in
  the source. Its child label is the platform's standard read-only label
  control, which the platform exposes to assistive technology as static
  text by default.
- Label requirement: satisfied unconditionally — the label always carries
  the `text` argument passed at construction or restyle
  (`displays-caller-text`); the only way the label reads empty is if the
  caller passes an empty string.
- Announce state changes: not applicable beyond the label's own text — the
  component has no loading or disabled state to announce (see States); the
  restyle operation re-assigns the label's text synchronously, and the
  platform's standard label accessibility support reflects text changes
  without any custom code in this component.
- Minimum tap target: Not applicable — the component defines no
  target/action, gesture recognizer, or click handling in the source; it
  is a purely visual, non-interactive display element with no tap target
  to size.
- **minimum-contrast-ratio**: The component performs no WCAG contrast-ratio check. In the filled style it picks black or white text with a BT.601 luminance heuristic (`0.299·R + 0.587·G + 0.114·B` > 0.6); in the outlined style it assigns `color` directly to the text and border with no check against the host background. Whether either meets a specific ratio (for example 4.5:1) depends on the caller's colors.

