
- **placeholder-registration**: Constructing the registry MUST register the
  `placeholder` view id, mapped to a factory that builds the placeholder
  pane, before any caller can register or query anything else.
- **register-overwrite**: Registering a view id MUST replace any descriptor
  and factory already registered for that view id.
- **placeholder-protection**: Unregistering MUST NOT remove the entry for
  the `placeholder` view id, MUST return false when called with it, and
  MUST log an error.
- **unregister-removal**: Unregistering MUST remove the entry and return
  true for any registered view id other than `placeholder`.
- **unregister-absence**: Unregistering MUST return false for a view id
  that has no registered entry.
- **view-id-ordering**: Listing registered view ids MUST return every
  registered view id, sorted ascending by its raw string value.
- **registration-presence**: Checking whether a view id is registered MUST
  return true only for a view id that has a registered entry.
- **descriptor-default**: Resolving a view id's descriptor MUST return the
  `unknown` descriptor for a view id with no registered entry, and MUST
  return the registered descriptor otherwise.
- **factory-dispatch**: Building content for a view id MUST invoke the
  factory registered for that view id, passing it a context built from the
  call's parameters and that entry's descriptor.
- **unregistered-fallback**: Building content for a view id with no
  registered entry MUST return a placeholder pane carrying the call's pane
  number, and MUST log an error, rather than throwing or trapping.
- **tree-id-default**: Building content MUST set the context's tree id to
  the call's node id when no tree id is given.
- **context-passthrough**: Building content MUST pass the node id, project,
  working directory, pane number, and owner node id through to the context
  exactly as given.
- **state-store-owner**: Constructing a state store from a context MUST
  build it with the context's project, node id, and the given prefix, and
  MUST set the store's owner node id to the context's owner node id.
- **explicit-holding-priority**: Resolving a pane's holding priority MUST
  return the descriptor's explicit holding-priority value when one is set,
  regardless of the preferred-thickness-fraction.
- **fractioned-priority-boost**: When no explicit holding-priority value is
  set and a preferred-thickness-fraction is set, resolving MUST return a
  priority value 10 points above the platform's default-low
  resize-priority level.
- **default-low-priority**: When neither an explicit holding-priority value
  nor a preferred-thickness-fraction is set, resolving MUST return the
  platform's default-low resize-priority level.
- **optional-teardown**: Pane content MAY adopt an optional teardown
  capability to be told, the moment its pane is discarded, that it is time
  to release live resources; content that does not adopt it MUST NOT be
  assumed to need teardown.
- **optional-removal-confirmation**: Pane content MAY adopt an optional
  removal-confirmation capability to supply a message describing what
  would be lost if its pane were closed; content that returns nothing, or
  does not adopt the capability, MUST be treated as having nothing to lose.
- **placeholder-pane-number**: The placeholder pane MUST display the
  literal text "Pane N", where N is the 1-based pane number it was
  constructed with.
- **placeholder-series-tint**: The placeholder pane MUST tint its
  container's background using the active theme's chart-series color list,
  indexed by (pane number − 1) modulo the list's count, at 15% opacity,
  whenever that list is non-empty.
- **empty-series-no-tint**: The placeholder pane MUST NOT set a background
  tint when the active theme's chart-series color list is empty.
- **placeholder-retint**: The placeholder pane MUST re-evaluate its tint
  every time the active theme changes.
- **stale-tint-persistence**: When **placeholder-retint**'s re-evaluation
  finds the newly active theme's chart-series color list empty, the
  placeholder pane MUST leave its container's existing background tint
  unchanged rather than clearing it — the guard makes no assignment on
  that path, so a tint set under a prior, non-empty theme persists after
  the switch.
- **placeholder-title-centering**: The placeholder pane MUST center its
  title label both horizontally and vertically within its container.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

