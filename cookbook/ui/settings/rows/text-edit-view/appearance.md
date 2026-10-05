
- **Corner radius**: Not applicable — no custom layer or drawn shape is
  added; the text field keeps whatever corner rendering its default bezel
  style draws, which is the platform's own rendering, not this component's.
- **Padding**: The row layout inserts a flexible spacer between the label
  and the text field and uses 8pt of spacing for the label-to-spacer gap;
  the spacer-to-field gap is explicitly zeroed, so the spacer's own width is
  the only thing between the label and the field. The text field is sized
  to absorb the row's leftover width instead of the spacer (see
  expands-text-field-to-fill-row). The row is pinned to the component's own
  edges with no additional constant, so the component contributes 0pt of
  outer padding beyond that internal 8pt/0pt spacing.
- **Font**: The label resolves to the button role's default style: 13pt,
  medium weight, proportional. The text field's typed text uses the body
  role's default style: 13pt, regular weight, proportional. Both scale with
  the active theme's size scale and repaint automatically on a theme
  change.
- **Background**: Not customized — the text field keeps its own default
  editable-field chrome (bordered/bezeled, background drawn); the component
  sets no background/border override on the field, the row, or itself.
- **Foreground/Text**: The label and the text field's typed text both
  resolve to the same role — the active theme's foreground color unchanged
  — recomputed live on a theme change. Placeholder text, when present, uses
  the placeholder-text role instead (see Design Decisions for its contrast
  floor).
- **Border**: Not customized; whatever bezel/border the text field's default
  construction draws (the platform's own rendering) applies unmodified.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set; sizing is governed entirely by the label's and the
  text field's own intrinsic content sizes, the row's 8pt/0pt spacing, the
  sizing behavior described above, and the row's edge pinning.

