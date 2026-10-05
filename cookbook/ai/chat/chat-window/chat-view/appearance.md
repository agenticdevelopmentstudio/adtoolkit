
- **Corner radius**: None on the view itself; children (bubbles, the typing indicator) set their own and are out of this component's scope.
- **Padding**: Transcript content: 20pt top/bottom, 16pt leading/trailing (see **transcript-content-insets**). Input row: 14pt top/bottom, 16pt leading/trailing (see **input-row-insets-and-spacing**). Status row: 6pt top/bottom, 16pt leading/trailing.
- **Font**: Composer field and prompt label use the active theme's body font (`palette.font(.body)`); the status label uses the theme's caption font (`palette.font(.caption)`).
- **Background**: The theme's `chatSurface` color fill while `drawsBackground` is `true`; transparent otherwise (see **background-fill-toggle**). Composer field itself has no background fill (`drawsBackground = false`, bordered = false, no focus ring).
- **Foreground/Text**: Composer field text uses `primaryText`; its placeholder uses `placeholderText`. Prompt and status labels use `secondaryText` when the composer is enabled, `placeholderText` when it is disabled.
- **Border**: A 1pt hairline in the theme's `divider` color, spanning the footer's full width, between the status row and the input row (see **footer-divider**). No border on the view itself or on the composer field.
- **Shadow**: None declared anywhere in this source.
- **Min/Max size**: Transcript scroll view has a minimum height of 200pt (see **transcript-minimum-height**); no maximum width or height is declared on the view. The view's own minimum width is deliberately *not* pinned to any bubble's measured width (see Design Decisions).

