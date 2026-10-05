
This component draws the file tree itself: one collapsible header row per
root directory (a root manager), and the files and folders under each one,
in a tree outline rather than a flat list. It is hosted inside the file
browser (see
[File Browser](adtoolkit://cookbook/workspace/files/file-browser-view)),
which owns the footer strip and the per-root managers; this component owns
only the tree surface: lazy per-directory loading, expand/collapse and
selection state kept in sync with injected shared state (a selection model,
a restoration model, a directories model), a "reveal the file the editor is
showing" operation, a live unsaved-changes indicator sourced from an
open-document registry, and a right-click context menu for opening,
revealing, and copying a path.

