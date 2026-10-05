
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| legacy | directory path | none, required | The directory to move from. |
| current | directory path | none, required | The directory to move to. |
| markers | list of file names | empty | Files whose presence at the top of `current` proves it holds real data. |
| fileManager | file-system handle | the default | The file system used for existence checks, listing and creating the parent; injectable for tests. |

The migration reads no environment variable or settings key of its own.

