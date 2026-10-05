
- **three-dot-layout**: The component MUST render exactly three dot elements arranged in a horizontal row with 4pt spacing between them.
- **pill-container-shape**: The component MUST render itself as a fixed 48×28pt container with a 12pt corner radius on its own background.
- **stack-centered-in-container**: The component MUST center the row of dots within the container on both the horizontal and vertical center lines.
- **dot-size-and-shape**: Each dot MUST be exactly 7×7pt with a corner radius of 3.5pt, rendering as a circle.
- **container-fill-tracks-theme**: The component MUST set its own background color to the active theme's `secondaryText` color at 0.08 alpha, applied immediately when the view is constructed and reapplied every time the active theme's palette changes.
- **dot-color-tracks-theme**: The component MUST set every dot's background color to the active theme's `secondaryText` color at full alpha, applied immediately when the view is constructed and reapplied every time the active theme's palette changes.
- **start-resets-dot-alpha**: When `startAnimating()` is called, the component MUST set every dot's opacity to 0.3 before scheduling the animation timer.
- **start-schedules-repeating-timer**: When `startAnimating()` is called, the component MUST make dot 0 the next dot to be highlighted and MUST schedule a repeating tick every 0.35 seconds thereafter.
- **single-dot-highlighted-per-tick**: On each tick, the component MUST animate exactly one dot's opacity to 1.0 over 0.2 seconds while animating the other two dots' opacity to 0.3 over the same 0.2 seconds, and MUST advance which dot is highlighted by one position (wrapping modulo 3) on every subsequent tick.
- **timer-invalidated-on-removal**: The component MUST stop its animation timer when it is removed from the view hierarchy.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

