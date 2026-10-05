
- **Empty or whitespace-only input**: The function MUST return `""`. In the config panel view this means a group whose name and slug are both blank is sent with `slug: ""`. Whether the backend accepts that is up to the status server, not this logic.
- **Input with no ASCII alphanumerics** (`"日本"`, `"🚀"`, `"!!!"`): The function MUST return `""`. Non-Latin names produce no slug.
- **Accented Latin letters** (`"Ünïcode"`): Each accented letter MUST be treated as a separator, so `"Ünïcode"` becomes `"n-code"`. The function does no transliteration or Unicode normalization.
- **Case mappings that change length**: Lower-casing happens before filtering, so a character whose lower-case form includes ASCII letters keeps them. The Kelvin sign U+212A lower-cases to ASCII `k`, and `İ` lower-cases to `i` plus a combining dot, which then acts as a separator (`İx` becomes `i-x`). The function MUST produce whatever locale-independent lower-casing followed by the ASCII filter gives (see Platform Notes for the exact API and a platform where this differs).
- **Distinct names that collapse together**: Two group names such as `"Ops Team"` and `"ops-team"` MUST produce the same slug (no-uniqueness). The backend's unique slug index decides which write wins. The board surfaces the backend's error, and this logic adds no suffix or retry.
- **Typed group slug**: the config panel view sends a non-blank typed slug trimmed but not passed through the slug function. The shared form applies only to the default. This belongs to the caller, not to this logic.
- **Very long input**: No length cap is applied. The output is never longer than the input.
- **Concurrent access**: Not applicable. The function is synchronous and pure, so calls cannot interleave.
- **Error states and offline**: Not applicable. This logic does no I/O, so no dependency can fail and connectivity does not matter.

