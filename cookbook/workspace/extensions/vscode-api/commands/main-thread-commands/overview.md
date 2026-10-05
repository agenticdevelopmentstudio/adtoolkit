
This adaptor is the extension host's `vscode.commands` namespace:
`registerCommand`, `executeCommand` and `getCommands`. All three terminate
in the app's own command registry — the same table the app's menus and
command palette dispatch through — rather than in a second,
extension-private command table. The adaptor MUST run confined to a
single, serialized execution context (matching the command registry and
the extension host, since the callback values it holds are not safe to
share across concurrent contexts, and every member below is invoked on
the thread that made the call, which for this host is always that
confined context), and is meant as **one instance per extension**,
mirroring the extension host itself: nothing in the type enforces that,
but every ownership rule below — most importantly the duplicate-
registration check — is answerable only if it holds, because it is what
makes "an id *this adaptor* already owns" a question this type can see.
The ownership record maps an id to its registered callback and the
registration token that names that specific registration — never a
second dispatch table; dispatch always goes through the shared registry.
Tearing the adaptor down walks that record to unregister everything this
adaptor is responsible for. There is deliberately no automatic net for
that teardown: nothing calls it today because nothing instantiates the
extension host in production yet, so the requirement to call it lives
only in documentation until a coordinator task wires it in.

