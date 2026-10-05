
The provider's own two error descriptions — `"no configured language model with id '<id>'"` and `"the plugin '<identifier>' is not available"` — are hardcoded English string literals with no localization key or catalog entry. Both strings are produced by the error's own textual description, which a caller (ultimately the extension-host seam that turns a thrown error into an extension-visible error) would surface. Each descriptor's name uses a fixed `"·"` separator glyph around two data-derived strings (the user's own configuration name and a model identifier), not translatable prose.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `no configured language model with id '<id>'` | The unknown-model error's description, surfaced when a descriptor's id no longer resolves. |
| (none — literal only) | `the plugin '<identifier>' is not available` | The plugin-unavailable error's description, surfaced when the resolved plugin cannot be reached. |

