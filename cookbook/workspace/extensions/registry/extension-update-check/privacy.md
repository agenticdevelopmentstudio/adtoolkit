
- **Data collected**: None persisted by this component. Per lookup,
  checking a single installed extension reads the fields the caller's
  installed-extension record already holds in memory — publisher, name, and
  version — and does not read or retain anything beyond those.
- **Storage**: Not applicable — this concept and the registry client it
  uses are documented as stateless and hold no cache; nothing is written to
  disk by this component.
- **Transmission**: Each single-extension check discloses the installed
  extension's publisher (as the registry namespace) and name to whichever
  registry the client addresses — the public registry unless a caller
  configured a different base — by placing them in the request path. The
  installed version string is read locally for comparison but is never sent
  to the registry; only namespace and name appear in the outgoing request.
- **Retention**: Not applicable — no data from this component is retained
  beyond the single check call; the registry client itself caches nothing
  between calls.

