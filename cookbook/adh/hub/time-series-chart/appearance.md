
The chart's visual treatment is set entirely by the component and theme tokens.

- **Corner radius**: only the tooltip, at 8px; the plot itself has none.
- **Padding**: the plot has margins of 8px top, 16px right, 0 bottom, 8px left; the y axis reserves 72px of width.
- **Font**: axis ticks use 12px text in the dim-text token; the legend uses 12px text in the muted-text token.
- **Background**: the plot is transparent; the tooltip uses the second surface token.
- **Foreground/Text**: tooltip rows use the text token and the tooltip's x label the muted-text token.
- **Border**: the tooltip has a 1px border in the border token; the x axis has a baseline in the border token; the y axis has no axis line; ticks have no tick marks.
- **Shadow**: none.
- **Min/Max size**: width is 100 percent of the container; height is the height input, default 240px. Lines are 2px wide; the hovered point's marker has a radius of 4px with a 2px outline in the background token.

