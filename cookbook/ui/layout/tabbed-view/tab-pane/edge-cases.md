
- **Null/empty input - model absent**: The model name is nil → the agent
  label MUST show the agent name alone, with no separator.
- **Null/empty input - branch/summary absent**: The branch/summary are nil →
  the corresponding label MUST be hidden rather than shown empty.
- **Null/empty input - data source absent**: No data source is set when
  reload is called → the component MUST take no action beyond ensuring the
  view is loaded, leaving whatever was last displayed unchanged. This is
  the source's only handling of a missing dependency; no error, placeholder,
  or logged diagnostic is produced.
- **Boundary values - depth at the recession ceiling**: Stack depth at `3`
  (the maximum) or any larger value MUST recede the card by the same amount
  as depth `3` - recession does not keep growing past that ceiling.
- **Boundary values - content far below/above the card's natural size**:
  Content shorter than the minimum width/height MUST still measure at the
  floor; content wider than the maximum width MUST clamp at the cap rather
  than overflow.
- **Redundant state change**: Setting the stack depth to its own current
  value MUST be a no-op - no animation starts and the depth-change logic is
  not re-run.
- **Concurrent access**: Not applicable in the general sense - every
  property and method that touches display state runs on a single
  execution context, so there is no multi-threaded mutation path to defend
  against. See Platform Notes.
- **Error states - dependency unavailable**: The only external dependency is
  the data source; its absence is handled as described above (no-op), not
  as a surfaced error. There is no network, database, or file-system
  dependency in this component to fail.
- **Offline/disconnected state**: Not applicable - the component performs no
  networking of its own; all content arrives synchronously from data-source
  calls.
- **Repeated reload with changing values**: Calling reload twice with a data
  source that has changed its answers between calls MUST update every
  label, the title, and the preferred content size to the new values on the
  second call, including newly appearing/disappearing branch or summary
  text.
- **View never attached to a window**: A depth change on a pane whose view
  has never been added to a window's view hierarchy MUST apply immediately
  with no animation, since there is nothing on screen to animate and an
  animated constraint would read a stale value if measured right after.
- **Edge-dependent measurement slack (documented quirk, not a guaranteed
  invariant)**: The content size's slack term (twice the deepest recession)
  is edge-dependent - `24` pt on a vertical edge (`3` steps × `4` pt × `2`)
  versus `8` pt on a horizontal edge (`1` step × `4` pt × `2`) - so, in
  principle, the same content could measure a different preferred content
  size depending solely on which edge hosts the pane. The deepest-recession
  calculation reuses the same recession formula used elsewhere, whose body
  answers a different question for a vertical edge (how far the deepest of
  several stacked cards recedes) than for a horizontal edge (a constant
  single-step recession) - the two questions happen to share one
  implementation. Every existing call site and test happens to mask this:
  short content is floored to the minimum and long content is capped at the
  maximum, regardless of which slack value applied (see tab-pane-010), so
  the difference has never been observed to change a real layout, but the
  formula itself is not edge-independent when content sits strictly between
  the floor and the cap.

