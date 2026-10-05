
- **Corner radius**: None. No corner radius is set on the view or on any crumb button.
- **Padding**: Crumb stack inset 8pt from the leading edge, at most 8pt from the trailing edge (an upper bound, not a fixed value), 2pt from the top edge, and 2pt from the bottom edge. 2pt of stack spacing separates each crumb from its neighboring chevron.
- **Font**: Crumb titles — system font at the platform's small system font size. Chevron icon — 9pt point size, regular weight.
- **Background**: None. No background color is set on the view or on any crumb button.
- **Foreground/Text**: Crumb button title — the platform's default button title color (a system label color). Chevron — the platform's secondary label color.
- **Border**: None. Crumb buttons are borderless, with an inline button style.
- **Shadow**: None specified in source.
- **Min/Max size**: None specified. No crumb button has a minimum or maximum width or height constraint; a crumb may shrink to its truncated content because of its low priority to resist compression (see **crumb-yields-width-before-container**), and the stack's trailing inset is an upper bound, not a fixed width.

