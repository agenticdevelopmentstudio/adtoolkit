
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `parent` | tree item (optional) | unset (roots) | Supplied by the caller to reading children; names the item whose children are requested, or asks for the roots when unset. |
| `item` | tree item | required | Supplied by the caller to `activate(_:)`, `didExpand(_:)`, and `didCollapse(_:)`; names the row the caller is reporting on. |
| `items` | list of tree items | required | Supplied by the caller to `selectionDidChange(to:)`; the full current selection. |
| `isVisible` | boolean | required | Supplied by the caller to `visibilityDidChange(to:)`; whether the pane hosting the tree is currently on screen. |
| `onDidChangeTreeData` | callback | unset | Assigned by whoever currently owns the instance's callbacks; invoked by the conformer with a changed element's `id`, or unset for the whole tree. |
| `onDidChangeChrome` | callback | unset | Assigned by whoever currently owns the instance's callbacks; invoked by the conformer when `title`, `message`, or `allowsMultipleSelection` changes. |
| `onProviderReplaced` | callback | unset | Assigned by whoever currently owns the instance's callbacks; invoked once, with the replacement instance, before this instance is invalidated. |

