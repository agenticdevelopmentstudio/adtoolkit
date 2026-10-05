
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | "Select a file to view its contents" | Placeholder shown when nothing openable is selected |
| (none — hardcoded literal) | "Cannot open this file" | Placeholder shown when the selected file could not be read |

Both placeholder strings are passed as plain, unlocalized literal text rather than through a localization key or lookup mechanism, so each renders verbatim with no bundle lookup (see Platform Notes for the mechanism this affects). Neither string is routed through any localization API or strings catalog.

