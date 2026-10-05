
- **Corner radius**: 12pt on the container's own background; 3.5pt on each 7×7pt dot, which is exactly half the dot's side length and so renders a true circle (see **dot-size-and-shape**). The container's 12pt radius on a 28pt-tall pill is less than the 14pt a fully rounded ("stadium") end would need.
- **Padding**: None defined as edge insets. The row of dots is positioned by centering rather than pinned to the container's edges (see **stack-centered-in-container**).
- **Font**: Not applicable; the component renders no text.
- **Background**: Container fill is the active theme's `secondaryText` color at 0.08 alpha (see **container-fill-tracks-theme**); there is no separate "indicator background" role.
- **Foreground/Text**: Not applicable; the component renders no text.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Fixed at 48×28pt via fixed-size layout constraints (see **pill-container-shape**); no minimum or maximum range is declared, so an external constraint or a containing view requesting a different size will conflict with these default-priority (required) constraints (see Edge Cases).

