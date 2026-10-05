
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| panels | array of panels | `[]` | Full, ordered panel list backing the sidebar. |
| searchQuery | string | `""` | Narrows the visible rows to panels whose harvested text matches every space-separated term; empty shows every panel. |
| onSelectPanel | callback taking an optional panel | none | Invoked with the panel behind the row the user selects, or no panel when cleared; wired to the ancestor's own selection callback only through the component's normal construction path. |

