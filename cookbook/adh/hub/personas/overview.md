
The Personas domain has two given implementations of one contract. On Apple, a navigation data
source drives a list-of-personas root level, a fixed 13-item facet rail per persona, and one form
per facet, backed by a persona data source contract the app repo implements over its own API
client. On the web, a family of hand-written clients covers a much larger surface: persona CRUD
and services, the demo-chat eligibility predicate and preview endpoint, the chat-status
word/glyph resolver, owner-level tool/may-act/approval grants, per-user tool consent, and the
special-interests research-corpus clients. Both sides agree that a persona is edited
facet-by-facet but sent as one whole payload on every update, and that everything past the core
CRUD + services surface — abilities, may-act, chat status, demo chat, special interests — is
either not yet wired into the Apple facet rail (only 5 of the 13 declared facets are currently
supported) or has no Apple client at all in the given sources.

