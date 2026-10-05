
- **Decision**: `presentPopover(for:relativeTo:)` unconditionally closes `activePopover` before showing a new popover.
  **Rationale**: A `.transient` popover (see **popover-transient**) closes when the user clicks outside it, but clicking a second crumb is not that click — the button's own click action is delivered first — so without this guard, two popovers listing different directories' siblings could end up open at once.
  **Approved**: pending

- **Decision**: `popoverDidClose(_:)` clears `activePopover` only when the closing popover is the one currently tracked as active.
  **Rationale**: A `.transient` popover dismissed by an outside click reports its closure asynchronously. Clearing `activePopover` unconditionally would wrongly discard the reference to a popover that has already replaced it by the time the closure notification arrives; the guard keeps the field pointing at whichever popover is actually still open.
  **Approved**: pending

- **Decision**: All crumb-title and crumb-directory computation is pure `URL` path-component arithmetic; `BreadcrumbView` performs no filesystem access itself.
  **Rationale**: Confining filesystem access to `BreadcrumbPopoverViewController`, shown only once a crumb is clicked, keeps the crumb-to-directory mapping testable without touching disk and keeps the strip's own behavior fully predictable from its `rootURL` and `fileURL` inputs alone.
  **Approved**: pending

- **Decision**: `rebuild()` runs on every `fileURL` assignment, including a reassignment of the same value, rather than skipping the rebuild when the new value equals the old one (see **rebuild-on-every-file-assignment**).
  **Rationale**: `fileURL`'s `didSet` observer calls `rebuild()` unconditionally, with no equality check. This is the plain, simple behavior of a Swift property observer rather than a deliberate optimization; a port is free to add an equality check to skip redundant rebuilds without breaking any observable contract of this component.
  **Approved**: pending

