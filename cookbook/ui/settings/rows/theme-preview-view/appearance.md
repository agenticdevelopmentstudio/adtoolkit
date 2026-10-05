
- **Corner radius**: The component itself has none. Every sample card box
  has an 8pt corner radius. The controls sample's two simulated text
  fields override this to 5pt. List rows and status badges use 5pt. ANSI
  swatches (in the embedded swatch grid) use 3pt — see that recipe.
- **Padding**: Card content is inset 10pt top / 12pt leading / ≤12pt
  trailing (may be narrower) / 10pt bottom, per card-content-insets. The
  terminal sample instead insets by the theme's resolved terminal padding
  (default 10pt on all four sides) rather than the fixed 10/12/12/10
  shape.
- **Font**: The title, body, caption and button text-style roles from the
  theme's typography, resolved through the palette's role lookup. The
  terminal sample uses the theme's resolved monospaced terminal font
  instead of any text-style role.
- **Background**: The component itself — the theme's window-background
  role. Chrome, list, controls and status cards — the surface role. The
  terminal card — window-background (see terminal-box-background). The
  chrome sample's inner panel — elevated-surface. Text field simulations —
  control-background. Status badges — their status color at 22% alpha.
- **Foreground/Text**: Role-specific per element — primary-text,
  secondary-text, tertiary-text, placeholder-text, on-accent-text,
  selection-text, accent, and the four status colors — as itemized in
  Behavioral Requirements.
- **Border**: The chrome sample's inner panel — 1pt, outline. The controls
  sample's two text-field simulations — 1pt, border. The terminal sample's
  box — 1pt, border. Status badges — 1pt, their status color at 55%
  alpha. No border on the component, its container, any card's outer box,
  or list rows/pills.
- **Shadow**: Not applicable — no shadow or layer-shadow property is set
  anywhere in the component.
- **Min/Max size**: Every card box and the terminal box each carry a
  minimum-width constraint of 280pt; the component and its container have
  no explicit min/max size of their own — the view's overall size is
  driven by its arranged content plus whatever constraints a host applies
  to it.

