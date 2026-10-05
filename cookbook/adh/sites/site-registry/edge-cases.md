
- **Null and empty input**: Building the workspace link for an empty slug returns
  nothing rather than minting `//` (workspace-href-single-shape). Parsing a
  workspace slug for an empty path resolves the path to `/`, whose first segment is
  empty, and therefore returns nothing. The cross-site URL builder, for a site
  identifier not present in the roster, returns the given path unmodified rather
  than throwing.
- **Boundary values**: A site with no testing deploy and no staging deploy
  (a production-only site) resolves to its bare `prodHost` from every non-local
  environment (environment host resolution's two-level fallback ends on the bare
  host, never on nothing). A site definition with neither a workspace route nor a
  home route is a valid, fully supported shape (an operations console such as
  `admin`, `status`, or `bitbag`) — the absence of both is not itself an
  inconsistency to flag.
- **Concurrent access**: This registry is synchronous and stateless — every value is
  computed once when the registry loads and every operation is a pure function over
  that data, with no shared mutable state written at runtime — so there is no
  interleaving for two callers reading the site roster, the merged route map, or the
  merged guided-tour graph at once to race against.
- **Error states — a shared hub feature segment with no clear owner**: The reverse
  feature-segment lookup's tie-break (site-for-hub-segment-tiebreak) resolves
  deterministically by "does the site's own identifier equal the segment," but a
  future segment shared by two sites where NEITHER site's identifier equals the
  segment resolves silently to whichever site's feature-segment entry was declared
  first in source order; this is documented as an intentional, documented convention
  rather than an oversight.
- **Error states — a route share whose generator has not run yet in this checkout**:
  A region's generated route share can legitimately be empty in a checkout whose own
  region generator has not run yet — a dedicated check's own fill-expectation table
  names `main` as the one region currently expected to be empty, and any other
  region going empty without an entry in that table is what the "has every share
  filled in" check exists to catch.
- **Error states — the additive OAuth allowlist widening unintentionally**: Flipping
  a staging-deploy or testing-deploy flag to `true` on a site claimed but not yet
  actually deployed on that tier allowlists a redirect target for a host nothing is
  serving; the OAuth return-origin allowlist's own documentation names the
  historical precedent (the `messaging` site, 2026-08-22) where a flag flip that
  looked like a listing change permanently widened two environments' allowlists, and
  states that a caller wanting to narrow the allowlist back down must run a
  separate, deliberate pruning tool against the database column this allowlist's
  output feeds — this registry itself performs no pruning.
- **Offline or disconnected state**: Not applicable — every part of this component
  performs only synchronous, local computation over in-memory constants; none of it
  makes a network request.

