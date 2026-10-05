
- **Null/empty input**: An empty seed shows an empty transcript until the
  first read lands; an absent send handler greys the composer (per
  `composer-follows-sendability`); an absent line limit shows messages whole
  (per `line-limit`).
- **Boundary values**: A line limit of one is the smallest sensible cap; a
  refresh interval is the caller's to choose and is not clamped here.
- **Concurrent access**: Not applicable beyond the poll: reads are driven by
  the session, and the overlay stays on the UI thread.
- **Error states (dependency/network failure)**: A failed read leaves the
  transcript as it was; a line that cannot be delivered is marked failed by
  the transcript, not by this component.
- **Offline/disconnected state**: Reads fail quietly and the last transcript
  stays on screen.
- **Return while composing** (MUST): Return sends the line instead of closing
  the overlay (per `return-belongs-to-composer`), because an overlay that
  vanished would throw the typed line away; Escape remains the way out.
- **Dismissal during a poll**: Reading stops before the fade (per
  `stop-reading-before-fade`) so no poll lands in the fade and rebuilds a
  transcript nobody will see.
- **Feed pushes**: The feed behind is pushed to when its source changes; the
  host forwards that push through the refresh operation so the overlay is not
  up to one interval behind.

