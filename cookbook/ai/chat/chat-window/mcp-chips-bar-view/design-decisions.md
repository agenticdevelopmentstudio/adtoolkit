
**Decision**: Read `activeServerIds.wrappedValue` once at construction into
the view model's own `@Published activeServerIds`, rather than observing
the binding for later external changes.
**Rationale**: In the Swift/AppKit implementation, traceable to
`MCPChipsBarViewModel.init`, which assigns `self.activeServerIds =
activeServerIds.wrappedValue` with no Combine subscription on the binding's
source; only `toggle(_:)` ever updates the binding afterward (one-way, out). This keeps the model's published state
the single source of truth for rendering after init, at the cost of the
bar not reflecting an external change to the active set made through some
other UI while this bar is visible. Until this decision is approved,
**snapshots-active-ids-at-init** and the "Stale active ids outlive their
server" edge case describe the current, accepted behavior — not
necessarily the final design.
**Approved**: pending

**Decision**: Ship the bar fully functional but retained, unwired to any chat
consumer.
**Rationale**: Per the type's doc comment, "Not wired to any chat consumer in
Phase 1 — the MCP tool loop lives in `MCPChatToolSource`. This bar is
retained for Phase 2 when a consumer surfaces the registry selection UI
again." The component computes and reports active-server state correctly,
but no other file currently reads `activeServerIds` or observes changes
written through the binding.
**Approved**: pending

**Decision**: Apply `.themedRoot()` twice — once to `MCPChipsBar`'s root, and
again to `MCPServerPicker` inside the `.popover` content — instead of
once for the whole component.
**Rationale**: In the Swift/AppKit implementation, per the inline source
comment, "A popover is its own window, so it is outside this view's
environment and needs the palette injected again." Reapplying it is a
workaround for a limitation in how this app's custom `\.theme` environment
value propagates into `NSPopover`-backed content, not a change in visual
intent between the bar and the picker.
**Approved**: pending

