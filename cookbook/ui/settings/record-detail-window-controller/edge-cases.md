
- **Null/empty input**: An empty record list is valid and selects nothing unless fixed rows exist.
- **Boundary values**: Deleting the last row selects the new last row.
- **Concurrent access**: Not applicable — the window is used from the main thread only.
- **Error states**: A failed change is reported through the replaceable failure report as a sheet on the window.
- **Offline/disconnected state**: Not applicable.
- **Unknown id**: Selecting an id no longer listed is ignored, so a caller can re-select after a save without checking.
- **Unshown window**: Selecting before the window is ever shown still updates the selection and remove control.

