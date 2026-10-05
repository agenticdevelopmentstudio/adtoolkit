
**Decision**: `children(of:)` answers an empty array for every failure a provider can produce — a thrown error, a rejected thenable, a non-array answer, and a call against a disposed registration — rather than distinguishing any of them to the caller.
**Rationale**: the caller draws an empty branch either way and has no display surface for the difference; the source's own doc comment states that surfacing a thrown error as a row "would put an extension's stack trace in a user's sidebar." The distinction is recorded by whichever conformer's own logging captures it (out of this recipe's scope), not by this protocol.
**Approved**: pending

**Decision**: `onDidChangeTreeData`'s argument is the changed element's `id` — a handle — rather than a freshly rebuilt `ContributedTreeItem`, and an id the caller has never resolved to a drawn row is treated the same as `nil`.
**Rationale**: the id is all a caller needs to locate the corresponding row and ask for its children again; building an item here would force a round trip for a row the caller may have already scrolled away from. Over-refreshing on an unresolvable id costs one extra `children(of:)` call; under-refreshing would leave a tree that silently stops matching the extension's own state.
**Approved**: pending

**Decision**: `onProviderReplaced` travels forward, from the outgoing instance to the caller, rather than through either of the two existing outward callbacks.
**Rationale**: a caller resolves its data source exactly once, when its view loads, and nothing ever re-offers one; an extension re-registering a provider for a view id it already owns is ordinary (every deactivate/activate cycle does it, and reloading the host does it for every view at once). Without a forward-traveling event, an already-open caller would go on holding an instance that, once invalidated, answers no children by design, forever.
**Approved**: pending

