
- **signature**: The slug function MUST take one string and return a string synchronously.
- **lowercase-first**: The function MUST lower-case the whole input using locale-independent case mapping before any other step.
- **trim**: After lower-casing, the function MUST trim leading and trailing whitespace.
- **hyphenate-runs**: The function MUST replace every maximal run of one or more characters outside ASCII `a`–`z` and `0`–`9` with a single `-`.
- **ascii-only-alphabet**: The output alphabet MUST be limited to ASCII lower-case letters, ASCII digits and `-`. Any other character, including accented and non-Latin letters, MUST be treated as a separator (`Café` becomes `caf`).
- **trim-hyphens**: The function MUST remove every leading and trailing `-` from the result.
- **no-double-hyphen**: The result MUST NOT contain two consecutive `-` characters, because each separator run collapses to one hyphen (hyphenate-runs).
- **empty-allowed**: The function MUST return `""`, without throwing, when the input contains no ASCII letter or digit (for example `""`, `"   "`, `"---"` or `"日本"`).
- **idempotent**: Applying the function to its own output MUST return the same string.
- **total**: The function MUST NOT throw for any string input.
- **no-uniqueness**: The function MUST NOT guarantee distinct outputs for distinct inputs. `"A B"`, `"a-b"` and `"a_b"` all become `"a-b"`. Uniqueness is the backend's job, through its unique slug indexes.
- **shared-form**: Group slugs defaulted by the config panel view and site slugs derived by the endpoints configuration view MUST both come from this one function, so the two follow the same rules.
- **pure**: The function MUST be free of side effects: no network, storage, logging or global state. Its result depends only on the argument.
- **concurrency**: The function MUST run synchronously to completion, so calls cannot interleave and need no ordering rule.

