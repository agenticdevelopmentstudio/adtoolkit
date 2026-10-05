
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` (repository record construction) | unique identifier | freshly generated | The row's stable identity; a caller reconstructing a known repository passes its existing `id` instead. |
| `path` (repository record construction) | string | none — required | The working tree's absolute path, per the doc comment; not validated as absolute (see `git-repo-path-absoluteness`). |
| `name` (repository record construction) | string | none — required | Display name; conventionally seeded from the path's final segment (see `git-repo-name-seeding-convention`). |
| `remote` (repository record construction) | string, optional | no value | `origin`'s URL as another component read it from `.git/config`; no value means no remote. |
| `firstSeen` (repository record construction) | timestamp | current time at construction | When this row was first added to the registry. |
| `lastSeen` (repository record construction) | timestamp | current time at construction | When a scan most recently confirmed this repository still exists. |
| `lastOpened` (repository record construction) | timestamp, optional | no value | When a project window was last opened for it; never set by this component. |
| `path` (scanned repository construction) | string | none — required | The path a directory walk found. |
| `remote` (scanned repository construction) | string, optional | none — required (no default; a no-value must be passed explicitly) | `origin`'s URL read from the found repository's `.git/config`, or no value. |
| (scan summary construction) | — | all five counts `0` | Takes no parameters; a caller mutates the counts afterward. |

Nothing in this component reads an environment variable, a settings key,
or any injected dependency; the only "configuration" is the arguments
passed to each constructor.

