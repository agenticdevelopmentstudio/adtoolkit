
Subsystem: the host application's bundle identifier (see Platform Notes
for the exact mechanism used on Apple platforms) | Category: `IDEDetector`
(the IDE-marker detector is the only one of the two components that logs
at all).

| Event | Level | Message |
|-------|-------|---------|
| Detection scan completes | info | `IDE detection complete: <count> IDE(s) found in <root's last path component>` |
| Each detected IDE, per scan | debug | `  Detected <type display name>: <path>` |
| The open operation begins | info | `Opening <project type display name> project at <target path>` |
| The specific-application open fails | error | `Failed to open <project type display name>: <error's full description>` |

The language-detection component contains no logging call of any kind.

