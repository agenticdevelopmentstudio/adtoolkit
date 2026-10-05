
The scan summary's summary text builds a hardcoded English sentence with
no localization key or lookup mechanism of any kind. Every fragment below
is a literal, not a lookup:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none — literal in source | `"<n> project"` / `"<n> projects"` | Headline noun, singular when `found == 1`. |
| none — literal in source | `", no changes"` | Appended to the headline when no part is selected. |
| none — literal in source | `" — "` | Separator between the headline and the joined parts. |
| none — literal in source | `"<n> new"` | Appended when `added > 0`. |
| none — literal in source | `"<n> moved"` | Appended when `moved > 0`. |
| none — literal in source | `"<n> removed"` | Appended when `removed > 0`. |
| none — literal in source | `"<n> not scanned"` | Appended when `skipped > 0` — note the field is named `skipped` but the displayed word is "not scanned". |
| none — literal in source | `", "` | Joiner between multiple selected parts. |

