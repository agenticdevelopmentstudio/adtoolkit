
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | text | none (required) | The AppleScript source text the script-running operation compiles and executes. |
| `key` | text | none (required) | The application element key declared in the host app's scripting definition (e.g. `panes`, `projectTabs`, `projectWindows`, `terminalSessions`), passed to the element-locator helper. |
| `uniqueID` | a closure returning text, called on the serialized main execution context | none (required) | Closure the element-locator helper calls, on that context, to obtain the addressed element's unique id string. |
| command-handler override | a subclass override returning an open result value, isolated to the serialized main execution context | returns an absent value | The subclass hook a caller overrides on the command base to implement one scriptable command; the base class's own implementation is the default when unoverridden. |

