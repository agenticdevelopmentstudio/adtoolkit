
This ingredient is the app's cross-cutting data substrate: nine
dependency-light modules that together give every per-domain feature area a
shared tenant-scoped resource cache, persisted last-shown/view-mode state
(FTD: which id a collection last showed, and whether it renders as cards or a
list), a cached workspace-preferences round-trip, and workspace
listing/switching. It builds directly on the shared authenticated request
layer, token/subject reading, and base64url decoding documented separately as
the Auth Client recipe (`depends-on`), and re-exports several of those
operations unchanged rather than re-implementing them. It has no visual
surface of its own: every list, detail pane, and workspace switcher in the
app is a consumer of this contract, not part of it.

