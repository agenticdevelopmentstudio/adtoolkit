
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| storage key | string (fixed) | `"extensions.disabledIdentifiers"` | The literal name the setting is declared with; pinned per **disabled-identifiers-key**, never derived at runtime. |
| default value | set of strings (fixed) | `[]` | The literal default the setting is declared with; returned whenever no value has been stored or a stored value cannot be decoded. |
| secure-storage flag | boolean (fixed) | `false` | Routes storage to the non-secure storage path rather than a secure, credential-store-backed one. |
| settings store | the store the setting reads and writes through | a default store backed by non-secure local storage and a secure, credential-store-backed provider | The host app may substitute a different store instance before the setting is first accessed. |

No environment variable is read by this declaration — it is a plain setting declaration with no parameters of its own; the table above lists the fixed values baked into that declaration and the one injected dependency (the settings store) it relies on.

