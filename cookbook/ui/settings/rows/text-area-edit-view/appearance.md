
- **Corner radius**: Not applicable — no custom layer or drawn shape is
  added to the editor or its scrolling container; the scrolling container
  keeps whatever corner rendering its default bordered style draws.
- **Padding**: The vertical layout uses 8pt of spacing between the label and
  the scrolling container, pinned directly to the component's own edges with
  no additional constant — 0pt of outer padding beyond that 8pt internal
  gap. Inside the editor, the typed text is inset 4pt on the top and 4pt on
  the bottom, and symmetrically 4pt on each side, within the scrolling
  container's content area.
- **Font**: The label resolves to the button role's default style: 13pt,
  medium weight, proportional. The editor's typed text uses the body role's
  style (13pt, regular weight, proportional) when monospaced is `false`, or
  the code role's style (12pt, regular weight, monospaced) when monospaced
  is `true`. Both scale with the active theme's size scale and repaint on a
  theme change.
- **Background**: The editor's and the scrolling container's backgrounds
  both resolve to the theme's control-background color — the theme's
  background blended 9% toward its foreground — recomputed on every theme
  change; the scrolling container's background is always drawn.
- **Foreground/Text**: The editor's text resolves to the theme's
  primary-text color (the theme's foreground, unchanged), matching the
  label's own role. The caret uses the theme's cursor color; selected text
  uses the theme's selection color as its background and that color's own
  contrast-chosen counterpart as its foreground.
- **Border**: Not customized beyond the scrolling container's bezeled border
  style; the editor itself draws no border of its own.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere.
- **Min/Max size**: The editor's content can grow without limit inside the
  scrolling container; the component's own visible height is fixed by
  visible-height rather than by any min/max constraint on the component
  itself.

