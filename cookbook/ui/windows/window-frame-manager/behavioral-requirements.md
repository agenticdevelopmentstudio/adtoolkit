
### Isolation and ownership

- **single-thread-isolation**: The manager MUST be confined to a single
  designated thread; every public operation, the screen-change handler, and
  the injected window-lister callback MUST run on that thread.
- **storage-single-thread-isolation**: The window-state storage protocol
  MUST be confined to that same single designated thread, so storage
  backends are only called from it.
- **concurrency-safe-value-types**: An anchor, a pair of anchors, a
  placement, the persisted window state, the legacy persisted state, a
  screen fingerprint, a window position preset, and a match-quality value
  MUST be safe to pass across concurrency domains (immutable value types).
- **thread-confined-screen-types**: A screen description, the screen
  provider, the live screen description, the live screen provider, and a
  screen-match result MUST remain confined to the caller's own thread rather
  than being safe to hand across concurrency domains, so the compiler keeps
  them in the caller's isolation domain.
- **sole-writer-precondition**: Callers MUST ensure this process is the only
  writer of a given window id's persisted state; the write-through cache is
  safe only because this process is the sole writer of a given id's state,
  and the manager never re-reads storage for an id it has cached.
- **screen-observer-registration**: Construction MUST register one observer
  with the injected screen manager that forwards each screen change to the
  screen-change handler through a weak reference to the manager.
- **start-observing-delegates**: The start-observing operation MUST forward
  to the screen manager's own start-observing operation and add no
  registration of its own.
- **spec-accessor**: A window controller's registered-spec accessor MUST
  read and write the spec registered under the controller's window ID in the
  window frame manager.

### Data shapes

- **window-placement-fields**: A placement MUST be an immutable, comparable
  value holding a screen fingerprint, a top-left X and Y offset from the
  screen's visible-area top-left (y pointing down), a width and height, a
  relative X and Y (0...1 fractions of travel, 0 = left/top), and a saved-at
  timestamp.
- **persisted-state-shape**: The persisted window state MUST hold a map of
  placements keyed by screen-set id, and a read-only, optional legacy
  record.
- **persisted-state-encode**: Encoding the persisted window state MUST write
  only the placements, and MUST NOT encode the legacy record.
- **persisted-state-decode-v2**: Decoding MUST read the placements when
  present and non-null, with the legacy record set to absent.
- **persisted-state-decode-v1**: When placements are absent or null and the
  payload decodes as a legacy record, decoding MUST produce empty placements
  and that record as the legacy value.
- **persisted-state-decode-degrade**: When the payload has neither a usable
  placements value nor a decodable legacy record (for example an empty
  object, a null placements value, or unrelated fields), decoding MUST
  produce empty placements and no legacy record rather than failing.
- **legacy-state-fields**: The legacy record MUST hold a proportional X and
  Y (bottom-left-anchored fractions of travel), a width and height, a screen
  fingerprint, and a saved-at timestamp.
- **fingerprint-fields**: A screen fingerprint MUST be an immutable,
  comparable value holding an optional display identifier, an optional
  localized name, a resolution width and height, and a main-screen flag.
- **fingerprint-from-screen**: Deriving a fingerprint from a live screen
  MUST take the display identifier from the platform's own per-display
  identity (absent when unavailable), the localized name from the screen,
  the resolution from the screen's full frame (not its visible area), and
  the main-screen flag from whether the screen is the current main screen.
- **screen-info-contract**: A screen description MUST expose its frame, its
  visible area, its fingerprint, and its backing scale factor; a description
  that does not supply a backing scale factor MUST report 2.
- **screen-provider-contract**: The screen provider MUST expose the current
  list of screens and the current main screen; the live screen provider
  MUST map these from the platform's own live screen list and main screen.
- **window-position-values**: A window position preset MUST map "center" to
  (0.5, 0.5), "top right" to (0.85, 0.85), and a custom preset to its two
  supplied values, as bottom-left-anchored fractions of travel (0 =
  left/bottom, 1 = right/top).
- **frame-anchors-shape**: An anchor MUST have exactly the values "start"
  (left or top) and "end" (right or bottom); a pair of anchors MUST hold one
  horizontal and one vertical anchor.

### Frame math

- **clamped-length-rule**: The clamped-length calculation MUST return
  `min(max(desired, minLength), max(visibleLength, minLength))`, so a length
  is never below `minLength`, never past the visible length, and
  `minLength` wins when the two disagree.
- **min-size-wins-everywhere**: The absolute-frame, frame-from-relative-
  position, content-hugging-frame, and frame-validation calculations MUST
  all size each axis with the clamped-length calculation, so a minimum
  larger than the screen is kept and the window overhangs.
- **proportional-position**: The proportional-position calculation MUST
  return `(origin - visibleOrigin) / (visibleLength - windowLength)` per
  axis, bottom-left anchored, clamped to -0.1...1.1, and 0.5 on an axis with
  no positive travel.
- **absolute-frame**: The absolute-frame calculation MUST clamp width and
  height with the clamped-length calculation, then set each origin to
  `visibleOrigin + proportion * max(visibleLength - clampedLength, 0)`.
- **default-frame**: The default-frame calculation MUST equal the
  absolute-frame calculation with the spec's default-position fractions,
  default size, and minimum size.
- **top-left-offset**: The top-left-offset calculation MUST return
  `(window.minX - visible.minX, visible.maxY - window.maxY)`.
- **frame-from-top-left**: The frame-from-top-left-offset calculation MUST
  return a frame at `x = visible.minX + offset.x`,
  `y = visible.maxY - offset.y - size.height` with the given size
  unclamped.
- **relative-position**: The relative-position calculation MUST return the
  top-left offset divided by the travel (`visibleLength - windowLength`) per
  axis, clamped to 0...1, and 0.5 on an axis with no positive travel.
- **frame-from-relative**: The frame-from-relative-position calculation
  MUST clamp the size with the clamped-length calculation, then place the
  top-left at `relative * max(visibleLength - clampedLength, 0)` from the
  visible top-left.
- **validate-frame-size**: The frame-validation operation MUST clamp width
  and height with the clamped-length calculation.
- **validate-frame-push**: The frame-validation operation MUST then push the
  origin inside the visible frame in this order: right edge, left edge, top
  edge, bottom edge; a window wider or taller than the visible frame
  therefore ends flush with the left and bottom edges.
- **hug-per-axis**: The content-hugging frame calculation MUST solve each
  axis independently in top-left user coordinates through the same one-axis
  fit rule, and return the fitted frame with the anchors it used.
- **hug-nearest-edge**: With no anchor supplied, an axis MUST hold its end
  edge when the end gap is strictly smaller than the start gap, and its
  start edge otherwise (ties, including a window filling the axis, keep
  start).
- **hug-held-anchor**: When a pair of anchors is supplied, the
  content-hugging frame calculation MUST use those anchors unchanged
  instead of re-deriving them from the frame, and MUST return them.
- **hug-end-anchor-offset**: Holding the end anchor MUST keep
  `offset + length` fixed before on-screen correction; holding the start
  anchor MUST keep `offset` fixed.
- **hug-push-on-screen**: After anchoring, the axis offset MUST be clamped
  to at most `visibleLength - newLength`, then to at least 0, so a window
  that cannot fit ends flush with the start (left or top) edge.
- **hug-length-clamp**: The new axis length MUST be the clamped-length
  calculation applied to the desired length, the minimum length, and the
  visible length.

### Screen matching

- **match-quality-order**: A match quality MUST order "position only" (1) <
  "name only" (2) < "identifier-and-resolution changed" (3) < "exact" (4).
- **match-uuid-tier**: A screen whose display identifier equals the saved
  non-absent display identifier MUST match as exact when both resolution
  components differ by less than 1 point, and as
  identifier-and-resolution-changed otherwise; that screen MUST NOT be
  considered for a lower tier.
- **match-name-tier**: A screen not matched by identifier whose localized
  name equals the saved non-absent localized name MUST match as name-only,
  even when both identifiers are present and differ.
- **match-position-tier**: A screen not matched by identifier or name MUST
  match as position-only when both the saved and current fingerprints have
  the main-screen flag set.
- **match-best**: The best-match search MUST return the candidate with the
  highest quality, the first such candidate in the screen list's order on a
  tie, and nothing when no screen matches.

### Registration

- **register-spec**: The spec-registration operation MUST store the spec
  under the id, replacing any spec previously registered under it.

### Restore

- **restore-tags-window**: The restore operation MUST set the window's
  identifier to a "wm_"-prefixed form of the id before any other step,
  including when it then fails.
- **restore-no-spec**: With no spec registered for the id, restore MUST log
  a warning, center the window geometrically on the main screen's visible
  area, and return false.
- **restore-min-size**: With a spec, restore MUST set the window's minimum
  size to the spec's minimum size.
- **restore-no-persistence**: When the spec does not persist frames, or no
  state is stored for the id, restore MUST apply the spec's default frame on
  the main screen (first screen if there is no main) and return false.
- **restore-touch-set**: Before looking a placement up, restore MUST ask the
  screen manager to refresh its notion of the current screen set and then
  read the current set id.
- **restore-no-screens**: When the provider reports no screens, restore
  MUST center the window geometrically and return false.
- **restore-known-set**: When a placement exists under the current set id,
  restore MUST apply the resolved frame (see placement-resolution rules) and
  return true.
- **restore-known-set-resave**: When that resolution was not an exact
  screen match, restore MUST immediately save the window's frame so the
  placement records the new screen geometry.
- **restore-unknown-set**: When no placement exists for the current set but
  other placements do, restore MUST apply the relative-fallback frame, save
  the window's frame under the current set, and return true.
- **restore-legacy-migration**: When there are no placements and a legacy
  record exists, restore MUST place the window with the absolute-frame
  calculation from the legacy proportions and size on the best-matching
  screen (main, then first screen when none matches), pass it through the
  frame-validation operation, apply it, save the frame as a per-set
  placement, and return true.
- **restore-fallthrough**: When stored state has neither placements nor a
  legacy record, restore MUST apply the spec's default frame and return
  false.

### Placement resolution

- **resolve-screen-choice**: A saved placement MUST be resolved on the
  screen the screen matcher finds for its fingerprint, falling back to the
  main screen, then the first screen.
- **resolve-exact-replay**: On an exact match the frame MUST be rebuilt from
  the saved top-left X/Y and saved size with the frame-from-top-left-offset
  calculation.
- **resolve-relative**: On any non-exact match or no match, the frame MUST
  be rebuilt from the saved relative X/Y and saved size with the
  frame-from-relative-position calculation and the spec's minimum size.
- **resolve-validate**: Every resolved frame MUST pass through the
  frame-validation operation against the chosen screen's visible area and
  the spec's minimum size.
- **relative-fallback-source**: The relative fallback MUST use the
  placement with the latest saved-at timestamp, placed on the main screen
  (first screen when there is no main), through the frame-from-relative-
  position calculation then the frame-validation operation; it MUST produce
  nothing when there are no placements.

### Save

- **save-guard-spec**: The save operation MUST do nothing when no spec is
  registered for the id or the spec does not persist frames.
- **save-touch-first**: Save MUST ask the screen manager to refresh its
  notion of the current screen set and read the current set id before
  choosing the screen to fingerprint, so a move the platform delivers before
  the screen-change notification is filed under the live set.
- **save-best-screen**: Save MUST fingerprint the screen that contains the
  largest area of the window's frame intersected with each screen's visible
  area; with no intersecting screen it MUST fall back to the window's own
  screen, then the system main screen, both read directly from the platform
  rather than the injected provider.
- **save-no-screen**: When no screen can be chosen, save MUST return
  without writing.
- **save-placement-values**: The placement written MUST carry the chosen
  screen's fingerprint, the window's top-left offset and relative position
  computed against that screen's visible area, the window's current width
  and height, and a saved-at timestamp equal to the screen manager's current
  time.
- **save-preserves-other-sets**: Save MUST rebuild state from the cached (or
  freshly loaded) placements, replace only the current set's entry, and
  keep other sets' entries subject to pruning.
- **save-drops-legacy**: The state written by save MUST have no legacy
  record, so the first save consumes a decoded legacy record.
- **save-prune**: Save MUST keep a placement only when its key is the
  current set id, or its key is one of the screen manager's known set ids,
  or its saved-at timestamp is later than the current time minus the
  maximum set age.
- **save-write-through**: Save MUST update the in-memory cache for the id
  and then write to storage exactly once.

### Cache

- **cache-read-through**: Restore and screen-change handling MUST read an
  id's state from the in-memory cache when present, and otherwise load it
  from storage and cache the result.
- **cache-miss-not-cached**: A load that returns nothing MUST leave the
  cache without an entry for the id, so the next read loads from storage
  again.

### Reset and clear

- **reset-frame**: The reset-frame operation MUST remove the id's stored
  state, clear its cache entry, and apply the spec's default frame, or
  center the window geometrically when no spec is registered.
- **reset-all-frames**: The reset-all-frames operation MUST remove stored
  state for every registered id and empty the whole cache; it MUST NOT
  reposition any window and MUST NOT remove stored state for ids that are
  not registered.
- **clear-saved-state**: The clear-saved-state operation MUST remove the
  id's stored state and cache entry without moving any window.
- **reset-leaves-visibility**: The reset-frame, reset-all-frames, and
  clear-saved-state operations MUST NOT touch persisted visibility.

### Visibility

- **load-visibility**: The load-visibility operation MUST return nothing
  when no spec is registered or the spec does not persist visibility, and
  otherwise the storage's value (nothing when never saved).
- **save-visibility**: The save-visibility operation MUST write the flag
  only when a spec is registered that persists visibility, and otherwise do
  nothing.
- **clear-visibility**: The clear-visibility operation MUST remove the
  stored flag without consulting the spec.
- **visible-window-ids**: The visible-window-ids operation MUST return the
  storage's list of ids whose saved visibility is true.

### Default placement

- **default-position-screen**: Applying a default position MUST use the
  main screen's visible area, falling back to the first screen, and MUST
  center geometrically when there are no screens.
- **geometric-center**: Geometric centering MUST set the window origin to
  `visible.origin + (visible.size - window.size) / 2` on each axis, keeping
  the window's size; with no screen at all it MUST fall back to the
  platform's own default window-centering placement.

### Screen-change handling

- **change-no-screens**: On a screen change with no screens, the handler
  MUST do nothing.
- **change-window-lookup**: The handler MUST snapshot the live windows once
  per event, key them by the id after the "wm_" identifier prefix, and
  consider every registered spec whose window is present, visible or
  hidden.
- **change-known-placement**: For a window with a placement under the
  current set, the handler MUST apply the resolved frame, for every kind of
  screen change.
- **change-new-set-fallback**: For a screen-set change where the window has
  no placement under the current set but has other placements, the handler
  MUST apply the relative-fallback frame and then save the window's frame.
- **change-reclamp**: Every other managed window (no persisted state, frame
  persistence off, or a non-set change with no placement) MUST keep its
  current frame pushed on screen through the frame-validation operation on
  its best screen.
- **change-apply-only-real**: The handler MUST skip re-applying the frame
  when the validated frame equals the window's current frame.
- **change-animate-visible**: The handler MUST animate the frame change only
  when the window is visible.
- **change-resave-by-delegate**: Apart from the new-set fallback, the
  handler MUST NOT save frames itself; re-saving after a reposition relies
  on the window controller's own move/resize callbacks.

### Persistence durability

- **storage-default-backend**: The default storage backend MUST store each
  id's state as JSON under a key of the form `WindowState_<id>` and
  visibility as a boolean under a key of the form `WindowVisible_<id>`,
  both qualified by the window-state namespace, so state survives app
  relaunch.
- **storage-failure-signal**: The window-state storage seam does not report load or save failures: the protocol has no error channel, and the default backend returns nothing for undecodable data (restore then applies the default frame and the next save overwrites the blob) and silently skips a write whose encoding fails, with no log.

