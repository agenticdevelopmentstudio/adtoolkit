
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | "Filter" | Filter field placeholder text |

"Filter" is assigned to the filter field's placeholder as a plain string
literal, not through a localization lookup, so it never reaches a string
catalog; there is no localization key or catalog entry for the placeholder.

Not applicable beyond the table above: row labels come from each entry's
file system name, not from a localized string table, so there is nothing
else in this file for the component itself to localize.

