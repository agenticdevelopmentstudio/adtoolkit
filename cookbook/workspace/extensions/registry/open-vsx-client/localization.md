
Not applicable: the source declares no user-facing string literal.
`OpenVSXError`'s cases carry structured data — a `URL`, an HTTP status code,
a field name and value — rather than display text, and no method returns or
logs a message meant to be read by a person (traced to the `OpenVSXError`
enum, and to the absence of any display-text literal in
`search`, `detail`, `data`, or `text`).

