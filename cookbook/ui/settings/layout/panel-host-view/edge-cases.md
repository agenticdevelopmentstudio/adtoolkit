
- **Null/empty input**: The set-content operation, given no view, MUST
  empty the content container rather than error (**clears-content-on-nil**).
  The set-help operation, given no content, MUST be forwarded to the
  presenter exactly like any other value (**set-help-forwards-to-presenter**);
  the source performs no special-casing between "no content" and populated
  help content beyond passing the value through.
- **Boundary values**: Not applicable in the numeric-input sense — the
  only fixed numeric value in source is the 12pt button-inset constant,
  which is not client-supplied and has no minimum/maximum to test.
- **Concurrent access**: Not applicable — the component is confined to
  the UI thread; construction or mutation of it from off that thread is
  rejected, so there is no concurrent-access surface to define behavior
  for.
- **Error states (dependency/network failure)**: Not applicable — the
  source performs no I/O, network call, or fallible operation; every
  method is a synchronous view/property update with no failure path.
- **Offline/disconnected state**: Not applicable — the source performs no
  networking of any kind.
- **Rapid, repeated set-content calls**: Each call independently tears
  down and rebuilds the content container's children
  (**replaces-content-on-set**); the source contains no debouncing or
  in-flight guard, so N calls in quick succession perform N full teardown
  cycles.
- **Help presenter reassigned to a different, non-empty instance while the
  previous presenter is still retained elsewhere**: The source's
  reassignment logic only ever touches the newly assigned presenter — it
  never clears the previously assigned presenter's own visibility-change
  notification. If a caller keeps a reference to the old presenter and it
  later fires its visibility-change notification on its own, this
  component's callback still runs and repaints the help button as if that
  stale presenter were still current. This is what the source's
  reassignment logic does, not an intentional safeguard.
- **The show-help-button setting toggled while help is currently
  visible**: Setting it off hides the button (**help-button-visibility**)
  but does not itself close help — the presenter's own help-visible value
  and any window drawer/popover the presenter owns are unaffected; only
  this component's own button disappears.
- **Anchor left stale when the button hides**: Per
  **help-anchor-untouched-when-button-hidden**, the component does not
  clear the assigned help presenter's anchor view when the show-help-button
  setting turns off — the presenter is left pointing at a now-hidden view.
  What a presenter does with a hidden anchor (for example guarding before
  presenting) is that presenter's own contract, not this component's.

