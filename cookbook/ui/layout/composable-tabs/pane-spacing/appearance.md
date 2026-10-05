
- **Corner radius**: Not applicable — this component draws a rectangular divider fill and defines no corner radius anywhere.
- **Padding**: Not a single vertical × horizontal pair. Four independent edge insets — `top`, `leading`, `bottom`, `trailing` — each an integer in points, default `0`, individually configurable, and converted together into the content-inset structure applied to the window's pane chrome.
- **Font**: Not applicable — this component renders no text.
- **Background**: Painting the divider fills it with the active theme's pane-backdrop color whenever the divider thickness is greater than `1` point, so a wide gutter reads as the same backdrop plane as the frame spacing rather than a colored bar. At `1` point or less, the divider falls back to the platform's own default hairline-divider paint, whose color is the theme's divider role — inherited behavior, out of this component's scope.
- **Foreground/Text**: Not applicable — this component renders no text.
- **Border**: Not applicable — the pane split view paints a divider fill, not a stroked border, and this component defines no border of its own.
- **Shadow**: Not applicable — no shadow appears anywhere in this component.
- **Min/Max size**: `minimumDividerGrab` (`6pt`) is a minimum *interactive* width guarantee used by consumers to widen a divider's hit-test region (see the composable-tabs pane view's own divider-grab widening, out of this recipe's scope) — it does not change what the divider thickness draws. This component's own drawn thickness has no declared minimum or maximum; any clamping of a user-entered value happens in the settings-control layer, not here. (Platform-specific guidance on published minimum divider/gutter widths is in Platform Notes.)

