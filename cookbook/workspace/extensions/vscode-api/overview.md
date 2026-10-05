
The bridge is the shared ceremony every `vscode.*` namespace adaptor in the
extension host needs, written once. The commands adaptor is the first of
five adaptors this concept names — the other four are workspace, window,
languages, and language models — and each of them installs its members
through the same seam, answers a torn-down host the same way, invokes
extension callbacks the same way, and settles the same promises. The bridge
is a stateless collection of operations: it holds no state of its own, and
every operation derives entirely from the arguments it is given and from
whichever script call is currently active. Every operation MUST run
confined to a single, serialized execution context, since the values this
bridge passes between the host and an extension's script are not safe to
share across concurrent contexts, and the script engine always invokes a
callback on the thread that made the call — for this host, always that one
confined context.

Three groups of primitives make up this concept. The first — installing a
member with a teardown response, reading the current call's arguments,
reading an array-like value's length, raising a script exception, and the
promise builders (a resolved promise, a rejected promise, a settled
promise) — are the small pieces an adaptor member reaches for directly. The
second — calling back into an extension's own callback or thenable,
observing a thenable's rejection, and reading a thenable's settlement,
built over a script trampoline evaluated once per script context and
cached under a fixed global name — let this host call back into an
extension's own callback or thenable without an uncaught extension
exception ever reaching the host's own exception handling. The third —
building a ready-made disposable, and building a throw-on-unimplemented-
member stub sub-namespace over a second trampoline cached under its own
fixed global name — give an adaptor both without writing its own proxy
object. Three small concurrency-safety wrapper values exist only to carry
values already confined to one execution context across shared-library
signatures that require concurrency safety regardless.

