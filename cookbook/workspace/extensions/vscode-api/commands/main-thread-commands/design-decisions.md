
**Decision**: the caller flag is shared across every adaptor instance rather than held per instance, even though it exists only to answer a question about one dispatch.
**Rationale**: the bit belongs to the dispatch, not to the adaptor instance running it. When extension A's `executeCommand` awaits a command extension B registered, B's callback runs on a path that genuinely has a caller, and B's own adaptor instance is not the one that knows it — a per-instance flag would read `false` there and log B's rejection as noise. A second reason points the same way: the dispatch a registered command runs through captures no reference to the adaptor instance, which keeps the adaptor out of the registry's retain graph; reaching an instance flag from the invoke operation would reintroduce exactly that captured edge, or read a value that is unavailable after teardown and answer wrongly.
**Approved**: pending

**Decision**: `registerCommand` raises a synchronous exception on failure, while `executeCommand` and `getCommands` reject a returned promise on the equivalent failure.
**Rationale**: the choice follows each member's own return shape. `registerCommand` returns a disposable, not a thenable, so there is nothing for a failure to reject; answering `undefined` instead of raising would let an extension push nothing useful onto its own subscription list while believing it had registered a command. `executeCommand` and `getCommands` return a thenable, and a VS Code extension writes `await vscode.commands.executeCommand(...)` inside a `try` — a synchronous throw from underneath that `await` would reach a `catch` other than the one the extension wrote, so both reject instead.
**Approved**: pending

**Decision**: (Swift implementation) the invoke operation returns private callback-failure and dispatch-unavailable wrapper values through the shared command's `([Any]) -> Any?` signature, rather than converting a callback's failure into a rejection or thrown error at the point of dispatch.
**Rationale**: that dispatch signature is shared with every non-extension command in the app, and giving it any awareness that a scripting engine or promises exist would leak this adaptor's concerns into a type the registry, the menu system, and the command palette all depend on. The two wrapper values are private to this file, and only the execute-command handler — the one member with a promise to settle — ever unwraps them.
**Approved**: pending

**Decision**: a duplicate registration is refused only when the *same* adaptor instance already owns the id; a duplicate the app or a different extension's adaptor owns falls through unchanged to the shared registry's own replace-and-warn (or built-in-refusal) behavior.
**Rationale**: whether one extension may register an id twice is a question the ownership record can answer outright — it is this adaptor's own bookkeeping. Whether an extension may shadow an id the app or a *different* extension already owns is a trust decision that belongs with the extension registry and the permissions work the class documentation explicitly defers to, not with a per-instance ownership check that has no visibility into who else registered what.
**Approved**: pending

**Decision**: the disposable returned when registering a command captures its registration token at registration time, and unregistering re-checks that captured token against the live entry in the ownership record before touching the shared registry at all.
**Rationale**: the captured token, not the disposed flag the underlying disposable-building operation already tracks, is what protects against a stale-but-unfired disposable. A disposable minted before a dispose-and-re-register cycle is still "unfired" as far as that operation is concerned, so without the token check its late dispose call would unregister the adaptor's own *fresh* registration of the same id, made after the earlier teardown — and, one level further, unregistering also confirms the token still matches what the shared registry itself has filed, so a registration that a different registrant has since displaced is never removed by someone else's stale token either.
**Approved**: pending

