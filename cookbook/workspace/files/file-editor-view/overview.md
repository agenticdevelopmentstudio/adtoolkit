
The component is the content pane of a file browser: given the file tree's
currently selected node, it shows that file's contents — an editable,
syntax-highlighted source editor for text, a system-provided preview for
everything else (images, PDFs, movies, oversized or non-UTF-8 files) — or a
placeholder when nothing openable is selected. It owns a private editor
state, created once at construction, which does all of the actual work:
reading the file, classifying it, keeping up to 8 recently-viewed documents
live in a bounded, undo-preserving cache, wiring each to autosave and to
this project's language services, and deciding what display state the view
renders. This recipe covers the file editor view, its editor state, the
file-preview classifier, and the file-private placeholder/content/
cached-editor-stack elements declared alongside them — together, one
component, since none of them is meaningful in isolation. The system
document preview and the hosted source editor are out of scope: this recipe
documents how and when they are shown, not their own internal rendering or
accessibility. Colors and font come from the app theme in the environment,
so the editor follows a theme switch like the rest of the UI.

