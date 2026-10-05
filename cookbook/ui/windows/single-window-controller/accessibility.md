
- **Role**: Not applicable beyond the platform's own default window role; the
  class does not set or alter it.
- **Label**: The window's accessibility identifier (not label) is set
  explicitly, to a slug of the window ID, when building the window, so UI
  tests can address the window by a stable, derived identifier. The window's
  human-facing title (used as its accessible name by the platform's own
  window accessibility support) is the title property, supplied by the
  subclass.
- **Announcements**: Not applicable — the base class performs no
  accessibility-announcement calls of its own; window appearance/disappearance
  announcements are handled by the platform's standard window-server
  behavior, not by this class.
- **Keyboard navigation**: Not applicable at this layer — key-view loops and
  first-responder handling belong to the hosted content, not to this class,
  which never overrides key handling.
- **Touch target size**: Not applicable — this class manages a window, not a
  tappable control; standard title-bar buttons keep the platform's own
  built-in target sizes, which this class does not adjust (it only
  hides/shows the standard buttons, never resizes them).

