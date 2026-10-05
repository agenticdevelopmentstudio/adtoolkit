
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| database (construction parameter) | a database reference | none — required | The store the repository list is loaded from and that scan-finishing/renaming/opening a project write to. |
| scanner (construction parameter) | a scanner reference (optional) | absent | Injected scanner for a test or a caller wanting a particular walk; when absent, scanning builds its own scanner from the current setting on every call. |
| window-opening delegate (construction parameter) | a project-opening reference (optional) | absent | Weakly held window-opening delegate; also settable afterward. |
| command registry (construction parameter, required) | a command-registry reference | none — required, no default | Where the open-project/scan-for-projects commands are registered at construction time (see **command-registry-required**). |
| scan-skip-patterns setting | a persisted list-of-strings setting | the scanner's own default root-skip patterns | Read fresh at the start of every scan call that has no injected scanner, so an edited skip list takes effect on the next scan without relaunching. |
| show-progress (scan parameter) | a boolean | `true` | Whether scanning presents a scan-progress window for the duration of the walk. |

