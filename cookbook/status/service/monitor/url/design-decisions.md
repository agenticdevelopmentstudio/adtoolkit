
- **Decision**: catch a `URL` parse failure and return the original string rather than
  `null` or letting the exception propagate.
  **Rationale**: not stated in source; recorded here as a fact of the code, per this
  recipe's authoring rules, not a defended choice. The effect is that a caller — for example
  `sync.ts`'s `hostOf(ep.url)` call composing a monitor-retirement reason — always receives a
  usable string even for a URL that fails to parse, at the cost of being unable to
  distinguish a successfully extracted value from a raw fallback.
  **Approved**: pending
- **Decision**: gate `projectPageUrl`'s collapse on an exact hostname match,
  `u.hostname === "vercel.com"`, rather than a suffix or subdomain match.
  **Rationale**: stated in the function's own doc comment — "Vercel inspector URLs are
  `…/<team>/<project>/<deployId>`; drop the deploy id. Other platforms / unrecognised URLs
  pass through unchanged." The comment frames this as intentionally narrow: only the one
  known dashboard-URL shape is rewritten; anything else, including a Vercel-hosted customer
  domain, is left untouched.
  **Approved**: pending
- **Decision**: reconstruct the collapsed URL from only `u.origin` plus the first two path
  segments, discarding every further path segment together with the query string and
  fragment.
  **Rationale**: the doc comment states the intent ("so clicking a project name always lands
  on the same place, regardless of which specific deploy the row is about") and names only
  the deploy id as dropped; the code's actual origin-plus-two-segments construction also
  drops any segment past the second one and any `?query`/`#fragment`, which the comment does
  not call out explicitly — recorded here as an observed behavior beyond what the comment
  states, per this recipe's source-fidelity rules.
  **Approved**: pending

