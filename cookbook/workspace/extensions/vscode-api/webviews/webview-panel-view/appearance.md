
- **Corner radius**: Not applicable — the view this component shows is a plain webview with no corner radius set; any rounding a rendered page's own CSS applies is the extension's content, out of this component's scope.
- **Padding**: Not applicable — the webview is constructed at a small placeholder size and becomes the component's view directly, with no inset around it; this initial size is discarded once the containing pane's layout system takes over sizing.
- **Font**: Not applicable — this component sets no font of its own; all text belongs to the extension's rendered page.
- **Background**: The webview's background is set from the active theme's surface color, applied immediately when the view is constructed and reapplied on every subsequent theme change.
- **Foreground/Text**: Not applicable — no foreground or text color is set by this component; text color belongs to the rendered page.
- **Border**: Not applicable — no border is set by this component.
- **Shadow**: Not applicable — no shadow is set by this component.
- **Min/Max size**: Not applicable — no width/height constraint is installed on the webview by this component; the initial size is a placeholder only, superseded by the pane host's layout system.

