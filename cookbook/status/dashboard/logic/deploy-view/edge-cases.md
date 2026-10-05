
- **Empty input list**: the platform-summary operation MUST return an empty list, the endpoint-deploys operation MUST return an empty list, the latest-terminal-for-endpoint operation MUST return no result, and the failures-for-endpoint operation MUST return 0.
- **Endpoint with no platform or no project**: the deploy-target-key operation returns no key, so every endpoint helper MUST report no deploys (empty list, no result, 0). This is the documented health-only-check contract, not an error.
- **Empty-string project**: the deploy-target-key operation treats an empty project as missing. The endpoint MUST correlate to nothing, and a deploy with an empty project name MUST never match any endpoint.
- **Railway deploy or endpoint with no environment**: The key's environment segment is `""`. A no-environment railway endpoint MUST match only no-environment railway deploys of that project.
- **Unknown platform name** (for example `"crunchy"` absent from the data, or `"custom-host"` present): the platform-summary operation MUST omit known platforms with no deploys, and MUST place unknown platforms after the known ones in first-seen order.
- **Canonical alias in summaries**: the platform-summary operation does not canonicalize. A `"cloudflare"` platform string MUST produce its own summary, sorted as unknown, apart from `"cloudflare-pages"`. The endpoint helpers, by contrast, MUST treat the two as one platform.
- **Unparseable phase-confirmation or creation time on an in-flight deploy**: the stale-in-flight test MUST fail closed. The deploy MUST count in `total` only.
- **Future phase-confirmation time**: The age is negative, so the deploy MUST NOT be demoted and MUST count as `building`.
- **Exactly at the window**: An age exactly equal to the greater of 600000 and five times the probe interval MUST NOT demote. The comparison is strictly greater than.
- **Missing, zero or negative probe interval**: The demotion window MUST fall back to the 600 000 ms floor.
- **Unparseable creation time in the endpoint-deploys operation**: The comparison yields a value the sort treats as equal. The position of such a deploy MUST be treated as unspecified. Creation time is a typed server-supplied timestamp, so this is a caller precondition, not validated here.
- **Equal creation times**: Sorting MUST be stable, so ties MUST keep their input order.
- **Many failures**: the failures-for-endpoint operation MUST count every failed deploy in the input. It applies no time window and no cap. Bounding the history is the caller's job (the server that fills the deploy list).
- **Concurrent access**: Not applicable. The module is stateless.
- **Error states and offline**: Not applicable. The module performs no I/O. A missing or failed deploy feed reaches it only as an empty or older deploy list. Fetching and error reporting belong to the layer that loads the board.

