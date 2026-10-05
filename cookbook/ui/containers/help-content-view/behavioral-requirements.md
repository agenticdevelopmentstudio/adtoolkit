
- **fixed-help-heading**: Component MUST display a label reading exactly
  `"Help"`, inset 20pt from the view's top and leading edges, and free to be
  narrower than the available width but never wider — its trailing edge
  never crosses the same inset from the view's trailing edge. See Platform Notes for the exact anchor equations and the
  literal inset constant's source.
- **independently-scrolling-content**: Component MUST host topic content in
  a scrollable panel, positioned directly below the heading with no gap,
  and spanning the view's full leading/trailing/bottom edges with no
  inset, so the heading stays fixed on screen while the topic content
  beneath it scrolls independently. See Platform Notes for the exact anchor equations.
- **topic-groups**: For each topic in the supplied content, Component MUST
  add one Group View titled with the topic's `title`, containing exactly
  one Explanation View showing the topic's `body`, to the scrolled panel,
  in the same order the topics array provides.
- **empty-state**: When the content-setting operation is called with no
  content, or with content whose topics array is empty, Component MUST
  display exactly one group titled `"No Help Yet"` containing one
  explanation row with the fixed sentence "This panel doesn't have any
  help written for it. Its controls each carry their own explanation
  underneath." — instead of leaving the scroll area blank.
- **wholesale-replacement**: Each call to the content-setting operation
  MUST discard every previously displayed group/explanation row and build
  an entirely new panel from the given content, rather than diffing or
  mutating the views from a prior call.
- **scroll-reset**: Each call to the content-setting operation MUST return
  the visible scroll position to the top of the content.
- **theme-application**: Component MUST resolve and apply the current
  `SemanticPalette` immediately when constructed, and again on every
  subsequent theme change, updating: the view's own background color, the
  heading label's font, and the heading label's text color.
- **window-background**: Component's background color MUST be set to the
  theme's `windowBackgroundColor` — the same ground as the window and
  drawer around it — so that the topic cards (a Group View's
  elevated-surface fill) are what visibly stand out, rather than a
  heading-shaped band of a second, near-identical color above them.
- **coder-init-unavailable**: The view MUST be constructible only in code. Constructing it from a serialized or archived representation MUST be refused as a programmer error that terminates, producing no instance.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

