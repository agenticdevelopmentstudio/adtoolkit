
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | "Any" | Menu item title and title-summary text shown when `selection` is empty; hardcoded in the menu-building and title-refresh operations, not routed through any localization mechanism. |
| n/a (literal) | "{n} selected" | Title-summary text shown when three or more choices are selected; same caveat as above. |

Not applicable beyond the table above: `label` and each `Choice.title`/
`Choice.detail` are caller-supplied strings, not literals owned by this
file, so there is nothing else here for the component itself to localize.

`"Any"` and `"{n} selected"` are English literals assigned directly, with
no localization key, and the count string has no plural variant.

