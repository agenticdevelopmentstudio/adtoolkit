
- **Corner radius**: None; the view itself has no background shape.
- **Padding**: 16pt above the label, 8pt below it (see **vertical-insets**); no horizontal padding on the view's own edges — the rules run flush to the leading and trailing edges.
- **Font**: Label uses the active theme's caption font (`palette.font(.caption)`).
- **Background**: None; the view has no background fill or layer color of its own.
- **Foreground/Text**: Label text color is the theme's `timestampText` role color.
- **Border**: None on the view; the two 1pt rule lines are filled with the theme's `divider` role color.
- **Shadow**: None.
- **Min/Max size**: None declared; the view's width is whatever its superview gives it (the rules stretch to absorb it), and its height is fixed to the label's own height plus the 16pt/8pt vertical insets.

