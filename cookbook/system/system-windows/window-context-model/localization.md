
The display name for each match-strategy value returns hardcoded English literals with no string-catalog lookup; it is placed beside the model so any host rendering a strategy picker reads the label from the model.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `Exact` | The display name for `appAndTitleExact`, a strategy-picker label |
| (none; literal) | `Substring` | The display name for `appAndTitleSubstring` |
| (none; literal) | `Regex` | The display name for `appAndTitleRegex` |
| (none; literal) | `App Only` | The display name for `appOnly` |

The example context names ("iOS App", "Backend API", "Docs") used to illustrate the type are documentation, not strings the code emits.

