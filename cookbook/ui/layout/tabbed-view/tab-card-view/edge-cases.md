
- Null/empty input (MUST): Replacing the status symbols with none MUST leave
  the status row with no icons. The card's content size MUST still return at
  least `240×136pt` even when every label's text is empty and no status
  symbols are set, because of the unconditional floor/ceiling in the content
  size calculation.
- Boundary values (documented behavior, not a gap): Stack depth accepts any
  integer with no lower or upper clamp. The recession calculation treats any
  depth `≤ 0` as zero recession, while front-card status requires depth `==
  0` exactly — so a negative depth draws the non-front palette (window
  background/border/tertiary text) at zero inset and zero overhang, a
  combination no depth of `0` or greater produces. See Design Decisions. On
  a vertical edge, any depth of `3` or more MUST produce the same `12pt`
  recession.
- Concurrent access: Not applicable — the component confines all of its
  mutable state and methods to a single execution context, so there is no
  path for two threads to mutate one instance at the same time. See Platform
  Notes.
- Error states (MUST): Replacing the status symbols MUST substitute an empty
  placeholder image when a symbol name fails to resolve to an icon, rather
  than crashing. The card's background painting MUST draw nothing when its
  stroke bounds have zero or negative width or height, rather than
  constructing a degenerate path.
- Offline/disconnected: Not applicable — this component performs no
  networking of any kind; every value it displays is handed to it
  in-process by its controller's reload operation.

