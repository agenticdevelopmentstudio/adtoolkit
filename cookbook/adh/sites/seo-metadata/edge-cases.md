
- **Null and empty input** — `seo.path === ''` MUST be treated identically
  to an omitted `path` (canonical and `openGraph.url` both absent),
  because the guard is a truthiness check, not a null check (MUST).
- **Null and empty input** — `seo.card === ''` MUST be used verbatim as
  the card URL, producing an empty-string image URL, because the fallback
  applies only to `null`/`undefined`, not to an empty string (MUST).
- **Null and empty input** — `seo.keywords === []` MUST still populate
  `keywords: []` in the output rather than omitting the key, because that
  guard is a truthiness check on the whole array, not a length check
  (MUST).
- **Null and empty input** — an empty route list MUST make the sitemap
  operation return `[]` (MUST).
- **Null and empty input** — `options.disallow === []` MUST omit the
  `disallow` key from the robots policy's production rule; this guard
  checks length, so it behaves differently from the `seo.keywords`
  truthiness guard above (MUST).
- **Null and empty input** — `host === ''` MUST be treated as
  non-production unless the resolved production host is also empty, in
  which case the non-production branch is already forced before the host
  comparison runs (MUST).
- **Boundary values** — `route.priority === 0` MUST be honored verbatim,
  not replaced by the `1`/`0.5` default, because the default applies only
  when the value is `null` or `undefined` (MUST).
- **Boundary values** — `route.path === '/'` (exact string equality) MUST
  get the priority default `1`; any other path string — including a
  trailing-slash variant such as `'/home/'` — MUST get `0.5`; there is no
  path normalization (MUST).
- **Boundary values** — the Open Graph/Twitter card is fixed at exactly
  1200×630; these four operations never emit any other image dimension
  for the card they construct (MUST).
- **Concurrent access** — all four exported operations are synchronous and
  read no mutable state that changes during a call; the noindex flag and
  the underlying deployment-tier build flag are assigned once at module
  load in a single-threaded execution model and never reassigned
  afterward, so concurrent calls from different requests cannot interleave
  or race on them. This is a fact of the execution model, not an unordered
  race (MUST).
- **Error states** — not directly applicable in the classic sense: this
  module makes no network, file-system, or database call for a dependency
  to fail on. The only "unresolved input" path — a site identifier for
  which the site-registry lookup finds no definition — degrades to the
  generic Agentic Developer Hub brand/origin (see site-metadata-brand,
  site-metadata-origin, site-sitemap-origin, site-robots-non-production)
  with no thrown error and no log line (MUST, as implemented).
- **Offline/disconnected** — not applicable. Per the source's own
  top-of-file documentation, "anything needing the live request… is
  passed IN by the caller rather than read here"; this module performs no
  network I/O of its own, so connectivity loss is entirely the caller's or
  the surrounding framework's routing layer's concern.

