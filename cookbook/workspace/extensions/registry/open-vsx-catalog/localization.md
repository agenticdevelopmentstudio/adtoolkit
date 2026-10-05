
Not applicable: no user-facing string literal appears anywhere in this
concept. Every string it defines is either a JSON field key read from the
registry's own wire format (`"icon"`, `"sha256"`, `"signature"`,
`"publicKey"`, `"license"`, `"readme"`, `"universal"`, and the
`engines`/`downloads`/`files` keys) or a case name used for programmatic
branching (installable, engine-incompatible, engine-range-unreadable,
platform-specific, no-universal-build) — none of it is text this concept
itself displays.

