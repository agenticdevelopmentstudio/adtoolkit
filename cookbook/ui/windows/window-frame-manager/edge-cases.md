
- **Null and empty input**: An unregistered id MUST restore to the geometric
  center and return false; save and visibility writes for it MUST be
  no-ops. An empty screen list MUST make restore center the window and
  return false, make the screen-change handler do nothing, and make save
  fall back to the window's own screen or the main screen (read directly
  from the platform), writing nothing if both are absent. An empty or
  unrecognised stored blob MUST decode to empty placements (MUST).
- **No placements left after decode**: Stored state with empty placements
  and no legacy record MUST restore to the spec's default frame and return
  false (MUST).
- **Boundary values**: A window exactly equidistant from both edges MUST
  keep its start anchor; a window filling an axis MUST report relative
  position 0.5 and proportional position 0.5 on that axis; resolutions
  within 1 point of the saved value MUST count as exact (MUST).
- **Minimum larger than the screen**: Every sizing path MUST keep the
  minimum size and overhang; the content-hugging frame calculation leaves
  the window flush top-left while the frame-validation operation leaves it
  flush left and bottom, because of their different push orders (MUST,
  documented quirk).
- **Out-of-range stored fractions**: The saved relative X/Y are not clamped
  on restore; a hand-edited value outside 0...1 is placed off the travel
  range and then pulled on screen by the frame-validation operation (MUST,
  as implemented).
- **Stale absolute offset**: A placement matched non-exactly (resolution
  change, name-only or main-only match) MUST NOT replay the absolute
  offset; it MUST use the relative position (MUST).
- **Screen not matched at all**: A placement whose fingerprint matches no
  current screen MUST resolve on the main screen, then the first screen,
  via its relative position (MUST).
- **Display change delivered after a move**: A window-move notification
  that arrives before the platform's screen-parameters-changed notification
  MUST be filed under the live set because save refreshes the current
  screen set first (MUST;
  `testMoveDuringUndeliveredScreenChangeDoesNotClobberTheDockedPlacement`).
- **Placements of aged-out sets**: A placement whose set is unknown to the
  screen manager and older than the maximum set age MUST be dropped at the
  next save of that window; one saved more recently MUST survive (MUST).
- **Duplicate registration**: Registering the same id twice MUST keep only
  the latest spec (MUST).
- **Hidden windows on screen change**: Loaded but hidden managed windows
  MUST be repositioned without animation (MUST).
- **Windows not tagged**: Windows whose identifier lacks the `wm_` prefix,
  or whose id has no registered spec, MUST be ignored by the screen-change
  handler (MUST).
- **Concurrent access**: All operations are serialized on the single
  designated thread, so no two calls interleave. Screen-change
  repositioning triggers save calls, made from the window controller's own
  move/resize callbacks, synchronously within the same turn on that thread
  (MUST).
- **Cross-process writers**: A second process writing the same id's state
  is outside the contract; the cache would not see its writes (per
  sole-writer-precondition).
- **Error states**: Storage load and save failures are not reported by the
  protocol (see the open question on storage-failure-signal). A missing
  spec on restore is logged at warning level.
- **Offline or disconnected state**: Not applicable; the component performs
  no network I/O.
- **Cancellation and timeouts**: Not applicable; every operation is
  synchronous and has no timeout or cancellation path.

