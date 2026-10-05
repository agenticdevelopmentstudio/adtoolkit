
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| registry used by the window matcher | a heuristic registry | the registry's shared instance | Heuristic lookup used for fingerprinting and live-pattern extraction |
| re-matching `threshold` | integer | `autoAssignThreshold` (80) | Minimum score for a pair to be matched |
| `autoAssignThreshold` | integer (constant) | 80 | Default auto-assign threshold |
| `minSubstringPatternLength` | integer (constant) | 2 | Minimum stored-pattern length for a 60-point containment match |
| registry's initial heuristics | list of title heuristics, optional | nil (the five built-ins) | Initial heuristics |
| registry's custom rules | list of custom heuristic rules | none registered | User rules layered over the initial heuristics |
| rule store's root directory | a directory location | required | Directory holding `heuristics.json` (the toolkit's manager passes its state store's root) |
| `CustomHeuristicRule.matchMode` | match mode | substring | How `titlePattern` is interpreted |
| `CustomHeuristicRule.autoAssign` | boolean | false | Auto-assign flag, read by the context manager (see rule-auto-assign) |
| `CustomHeuristicRule.targetContextName` | optional string | nil | Auto-assign target context name (see rule-auto-assign) |
| `CustomHeuristicRule.name` | string | `"<appName> - <titlePattern>"` | Display name |

No environment variables or settings keys are read.

