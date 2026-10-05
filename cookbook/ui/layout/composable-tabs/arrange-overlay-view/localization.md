
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | "Add" | Add button title |
| n/a (literal) | "Remove" | Remove button title |
| n/a (literal) | "Move" | Move menu's own fixed title item |
| n/a (literal) | "Done" | Done button title |

Not applicable beyond the table above: the pane-name text shown by
`paneName` is supplied by the caller (an already-resolved display name from
elsewhere in the app), not a literal string this file owns.

The "Add", "Remove", and "Done" button titles and the "Move" menu title are
plain literals, none routed through a localization function, so none
reaches a string catalog.

