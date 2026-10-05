
- **Reduce Motion**: Not applicable. The component calls the
  scroll-to-visible operation directly, with no animation context or
  animator proxy wrapping it, so there is no motion effect to suppress.
- **Increase Contrast**: Not applicable at this component's level. Colors
  are drawn entirely from semantic theme roles; neither this component nor
  the themed view types it uses branch on an increase-contrast accessibility
  setting, so any such adaptation would live in the theme/palette system,
  not here.
- **color-only-selection-cue**: The selected row is conveyed by a background color fill alone (`selected-row-uses-theme-selection-color`) with no additional shape, border, or icon; the component does not respond to Differentiate Without Color.

