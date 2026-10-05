
This recipe is the headless, non-visual logic shared by two sibling features: an
API-exploration browser and a generic data-table (CRUD) editor. Neither feature
exports a single component named after this recipe; this is the umbrella
specification for their pure logic and headless state units — the parts with no
visual rendering — so that the request-building, endpoint-lookup,
schema-derivation, slugging, snippet-generation, and generic-CRUD contracts are
documented once instead of being re-derived by every UI recipe that consumes
them (the CRUD table, the CRUD record form, and any API browser or
endpoint-reference consumer).

The API-exploration logic builds and executes same-origin backend-for-frontend
(BFF) requests from generated endpoint metadata, derives cycle-safe
schema-driven examples and field descriptions, highlights code with a
dual-theme, lazily-cached syntax highlighter, projects endpoints to crawlable,
collision-checked URL slugs, generates request snippets (a command-line form
and a scripting form) with a deliberate non-live token placeholder, and maps
HTTP method/status to a fixed presentation "tone." A server-usable entry point
re-exports the non-interactive pieces; a separate client-facing entry point
deliberately excludes the large generated endpoint metadata so importing a
button component never pulls it into the initial bundle.

The CRUD logic derives per-column editability from a fixed precedence, tracks
staged, dirty, mergeable row edits, gates table visibility by a
presentation-only authorization tier, exposes the generated CRUD schema
allowlist, defines the shared CRUD metadata shapes, runs list/create/
update/remove against the same BFF layer through a headless state unit with an
out-of-order-response guard, bridges an imperative unsaved-changes guard into a
stable proxy object, and exposes the current viewer's admin capability and
readiness.

