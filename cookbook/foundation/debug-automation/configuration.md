
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Switch key (constructor parameter) | string | none — required at construction | Caller-supplied name shared as both the settings-store key and the launch-argument name, e.g. `"QuietWindowPresentation"` or `"MultipleInstances"`. |
| Launch argument | CLI flag, e.g. `-QuietWindowPresentation YES` | absent | Passed as a launch argument to the process; landed in the settings store's launch-argument-derived layer, which the switch's enabled-state read consults, and which lasts exactly as long as that one process. |
| Settings-store parameter (enabled-state read) | settings store | the standard/default store, via the no-argument read | Injectable so a test can supply an isolated settings store instead of the developer's real preferences. |
| Debug/release build configuration | compiler build configuration | project-configured (debug vs. release) | Gates whether the enabled-state read ever consults the settings store at all; a release build removes the check entirely. |

None of the four units reads a process environment variable or any settings
key of its own beyond the settings-store key described above.

