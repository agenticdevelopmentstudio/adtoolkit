
This bridge raises with hardcoded English string literals; none carries a localization key or a lookup into a string catalog. Every raised message reaches the extension as a thrown error, so an extension author sees the literal English text regardless of locale. The log-only messages (the duplicate-registration warning, the dropped-duplicate-handle warning) reach only the host's own log, never the extension.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `<path>'s first argument must be a view id string.` | Raised by `registerTreeDataProvider` or `createTreeView` when the first argument is missing or not a string. |
| (none — literal only) | `<path>'s second argument must be a TreeViewOptions object.` | Raised by `createTreeView` when the second argument is missing or not an object. |
| (none — literal only) | `<path> requires a TreeDataProvider with getChildren(element) and getTreeItem(element) methods.` | Raised by either member when the provider argument fails **provider-requires-getchildren-and-gettreeitem**. |
| (none — literal only) | `<path> is unavailable: this extension's host has been torn down.` | Raised by either member when the bridge has been disposed. |

