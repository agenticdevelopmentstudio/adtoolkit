
**Decision**: On Apple platforms, lean on QuickLook (`QLPreviewView`) rather than a stack of per-file-type views.
**Rationale**: Per the source's own doc comment, this "is what keeps 'show it if we can' from becoming a format list this repo has to maintain," and reuses "the same renderer the user already knows from the Finder."
**Approved**: pending

**Decision**: On Apple platforms, an unsupported file format's "no preview available" message is left entirely to `QLPreviewView`, with no fallback view or message coded in this file.
**Rationale**: Per the source's own doc comment, "a type QuickLook has no generator for draws its own 'no preview available' — that is the honest answer, and it costs nothing."
**Approved**: pending

**Decision**: On Apple platforms, `updateNSView` guards reassignment of `previewItem` behind an equality check rather than always reassigning it.
**Rationale**: Per the source's own comment, "reassigning the same item restarts the generator and flickers, so only a genuine change is pushed through."
**Approved**: pending

**Decision**: On Apple platforms, `dismantleNSView` explicitly calls `view.close()` rather than relying on ARC/`deinit` to release the view.
**Rationale**: Per the source's own comment, "QuickLook holds a generator process alive per view; closing releases it rather than waiting for the view to be collected."
**Approved**: pending

**Decision**: On Apple platforms, the failable `QLPreviewView(frame:style:)` initializer is used with a fallback to `QLPreviewView()` rather than force-unwrapping it.
**Rationale**: Per the source's own comment, "the failable initializer is the only one that takes a style; it returns nil only when QuickLook is unavailable, and the plain initializer is the same view at the default style" — a genuine but rare fallback is handled rather than risking a crash.
**Approved**: pending

