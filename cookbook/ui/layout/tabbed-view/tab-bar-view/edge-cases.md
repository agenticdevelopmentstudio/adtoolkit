
- Null/empty input (MUST): Setting the bar's items to an empty list with no
  selection MUST leave the bar with no arranged subviews, and recomputing
  thickness MUST fall back to the bar's preferred thickness floor since no
  hosted content remains (see tab-bar-view-025). Renaming a tab using an id
  absent from the items MUST be a silent no-op (see tab-bar-view-017).
- Boundary values (MUST): A single-item bar MUST compute a stack depth of
  `0` for that item whether or not it is selected; the vertical-bar
  reordering pass still runs with only one view to raise, producing no
  visible reordering.
- Concurrent access: Not applicable — the bar and its constituent parts are
  all confined to a single thread (see Platform Notes), so this concept
  provides no path for two threads to mutate one instance at the same time.
- Error states: Not applicable — this concept makes no network, database,
  or file-system call. Its only fallible lookups resolve to silent no-ops
  or default values rather than throwing or trapping.
- Offline/disconnected: Not applicable — this component performs no
  networking of any kind.
- Unset host content (MUST): When no host content is set, a
  content-hosting item's parenting step is skipped entirely, so the hosted
  content never receives a parent — but its view is still wrapped in the
  hosted-item wrapper and added to the stack regardless, so the tab still
  renders and is still clickable; only parent-based lifecycle callbacks are
  missing.
- Renaming a content-hosting tab (documented quirk, not a deliberate design
  choice): Renaming an item performs no check on the existing item's
  payload type. Renaming an id whose current item hosts content overwrites
  that entry with a title item in the item list, while no button was ever
  created for a content-hosting item, so updating that (nonexistent)
  button's title is a no-op — the model now disagrees with what is rendered
  until the next rebuild. This concept's own documentation states this is
  safe only because the caller (the tabbed view's rename operation) already
  refuses to call it for a content-hosting item, so there is nothing left
  to guard against here; the invariant is enforced entirely by the caller,
  not by this component itself. This is recorded as technical debt rather
  than a supported code path.
- Title tabs on a vertical bar are not depth-reordered (documented quirk,
  not a deliberate design choice): a title tab on a left/right bar receives
  the same `-16pt` overlapping spacing as a hosted content item (see
  **item-spacing-by-orientation**), but
  **vertical-edge-cards-overlap-and-order-by-distance**'s front-to-back
  reordering only ever touches hosted content items — a title tab's
  z-order (and so which overlapping title tab draws and hit-tests on top)
  is whatever order it was originally added in, regardless of selection.
  Nothing suggests this was a deliberate choice for the title-tab case
  rather than an oversight; it is recorded here, per source fidelity,
  rather than smoothed over.

