
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `"Search"` | Search | Placeholder text for the sidebar's search field, stored as the field's platform placeholder text — a literal string, not routed through any localization lookup in this component. |

The `"Search"` placeholder is not localized: this component passes it as a
hardcoded literal to the search field, never routing it through a
localization lookup, both of which are used elsewhere in the surrounding
codebase (outside this component).

