
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — (inline literal, no lookup key) | "API Key" | A provider template's resolved config type fallback when `configType` is absent and `secretRequired == true`; shown in the provider picker's Config Type column. |
| — (inline literal, no lookup key) | "Local" | A provider template's resolved config type fallback when `configType` is absent and `secretRequired == false`. |

Both strings are hardcoded English literals with no localization-lookup mechanism (a string catalog, a localized-string table) anywhere in this concept. Every other user-facing string on a descriptor (`displayName`, `label`, `placeholder`, `providerDescription`, `llmDescription`, etc.) is plugin-authored data passed through unchanged, not a string this concept itself defines.

