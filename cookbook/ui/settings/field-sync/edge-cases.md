
- **Null/empty input**: An empty stored value is an ordinary value; a refresh
  of an idle field holding text replaces it with the empty string.
- **Boundary values**: A pop-up item whose represented value is not text never
  matches, so selecting any text value leaves such an item unselected.
- **Concurrent access**: Not applicable — all operations run on the main thread
  with the controls they act on.
- **Error states**: The component has no error path; a refused save is the
  caller's concern and the forced revert is how it restores the field.
- **Offline/disconnected state**: Not applicable.
- **Multi-line force**: A forced revert of a multi-line view does not end an
  edit session explicitly; it replaces the text directly (see Design Decisions).

