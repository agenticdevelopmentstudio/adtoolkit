
This is a small rounded "pill" label for a status or category chip (e.g.
"dev", "stopped", "3"). It is theme-agnostic for color: the caller supplies
the tint (typically drawn from a `SemanticPalette`) and the component owns
only the pill shape, padding, and text styling, so it is reusable across
apps that build list rows and status chips. It renders in one of two styles
— filled (solid `color` background with automatically contrasting text) or
outlined (clear background with a `color` border and text) — and can be
restyled in place via the restyle operation, e.g. when the app's theme
changes.

