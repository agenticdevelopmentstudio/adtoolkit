
- **Null/empty input**: A record with an empty title gives an empty sidebar title.
- **Boundary values**: Two records equal in every field are the same edit, whatever their title.
- **Concurrent access**: Not applicable — the pane is used from the main thread only.
- **Error states**: A refused save is not seen by the pane; the owner restores the fields (see field-sync).
- **Offline/disconnected state**: Not applicable.
- **Absent callback**: Committing with no save callback set updates the held record and title and reports nothing.

