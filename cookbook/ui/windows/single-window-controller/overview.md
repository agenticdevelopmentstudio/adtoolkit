
This is a base class for managing exactly one live window per logical window
ID. A subclass supplies a window ID and content at construction, and may
override the window's title, default content rect, style options, minimum
size, and a configuration hook to shape the window before it is first shown.
The window itself is not built at construction — it is built lazily, the
first time the platform asks for the window to be loaded (typically driven by
the first call that shows it), as a utility-style window when the style
options request a utility or HUD appearance, otherwise a standard window.

Once built, the controller wires itself to two toolkit-wide subsystems: the
window frame manager, which restores and re-saves the window's frame and
visibility, and the window registry, which tracks one live controller per
window ID so callers can look an open window up by ID. The controller also
supports "content-hugging" resizing through a fit-to-content operation, an
optional HUD configuration for translucent floating utility windows, and
conformance to a single-instance protocol for call sites that want a single
shared instance addressable through a class-level accessor.

The class's own header doc comment shows a usage example that calls a
single-argument initializer and overrides a content-factory method (also
mentioning a second, view-returning factory method). Neither of those exists
anywhere in the implementation below: the only initializer takes both a
window ID and content, and there is no content-factory override point at all
— the content is a fixed, required constructor argument (see Design
Decisions for how this recipe treats the mismatch).

