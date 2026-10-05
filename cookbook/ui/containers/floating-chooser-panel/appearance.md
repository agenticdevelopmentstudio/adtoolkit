
- **Corner radius**: Not applicable — the controller draws no
  custom-cornered chrome; whatever corner rounding appears is the system's
  own standard panel rendering.
- **Padding**: The hosted content view's edge constraints to the container
  view carry no additional constant — 0pt padding on all four sides.
- **Font**: Not applicable — the controller renders no text of its own; any
  text belongs to the hosted content component, a separate ingredient.
- **Background**: Not specified in source — no background color is set on
  the window or the container view in this file; the panel uses the system
  default panel background.
- **Foreground/Text**: Not applicable — see Font.
- **Border**: Not applicable — no custom border is configured in this file;
  standard system panel border applies.
- **Shadow**: Not applicable — no custom shadow is configured in this file;
  the standard floating-panel shadow applies.
- **Min/Max size**: Not applicable — the window is not user-resizable, so
  no min/max size constraint is needed or set; the window's fixed size is
  the `contentRect` value an extending component supplies at construction.

