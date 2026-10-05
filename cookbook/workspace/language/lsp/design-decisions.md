
**Decision**: A diagnostics publish with a missing or stale `version` is
never dropped by the diagnostics store — the store always keeps the most
recently published diagnostics for a URI regardless of version.
**Rationale**: Many language servers omit `version` on published
diagnostics or publish out of band with the document's own edit stream;
treating an unversioned or older-versioned publish as untrustworthy would
mean silently losing diagnostics for those servers rather than showing
something. Overwriting on send order, not version order, keeps the store
simple and matches what LSP servers actually send in practice.
**Approved**: pending

**Decision**: Forwarding in the document-sync pipeline gates change and
close events on the tracked open-URI set, but deliberately does not gate
save events the same way.
**Rationale**: The source's own comment asks that this asymmetry not be
"fixed" — a save event for a document the pipeline does not believe is
open is forwarded anyway, because some server integrations rely on
receiving `didSave` even across an open-tracking edge case that would
otherwise suppress it; unifying the gating would silently drop those saves.
**Approved**: pending

**Decision**: A user configuration for a language id replaces the built-in
configuration for that id wholesale when computing the effective
configuration set, rather than merging fields (e.g. keeping the built-in's
root markers while taking the user's command).
**Rationale**: Partial merging would require a field-by-field precedence
rule that has no natural default (should a user's arguments merge with or
replace the built-in's?); replacing wholesale is unambiguous and matches
the mental model of "I am supplying my own server for this language,"
consistent with how this codebase's MCP server configuration makes the
same choice.
**Approved**: pending

**Decision**: Stopping a session preserves a failed state rather than
overwriting it with stopped, and skips the graceful-shutdown budget
entirely when the server has already died on its own.
**Rationale**: Once a server has died, there is nothing left to negotiate a
graceful shutdown/exit with, so waiting out that budget would only delay
stopping for no benefit; and reporting stopped over a genuine failed state
would hide from callers (and from the session-state observers) that the
process died unexpectedly rather than being asked to stop.
**Approved**: pending

