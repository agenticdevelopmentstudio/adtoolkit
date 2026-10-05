
This module gives the status board the same peer base-URL rules the backend enforces. It exports two pure operations:

- the normalize operation returns the canonical stored form `scheme://host[:port][/path]` — lower-cased scheme and host, default port dropped, no trailing slash, no query or fragment — and never throws.
- the validity-check operation reports whether the backend will accept the string: an absolute `http:` or `https:` URL.

Its doc comment calls it "a deliberate mirror" of the backend's own rules: the board cannot import the backend's code because it has its own build, and the backend stays the authority, normalizing and validating every write whatever the UI sends. The mirror only moves feedback earlier. The peer editor runs its dirty check against the value the server will keep, and shows a typo as a sentence under the field instead of a 400 response. See
[Status Server Peers](adtoolkit://cookbook/status/service/peers) for the
authoritative backend contract.

