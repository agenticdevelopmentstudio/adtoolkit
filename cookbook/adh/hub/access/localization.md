
Listing feature areas is the one place this module authors its own English string, rather
than relaying one from the backend:

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| — | `GET /access/features returned a malformed feature list` | Thrown when the response fails `feature-row-shape-validated`'s runtime shape check |

There is no localization mechanism in this module (no catalog, no key, no i18n call) — the
string above is a hardcoded literal, stated as fact per the non-UI component guidance rather
than as a gap. Every other error message a caller can observe from this client originates in
the backend's response body and is extracted by the shared authentication client, not
authored here.

