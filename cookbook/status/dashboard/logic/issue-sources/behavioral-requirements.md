
### Issue-source vocabulary

- **source-union**: the issue-source vocabulary MUST be exactly these seven identifiers: `"dns"`, `"http"`, `"glitchtip"`, `"vercel"`, `"cloudflare-pages"`, `"railway"`, `"crunchy"`.
- **source-spelling**: The Cloudflare source MUST be spelled `"cloudflare-pages"`, not `"cloudflare"`. A row whose source is `"cloudflare"` MUST NOT be treated as a member of the vocabulary.
- **source-glitchtip-separate**: `glitchtip` MUST be a distinct member from `http`, so an error-tracker Problem can be open on a site that every probe reports as up. The doc comment calls carrying it here "rather than folding it into `http`" the whole point.

### Source label map

- **label-map-total**: the source label map MUST have exactly one entry for every member of the issue-source vocabulary and no other keys.
- **label-values**: the source label map MUST map `dns` to `"DNS"`, `http` to `"HTTP"`, `glitchtip` to `"GlitchTip"`, `vercel` to `"Vercel"`, `cloudflare-pages` to `"Cloudflare"`, `railway` to `"Railway"` and `crunchy` to `"Crunchy Bridge"`.
- **label-non-empty**: Every value in the source label map MUST be a non-empty string.
- **label-unguarded-index**: Looking up the source label map with an identifier that is not a member of the issue-source vocabulary MUST yield no result. The module does not supply a fallback label; the doc comment warns that such a source "renders `undefined` in the filter and the badge". Callers holding a plain string narrow it with the issue-source guard operation first (the row-building logic falls back to the raw string when the guard fails).

### Source order list

- **order-members**: the source order list MUST contain each member of the issue-source vocabulary exactly once, seven entries in all.
- **order-canonical**: the source order list MUST list the sources in the order `dns`, `http`, `glitchtip`, `vercel`, `cloudflare-pages`, `railway`, `crunchy`. Consumers render filter checkboxes and group lists by filtering this list, so this order is the display order.
- **order-not-mutated**: The module MUST NOT mutate the source order list after it is defined.

### Issue-source guard operation

- **guard-signature**: the issue-source guard operation MUST take one text-value argument and MUST return a true-or-false result indicating whether that value is a member of the issue-source vocabulary.
- **guard-true**: it MUST return true when the argument is exactly equal (strict comparison) to a member of the source order list.
- **guard-false**: it MUST return false for every other string, including the empty string, a member with different casing (`"DNS"`), a member with surrounding whitespace, and the integration spelling `"cloudflare"`.
- **guard-no-normalization**: it MUST NOT trim, lowercase or otherwise normalize its argument before comparing. (The server's separate source-normalization function trims and lowercases, and maps `"cloudflare"` to `"cloudflare-pages"`; this client guard does neither.)
- **guard-no-throw**: it MUST NOT throw for any string argument.
- **guard-order-source**: it MUST decide membership from the source order list, so the guard and the filter order agree by construction.

### Stuck-deploy threshold

- **stuck-threshold-value**: the stuck-deploy threshold MUST equal `1800000` (30 × 60 × 1000, thirty minutes).
- **stuck-threshold-mirror**: the stuck-deploy threshold MUST equal the server's own mirrored threshold, which drives the backend's stuck issues and alerts.
- **stuck-not-client-derived**: The client MUST NOT derive stuck Problems from the stuck-deploy threshold. The doc comment records this as an owner call dated 2026-07-10: an in-flight `building` row is activity, never a Problem. No module in the client reads the constant.
- **queued-never-stuck**: A `queued` deploy MUST NOT count as stuck at any age. The doc comment gives the reason: "a long queue is almost always an INTENTIONAL hold, not a wedge".
- **platform-debounce-server-side**: The client MUST NOT implement the platform-unreachable debounce. The module's closing note says the debounce lives server-side, reaching the board as a `platform-health|<source>` Problem, which the client renders directly with no client-side streak or threshold.

### Mirror contract

- **mirror-union**: The client's issue-source vocabulary MUST contain the same members as the server's.
- **mirror-labels**: The client's source label map MUST hold the same key-to-label pairs as the server's.
- **mirror-order**: The client's source order list MUST list the same members in the same order as the server's.
- **mirror-hand-synced**: The two files restate the vocabulary rather than share it. Both doc comments name the other file; no import, generated code or parity test ties them together. A port MUST keep both sides in step when a source is added.
- **mirror-client-extras**: the issue-source guard operation exists only on the client side. The server file has no equivalent guard.

### Purity and concurrency

- **pure-module**: The module MUST have no side effects on import, MUST perform no I/O, and MUST NOT mutate any of its exports after they are defined.
- **single-threaded**: The module's exports are never mutated after load, so calls cannot interleave and it needs no ordering rule between calls.

