
- **Null/empty input**: The theme store is a non-optional, defaulted
  construction parameter; there is no null case to handle. If the store's
  themes were empty, the theme-choice view model's choices would be empty
  and the composed choice control would construct with zero items and no
  selection (its own documented empty-choices behavior, per
  `adtoolkit://cookbook/ui/settings/rows/popup-menu-choice-view`) —
  this component adds no additional guard of its own around that case.
- **Boundary values**: Not applicable — the component owns no numeric or
  length-bounded input of its own.
- **Concurrent access**: Not applicable — the component is confined to
  construction and mutation from a single, serialized execution context
  (see Platform Notes).
- **Error states**: Not applicable — every operation (constructing the
  stack, pinning edges, constructing the subscription) is a synchronous,
  non-throwing call; no error-producing path appears.
- **Offline/disconnected**: Not applicable — the component performs no
  networking of its own; it only reads from and writes to in-process
  settings state and in-process notifications.
- **Observer torn down with the view**: The palette-observing subscription's
  two notification subscriptions each capture the component weakly inside
  their callbacks, and the component is the sole strong owner of the
  subscription. When the component is released, its subscription is
  released with it, and no further preview refreshes occur for that
  instance — an inherent consequence of that ownership shape rather than an
  explicit teardown call.
- **Selection-to-preview lag spans one processing turn**: Selecting an item
  writes synchronously to the active-theme setting, but every downstream
  observer of that setting — including the persisted store's own internal
  observer, which reloads the theme manager on an external change — fires
  asynchronously, hopped to the next main-queue turn. The theme manager
  then posts its change notification synchronously within that later
  turn, which is what finally triggers the preview refresh. This is
  current, source-traceable behavior across the component and its
  supporting settings/theme-manager machinery together: the preview is
  never more than one processing turn behind a selection, and the
  component performs no additional debouncing of its own on top of that.
- **Reload no-ops when the theme id round-trips to the same theme**: The
  theme manager's reload guards against reprocessing an unchanged theme
  before rebuilding the palette or posting the notification, so selecting
  the item that is already active produces no preview re-render and no
  second notification — current, source-traceable behavior that this
  recipe's **resyncs-preview-on-theme-change** requirement depends on.

