
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `primary` | `URL` | required (no default) | `FileBrowserDirectories`' always-shown root; resolved via `resolvingSymlinksInPath()`. |
| `additional` | `[URL]` | `[]` | `FileBrowserDirectories`' extra roots the user has added, normalized on construction. |
| `FileBrowserDirectories.onChange` | `(([URL]) -> Void)?` | `nil` | Closure a host supplies to persist `additional` whenever `add`/`remove` change it. |
| `expandedPaths` | `[String]` | `[]` | `FileBrowserRestorationState`'s initial set of disclosed directory paths. |
| `selectedPath` | `String?` | `nil` | `FileBrowserRestorationState`'s initial selected file path. |
| `FileBrowserRestorationState.onChange` | `((_ expandedPaths: [String], _ selectedPath: String?) -> Void)?` | `nil` | Closure a host supplies to persist expanded/selected state whenever either changes. |
| `repoRootURL` | `URL` | required (no default) | `FileTreeManager`'s root directory to scan and watch. |
| `packageURL` | `URL` | required (no default) | Path excluded from filesystem watching alongside `.git` (e.g. a build output directory). |
| `config` | `FileTreeConfig` | required (no default) | Package-extension/display-name/persisted-preference-key configuration passed through to the scan. |
| `ignorePatterns` | `[String]` | `[]` | Wildcard filename patterns excluded from the scan; also settable later via `updateIgnorePatterns(_:)`. |
| `gitStatusProvider` | `GitStatusProvider?` | `nil` | Injected provider to share across managers/panes of the same checkout; a manager scoped to `repoRootURL` is built when omitted. |

