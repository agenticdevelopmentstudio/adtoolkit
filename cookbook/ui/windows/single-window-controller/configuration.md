
| Option | Type | Effect | Source |
|---|---|---|---|
| Window ID | Text | Construction-time identity used for registry lookup and frame/visibility persistence keying | constructing the controller |
| Content | Content controller | Construction-time, fixed content of the window | constructing the controller |
| Title (override) | Text | Window's title bar text | computed property |
| Default content rect (override) | Rectangle | Fallback frame when nothing is persisted | computed property |
| Style options (override) | Style-option set | Chrome and, via the utility/HUD options, whether a utility-style window is built | computed property |
| Minimum size (override) | Size | Window's minimum content size | computed property |
| Configuration hook (override) | Callback | One-time additional setup after full assembly | overridable method |
| Content-size provider | Optional callback | Enables content-hugging refit after moves | settable property |
| Forces-front flag (class override) | Boolean | Whether showing the window additionally forces it fully to front regardless of quiet presentation | class-level property |
| HUD-configuration operation | (Boolean, Number) | Opts the window into translucent/floating HUD chrome | method call |

