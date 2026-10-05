
- **site-metadata-brand**: Building the full metadata object MUST set
  `applicationName` and `openGraph.siteName` to the resolved site
  definition's `fullLabel` when present, else its `label`, else the
  literal string `"Agentic Developer Hub"` when the site identifier
  resolves to no definition.
- **site-metadata-origin**: Building the full metadata object MUST set
  `metadataBase` to `https://<prodHost>` of the resolved site definition,
  or to `https://agenticdeveloperhub.com` when the site identifier
  resolves to no definition, regardless of which host actually served the
  request.
- **site-metadata-title-description**: Building the full metadata object
  MUST set the result's `title` and `description` to the caller-supplied
  `seo.title` and `seo.description` verbatim.
- **site-metadata-keywords**: Building the full metadata object MUST set
  `keywords` to the caller-supplied `seo.keywords` whenever that value is
  truthy — including an empty array — and MUST omit the `keywords` key
  entirely only when it is `undefined`.
- **site-metadata-canonical**: Building the full metadata object MUST set
  `alternates.canonical` to the caller-supplied `seo.path`, resolved
  against `metadataBase`, only when `seo.path` is a non-empty string; it
  MUST omit `alternates` entirely otherwise.
- **site-metadata-og-url**: Building the full metadata object MUST set
  `openGraph.url` to `seo.path` only when it is a non-empty string; it
  MUST omit `openGraph.url` otherwise.
- **site-metadata-og-block**: Building the full metadata object MUST set
  `openGraph.type` to `"website"`, `openGraph.locale` to `"en_US"`, and
  `openGraph.images` to a single-element array whose entry is the resolved
  card URL sized 1200×630, on every call.
- **site-metadata-card**: Building the full metadata object MUST use
  `seo.card`, resolved against `metadataBase`, as the image in both
  `openGraph.images` and `twitter.images` when it is not `null`/`undefined`,
  and MUST fall back to `/opengraph-image.png` otherwise.
- **site-metadata-twitter**: Building the full metadata object MUST set
  `twitter.card` to `"summary_large_image"` and `twitter.images` to a
  single-element array containing the same card URL used for
  `openGraph.images`.
- **site-metadata-robots-gate**: Building the full metadata object MUST
  set `robots.index`, `robots.follow`, `robots.googleBot.index` and
  `robots.googleBot.follow` to `false` when the build-time noindex flag
  (derived from the deployment-tier build flag documented in the
  Deployment Env recipe) is `true`, and to `true` otherwise, and MUST set
  `robots.googleBot['max-image-preview']` to `"large"` unconditionally.
- **canonical-only-scope**: Building the canonical-only metadata object
  MUST return a result containing only `alternates.canonical` set to the
  given path; it MUST NOT set `title`, `description`, or any
  `openGraph`/`twitter` key.
- **site-robots-non-production**: Building the robots policy MUST return
  `{ rules: [{ userAgent: '*', disallow: '/' }] }`, with no `sitemap` or
  `host` key, when the site identifier resolves to no definition, when the
  resolved definition's `prodHost` is an empty string, or when the given
  `host` (lower-cased, with a trailing `:<port>` stripped) equals neither
  `prodHost` nor `www.<prodHost>`.
- **site-robots-production**: Building the robots policy MUST return
  `{ rules: [{ userAgent: '*', allow: '/' }], sitemap: '<origin>/sitemap.xml', host: '<origin>' }`
  (`origin` = `https://<prodHost>`) when `host` is the production host or
  its `www.` form.
- **site-robots-disallow-option**: Building the robots policy MUST add a
  `disallow` key to the production rule set to the caller-supplied
  disallow list verbatim only when that list is a non-empty array; it MUST
  omit `disallow` when it is `undefined` or an empty array.
- **site-sitemap-origin**: Building the sitemap MUST resolve every entry's
  URL against `https://<prodHost>` of the resolved site definition, or
  against `https://agenticdeveloperhub.com` when the site identifier
  resolves to no definition.
- **site-sitemap-mapping**: Building the sitemap MUST map each given route
  to one sitemap entry whose `url` is the resolved origin concatenated
  directly with that route's path.
- **site-sitemap-last-modified**: Building the sitemap MUST set an entry's
  `lastModified` to the route's own `lastModified` when it is provided,
  and otherwise to one timestamp captured once at the start of the call and
  shared by every route in that call that omits `lastModified`.
- **site-sitemap-change-frequency**: Building the sitemap MUST set
  `changeFrequency` to the route's own value when provided and MUST
  default to `"monthly"` otherwise.
- **site-sitemap-priority**: Building the sitemap MUST set `priority` to
  the route's own value when it is not `null`/`undefined`, and MUST
  otherwise default to `1` when the route's path is exactly the string
  `"/"` and to `0.5` for every other path string.
- **og-image-size-export**: The module MUST export a fixed image-size
  constant of `{ width: 1200, height: 630 }`, the size a companion
  image-generation script emits into every site's default social-card
  image.
- **noindex-build-evaluation**: The noindex flag MUST be computed once,
  from the deployment-tier build flag (itself computed once at module
  load; see the Deployment Env recipe), and MUST NOT be re-read or
  recomputed per call to the full-metadata operation.
- **functions-are-pure**: All four exported operations MUST be synchronous
  and MUST NOT read or write any module-level mutable state; the only
  module-level values they read (the fixed image size, the default card
  path, the noindex flag) are assigned once at module load and never
  reassigned.
- **seo-path-scope**: Callers MUST set `seo.path` only from a single
  page's own metadata declaration, never from a shared layout's, because
  the surrounding framework merges metadata down the page hierarchy and a
  canonical inherited from a layout would mark every descendant route a
  duplicate of it.
- **seo-path-is-a-path**: `seo.path` and each route's `path` MUST be
  site-relative paths, never absolute URLs; neither the full-metadata
  operation nor the sitemap operation validates a leading slash or
  otherwise normalizes the value before using it.
- **bespoke-card-override**: A caller whose site has a designed social
  card SHOULD build on the full-metadata operation's result and override
  only `openGraph.images`, rather than hand-rolling the whole metadata
  object, so that title, description, robots and the Twitter block stay in
  sync with the shared contract. Rationale: three sites (devteam,
  myagenticteams, personaregistry) do this today per the source's own
  documentation, and duplicating the whole object risks the fields
  drifting out of sync when this module changes.
- **extra-disallow-paths**: Callers MAY pass a disallow list to the
  robots-policy operation to keep auth-gated or API routes out of the
  production `allow` rule.

