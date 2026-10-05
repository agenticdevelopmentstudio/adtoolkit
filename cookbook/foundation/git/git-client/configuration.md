
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| executable path | string (file path) | `/usr/bin/git` | Path to the git binary the client spawns. |
| timeout | number (seconds) | `5` | Wall-clock budget for one invocation. |
| submodule handling | enumeration (ignore / include) | ignore | When set to ignore, the status verb appends `--ignore-submodules`. |
| extra environment | key-value map of strings | empty | Merged over the `GIT_TERMINAL_PROMPT=0` default in the spawned child's environment; lets a caller (a test, in particular) redirect something like `GIT_CONFIG_GLOBAL` without mutating process-wide state. |
| caller attribution | captured at the call site | captured automatically | Identifies the calling file and function that invoked a verb, with no effort required from the caller. |
| git executable path setting | string | `"/usr/bin/git"` | Read when deriving configuration from settings, into the executable path. |
| git status timeout setting | integer (seconds) | `5` | Read when deriving configuration from settings, into the timeout, clamped to a minimum of `1`. |
| git status includes submodules setting | boolean | `false` | Read when deriving configuration from settings; `true` maps to include, `false` to ignore. |

