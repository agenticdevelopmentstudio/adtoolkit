
The display-name lookup, the icon-key lookup, and the `"VS Code"` literal
in the marker-matching step are hardcoded English-only string literals
returned directly from fixed mappings, with no localization-API call and no
localized-strings-table entry in either component. These strings are
user-facing per the IDE-type value's own documentation ("Provides display
names ... for UI presentation").

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — no string-key mechanism) | `"Xcode"` / `"Xcode Workspace"` / `"Swift Package"` / `"VS Code"` / `"IntelliJ IDEA"` / `"Android Studio"` | The display-name lookup: label for a detected project marker |
| (none — no string-key mechanism) | `"VS Code"` | Hardcoded display-name literal assigned directly in the marker-matching step's `.vscode` branch |

