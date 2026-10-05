
- **Corner radius**: Not applicable — the container is a plain layered view with no corner radius set anywhere in this component.
- **Padding**: Not applicable — the incoming child's view is pinned edge-to-edge to the container with a constant of 0; there is no inset.
- **Font**: Not applicable — this component draws no text of its own. Text belongs to whichever content is on screen: the placeholder's labels, or the hosted panel's rendered page.
- **Background**: The container's background is filled with the active theme's `.surface` color, resolved through the theme-observing mechanism and reapplied on every theme change.
- **Foreground/Text**: Not applicable — no text or foreground color is set in this component.
- **Border**: Not applicable — no border is set anywhere in this component.
- **Shadow**: Not applicable — no shadow is set anywhere in this component.
- **Min/Max size**: Not applicable — the container carries no width or height constraint of its own. It is constructed with an initial frame of 300×200, which is discarded the moment the pane host's layout system takes over sizing.

