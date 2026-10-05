
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none - hardcoded literal, no localization lookup) | `Close` | The close button's icon's accessibility label. |

All other visible text - agent name, model name, session name, working
directory, branch, and summary - is opaque data supplied by the data
source, not UI copy authored by this component; localizing that content, if
ever needed, is the data source's responsibility, not this component's.

The `Close` description has no localization lookup, so the screen reader
reads it in English only, regardless of the user's locale. See Platform
Notes for why this string in particular is not itself a localization key on
the source platform.

