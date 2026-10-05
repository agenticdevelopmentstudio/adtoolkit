
### Identity & construction

- **state-store-injection**: The pane MUST accept a state store at construction and MUST default to an ephemeral (in-memory) state store when none is supplied.

### Host relationship (requests, not actions)

- **host-weak-reference**: The pane MUST hold its reference to its host weakly, so the host is not kept alive on the pane's account.
- **close-is-a-request**: Clicking the close control MUST ask the host to close the pane and MUST NOT remove the pane or change any pane state itself.
- **zoom-is-a-request**: Clicking the zoom control MUST ask the host to zoom the pane and MUST NOT change the pane's zoomed state itself.
- **minimize-picker-uses-host-edges**: Clicking the minimize control MUST present a picker offering exactly the edges the host currently reports as available, with every other edge disabled.
- **minimize-pick-is-a-request**: Choosing an edge from the picker MUST ask the host to minimize the pane to that edge and MUST NOT change the pane's minimize edge itself.
- **restore-is-a-request**: Clicking restore, from the title bar or from the minimized rail, MUST ask the host to restore the pane and MUST NOT change the pane's minimize edge itself.
- **host-change-refreshes-controls**: Setting the host to a new value MUST immediately re-derive whether the minimize and close controls are available from the new host, without waiting for another trigger.
- **close-availability-defaults-true**: The close control MUST be treated as available when there is no host, or when the host does not override its close-permission check.
- **minimize-availability-empty-without-host**: The minimize control MUST be disabled when there is no host.

### Loading and layout

- **title-bar-above-content**: The pane's view MUST place the title bar above the content container, both inset from the container by the content inset (default `0`) on every side.
- **content-child-hierarchy**: When the content-building hook returns content, that content MUST be added as a child and its view MUST be pinned to the four edges of the content container.
- **no-content-is-supported**: When the content-building hook returns nothing, the pane MUST load a working, empty pane rather than failing.
- **accessibility-id-on-container**: The pane's container view MUST carry the accessibility identifier its accessibility-identifier hook returns (default `"pane"`).
- **clamped-pane-yields-width**: Enabling the clamping option MUST yield the title bar's width demand to the container exactly once, and disabling it MUST have no effect.
- **clamp-covers-later-installed-chrome**: Chrome installed into the title bar after clamping — the gear button, at minimum — MUST also have its width demand yielded when the pane is clamped.
- **clamp-is-one-way**: Disabling the clamping option after it was enabled MUST NOT restore the title bar's original compression resistance.

### Title

- **title-follows-content**: The pane's resolved title MUST equal the content's own title (when the content implements the title-providing capability), falling back to the fallback title when the content does not implement it.
- **title-change-callback-installed**: The pane MUST install its own callback into the content's title-change notification (when implemented) once, during the pane's initial setup, so the title bar updates without polling.
- **title-refresh-updates-three-readers**: Refreshing the title MUST update the title bar's title, the open options dialog's heading (when one is presented), and MUST invoke the pane's own title-change notification.
- **fallback-title-default**: The fallback title MUST be `"Pane"` when not overridden.

### Accessories and gear

- **accessories-from-content**: Refreshing accessories MUST set the title bar's accessory views to the content's own accessory views (when the content implements the accessory-providing capability), or an empty array when it does not.
- **gear-installed-trailing**: The pane MUST install a gear button in the title bar's trailing slot while its view is being built.
- **gear-menu-order**: The gear's menu MUST list the pane's own menu items first, followed by a separator only when that list is non-empty, followed by a `"Settings…"` item.
- **bare-pane-menu-is-settings-only**: A pane whose menu items are empty MUST raise a menu containing exactly one item, `"Settings…"`, with no leading separator.
- **menu-items-self-validate**: The options menu MUST have each item's enabled state decided by the item itself, rather than by a platform default validation pass.
- **settings-opens-options-dialog**: Choosing `"Settings…"` MUST present an options dialog as a sheet, seeded with the pane's option rows and headed by its resolved title.
- **options-rows-order**: The pane's option rows MUST return its own spacing control and reset button first, followed by the content's own option rows (when the content implements the options-providing capability).
- **options-dialog-close-flushes-spacing**: Dismissing the options dialog MUST flush any pending spacing-override write immediately, before the dialog closes.

### Spacing

- **spacing-defaults-to-inherited**: A pane with no stored spacing override MUST apply its inherited spacing. When the content implements the content-spacing-consuming capability, that value MUST be exactly the content's own inherited spacing (whatever the content itself reports, zero or not). When the content does not implement it, the inherited spacing MUST be all-zero, unconditionally.
- **spacing-consumer-applies-its-own-gap**: When the content implements the content-spacing-consuming capability, the pane MUST apply the resolved spacing to it directly and MUST hold its own content-spacing insets at zero.
- **spacing-non-consumer-gets-pane-applied-gap**: When the content does not implement the content-spacing-consuming capability, the pane MUST hold the content off the content container's edges by the resolved spacing's four insets itself.
- **spacing-control-range**: The pane's spacing control MUST offer the range `0...40` on every edge.
- **spacing-clamped-on-read**: A stored spacing value outside `0...40` on any edge (written by an older build, or edited by hand) MUST be clamped back into range when read from the state store, never rejected outright.
- **spacing-decode-failure-is-absent**: A spacing-override record that fails to decode MUST be treated the same as no stored override, not as an error.
- **spacing-reset-restores-inheritance**: Activating the spacing reset button MUST delete the pane's stored override rather than writing the current inherited value, and MUST leave the reset button disabled immediately afterward.
- **spacing-reset-enabled-only-when-overridden**: The spacing reset button MUST be enabled exactly when the pane currently has a stored override.
- **apply-resolved-spacing-is-idempotent**: Reapplying resolved spacing more than once with nothing changed MUST leave the resolved spacing, the spacing control's displayed value, and the content-spacing insets unchanged.

### Minimize / restore appearance

- **minimize-vertical-hides-content-only**: Minimizing to the top or bottom edge MUST hide the content container and the content's view while leaving the title bar visible, showing its minimized (restore) control state.
- **minimize-horizontal-replaces-with-rail**: Minimizing to the leading or trailing edge MUST hide the title bar and content, and MUST show a minimized rail docked to that edge.
- **rail-glyph-from-content**: The minimized rail's icon and tooltip MUST come from the content's own minimized-representation values (when the content implements that capability), falling back to the generic default icon and the pane's resolved title respectively.
- **rail-rebuilt-on-edge-change**: Flipping directly from one minimized horizontal edge to the other MUST remove the existing rail and build a new one docked to the new edge, rather than repositioning the existing view.
- **restore-clears-minimized-chrome**: Restoring MUST unhide the title bar and content, remove any rail, and reactivate the content's four edge constraints.
- **minimized-content-pins-deactivated**: While minimized to any edge, the four constraints pinning the content's view to the content container MUST be deactivated, not merely left active on a hidden view.
- **minimize-before-load-is-lossless**: Requesting a minimize edge before the pane's view has loaded MUST record the edge and MUST NOT force the view to load; the recorded edge MUST be applied exactly once when the view does load.
- **appearance-methods-noop-before-load**: Applying minimized appearance MUST NOT take effect, and MUST NOT force the view to load, while the view is not loaded.
- **title-bar-trailing-active-except-rail**: The title bar MUST span the container's full width for every pane shape except a pane minimized to a horizontal (leading/trailing) edge, where its trailing edge MUST be released so it can collapse to its own width instead of being stretched to match the (now much narrower) rail.

### Persistence

- **minimize-edge-persisted**: Setting a minimize edge MUST write the edge's value to the state store under the minimize-edge key, or delete that key when cleared.
- **zoom-persisted**: Setting zoomed state MUST write `"1"` to the state store under the zoomed key when `true`, or delete that key when `false`.
- **state-restored-on-load**: Loading the view MUST restore the minimize edge and zoomed state from the state store.
- **unparseable-stored-edge-ignored**: A stored minimize-edge value that does not match a recognized edge MUST be treated as absent — the pane opens whole — rather than crashing or raising an error.

### Search and selection

- **search-reaches-searchable-content-only**: The pane's searchable state MUST be `true` exactly when the content implements the search capability; searching MUST forward to the content when searchable and MUST be a no-op otherwise.
- **selection-description-reported**: The pane's selection description MUST equal the content's own selection description (when the content implements the selection-describing capability), or be unset when it does not.
- **selection-change-forwarded**: The pane MUST install its own callback into the content's selection-change notification (when implemented) and MUST invoke its own selection-change callback whenever that fires.

### Sizing for the host

- **minimized-thickness-formula**: The minimized thickness for an edge MUST equal the minimized rail's thickness plus twice the content inset for a horizontal edge, and the title bar's height plus twice the content inset for a vertical edge.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

