
- The outline view carries the accessibility identifier `file-browser.tree`
  (`tree-carries-accessibility-id`).
- Each row's icon carries an explicit accessibility description of "Folder"
  or "File", chosen by `node.isDirectory`. Because a package's `isDirectory`
  is also `true`, a package's icon is described as "Folder" even though a
  package behaves like an openable file (`open-opens-files-and-packages`),
  not like a directory a user discloses — a naming quirk of reusing
  `isDirectory` for the description text, not a functional defect.
- The unsaved-changes marker carries the accessibility description "Unsaved
  changes" and the accessibility identifier
  `whippet.filebrowser.dirty-indicator`. That identifier's prefix
  (`whippet.filebrowser`) does not match the tree's own identifier prefix
  (`file-browser.tree`) — a naming inconsistency present in the reference
  implementation, carried here as-is rather than normalized.
- The outline MUST support standard tree-outline keyboard navigation and
  type-ahead selection (`keyboard-and-typeahead-inherited`); no key-handling
  code is added or overridden in this component, so whatever the platform
  provides by default for a tree-outline control with a data source and
  delegate applies unmodified (see Platform Notes).
- Reduce Motion, Increase Contrast, Differentiate Without Color: see
  **Accessibility Options** below.
- Minimum tap target: Not applicable. This is a pointer-driven desktop
  control, not a touch surface; the 44×44pt guidance for touch targets does
  not apply. The actual row height is 22pt.
- The git-status badge is a plain label carrying only the raw status
  character (`M`, `A`, `D`, `R`, `C`, `?`, `U`, `!`) as its text; unlike the
  row's icon and unsaved-changes marker, it has no accessibility label or
  description of its own, so a screen reader announces the bare character or
  punctuation mark rather than a descriptive word such as "Modified".

