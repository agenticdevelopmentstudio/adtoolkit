
- **Reduce Motion**: Not applicable. This component contains no
  animation — layout and the footer update run entirely through immediate
  constraint/property assignment; there is no transition or motion effect
  to reduce.
- **Increase Contrast**: Not applicable at this component's level. The
  container and footer delegate all color to the semantic theme roles
  (window-background, surface); neither this component nor the shared
  themed-background mechanism branches on an increase-contrast setting, so
  any contrast adaptation would live in the theme/palette system, not here.
- **Differentiate Without Color**: Not applicable. This component itself
  renders no state that is conveyed by color alone — the only color fills
  are the plain background roles above. Git-status coloring in the file
  tree is rendered by the hosted file tree, a separate component with its
  own recipe.

