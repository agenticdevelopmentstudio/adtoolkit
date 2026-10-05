
- **Corner radius**: Not applicable — this component draws no chrome of
  its own; any corner radius shown by hosted panel content belongs to
  that content's own recipe.
- **Padding**: The detail pane's content view (the detail-pane host) is
  pinned to its container's safe-area top and to the container's leading,
  trailing, and bottom edges with zero additional inset; no other padding
  constant is set in this component.
- **Font**: Not applicable — this component sets no font of its own; the
  search field's font is that field's own responsibility.
- **Background**: The window's background and the detail container's
  background are both set to the active theme's window-background color
  role, on theme application.
- **Foreground/Text**: Not applicable — this component sets no text
  color of its own.
- **Border**: Not applicable — no border is configured in this component.
- **Shadow**: Not applicable — no shadow is configured in this component.
- **Min/Max size**: The detail-pane minimum-thickness floor defaults to
  `400`pt (raised to the nested-detail floor when larger). The sidebar
  item is either draggable between `160` and `360`pt
  (content-sized-sidebar flag `false`) or pinned at the lesser of an
  externally supplied minimum-width override (or the panel list's own
  preferred width) and `480`pt (content-sized-sidebar flag `true`). No
  maximum is set on the detail item.

