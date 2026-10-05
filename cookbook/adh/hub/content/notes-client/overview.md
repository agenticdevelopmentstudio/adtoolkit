
`notesApi` (`packages/web/packages/data/src/notes/notes.ts`, re-exported
whole by `notes/index.ts`) is a **logic** component — no visual surface. Per
the module's own header comment, a note IS a markdown document: same row
shape, same version history, same relational category/tags as every other
research document `markdownApi` serves. What makes a document a note is a
`content.notes` storage-bucket MARKER — filed by sending `note: true` on
create and read back by filtering `list` with the same flag. `notesApi`
exists only to bake that marker in so a caller cannot forget it: "this
client is `markdownApi` with the marker baked in — `noted` on the way out,
`note: true` on the way in — and nothing else." It is one of three lenses
over the shared markdown-document surface, alongside `docsApi`
(`hub-domain-docs`, the `content.docs` marker) and the plain research-paper
use of `markdownApi` itself (`hub-domain-markdown`); this recipe describes
only the marker lens `notes.ts` adds, not the underlying client's own
behavior, which the sibling `hub-domain-markdown` recipe already covers.
`notesApi` contains no HTTP call, no wire-shape knowledge, and no taxonomy
logic of its own — every operation forwards directly to `markdownApi` or
re-exports `taxonomyApi` unchanged.

The module comment also records a deliberately unused alternative: a
`/content/notes` backend surface exists, but it is "the device-SYNC marker
surface — content only, no title/category/tags, no workspace — and it has
no web consumer," and this client is documented as never calling it.

