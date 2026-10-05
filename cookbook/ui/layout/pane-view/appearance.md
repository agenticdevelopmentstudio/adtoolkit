
- **Corner radius**: None drawn by the pane itself. The default container is a plain rectangle filled with the theme's `windowBackground` surface role; a pane that builds its own container may add one, out of scope here.
- **Padding**: The content inset (default `0`pt) holds both the title bar and the content off the container's edges. The title bar is a fixed 26pt tall. A minimized-to-a-side rail is a fixed 28pt thick.
- **Font**: Not set directly by the pane; the title bar's own label typography belongs to the title bar concept (`depends-on`), out of this recipe's scope.
- **Background**: The pane's own fill is whatever its container-building hook returns; the default is the theme's `windowBackground` surface role.
- **Foreground/Text**: Not set directly by the pane; delegated to the title bar and to the content.
- **Border**: None drawn by the pane anywhere in this concept.
- **Shadow**: None drawn by the pane anywhere in this concept.
- **Min/Max size**: None set by the pane. The container view is given an explicit default frame of 300×200pt when the view is created, before the layout system resolves its real size from the constraints installed immediately after; no min/max width or height constraint is authored anywhere in this concept.
- **Gear button**: A borderless button showing a gear-shaped icon only (no text), tinted with the theme's secondary-text color, with tooltip "Pane options" (see Platform Notes for the exact bezel style and icon asset).

