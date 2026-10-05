
The storage-location helper contains no user-facing string of its own; the fallback token (`"AgenticToolkit"`) is a hardcoded, unlocalized identifier, and the display-name reader returns the platform's own resolution of the declared display name, which is the localized value when the app localizes that value. Consumers interpolate the display name into sentences the user reads.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Declared display name (platform bundle metadata) | the app's declared name, or `AgenticToolkit` when absent | Returned by the display-name reader; also the input to the token-deriving operation and therefore to the storage directory name. |

