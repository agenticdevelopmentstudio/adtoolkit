
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `Active MCP Servers` (translatable string) | Active MCP Servers | Popover heading |
| `No connected servers.\nAdd one in Settings → MCP Servers.` (translatable string) | No connected servers.\nAdd one in Settings → MCP Servers. | Popover empty-state message |
| — (not localized) | No MCP servers | Computed button label |
| — (not localized) | MCP: none | Computed button label |
| — (not localized) | MCP: {active} of {total} | Computed button label |
| — (not localized) | Unknown | Fallback row label when a server id is missing from the name lookup |

The button's label and the row's fallback label are computed as plain,
unlocalized strings rather than translation keys, and render verbatim with
no string-table lookup, even though their possible values ("No MCP
servers", "MCP: none", "MCP: {n} of {m}", "Unknown") are authored as
English literals. None of these four strings goes through localization in
source.

