
| Event | Level | Message | Category |
|-------|-------|---------|----------|
| File loaded successfully | info | `Loaded file: <name>` | editor state |
| File could not be read | error | `Cannot read <name>` | file-preview classifier |

An autosave write failure is logged at error level (`Auto-save failed for <uri>: <reason> — still pending, will retry`) by the injected autosave scheduler, not by this component directly; it is included here because this component is what triggers every autosave this log line can report.

