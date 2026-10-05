
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directories` | directories state | required (no default) | The primary root plus any additional roots this browser shows. |
| `excludedURL` | location | required | A directory excluded from both the tree and the watcher (e.g. a hosting document's own package). |
| `config` | tree display configuration | default configuration | Opaque-package extensions/display names and the persisted-settings key for custom file-type mappings. |
| `ignorePatterns` | list of patterns | empty | Wildcard filename patterns left out of the tree. |
| `selection` | selection state | a new, private instance | The shared selection state; supply one to let a host read or drive it. |
| `restoration` | restoration state | a new, private instance | Persisted expanded/selected state; supply one to restore or persist it. |
| `documentStore` | document store | required | App-wide open-document registry, threaded to the tree for its dirty indicator. |
| `gitStatusProvider` | git status provider (optional) | none | A provider to reuse for whichever root it belongs to; none lets each root build its own. |
| `rootURL` (single-root convenience form) | location | n/a | Shorthand that builds the directories state with that location as the sole primary root and no additional roots. |

