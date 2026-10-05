
Not applicable: none of the seven given sources define a URL scheme, route,
or deep-link handler. The Apple side navigates purely through in-memory
`HTDVItem`/`RailPath` values, not URLs. The web side's `token`/`code` values
are ordinary function parameters supplied by whatever page component owns
the actual `/join`-style route and its query parameters — that route is not
among these given sources.

