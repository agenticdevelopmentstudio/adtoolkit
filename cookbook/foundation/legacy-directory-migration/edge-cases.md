
- **Null / empty input**: An empty marker list disables placeholder detection, so two existing directories always report both exist.
- **Boundary values**: Only a marker at the new directory's top level counts; a nested copy does not. After 100 taken aside names the migration throws, and nothing has moved.
- **Concurrent access**: The placeholder check and the move are separate steps. A writer that creates a marker in between would be moved aside with the placeholder, so the caller runs the migration before anything opens the directory. Removal of an empty placeholder fails instead of deleting anything that appeared.
- **Error states**: A cross-volume move, an existing destination, or a file system without exclusive-rename support throws, and nothing is moved. A failure after the aside rename restores the placeholder, or throws an error carrying its aside location.
- **Offline / disconnected state**: Not applicable: The migration has no network access.
- **Cancellation**: Not applicable: The migration is a single synchronous call with no cancellation point.

