
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | site identifier | required | Registry key resolved via the site-registry lookup; drives brand, `applicationName` and origin/`prodHost` for all four operations |
| `seo.title` | `string` | required | Verbatim `title`/`openGraph.title`/`twitter.title` |
| `seo.description` | `string` | required | Verbatim `description`/`openGraph.description`/`twitter.description` |
| `seo.path` | `string \| undefined` | `undefined` | Page-level-only canonical/`og:url` source path; a falsy value (including `''`) is treated as omitted |
| `seo.keywords` | `string[] \| undefined` | `undefined` | Included verbatim (even `[]`) whenever set to a truthy value |
| `seo.card` | `string \| undefined` | `/opengraph-image.png` | Social card path used for `openGraph.images`/`twitter.images`; only `null`/`undefined` triggers the default |
| `host` | `string` | required (robots policy only) | Request hostname compared against `prodHost`/`www.<prodHost>` (port-stripped, lower-cased) to choose allow vs. disallow |
| `options.disallow` | `string[] \| undefined` | `undefined` (no extra disallow) | Extra paths appended to the production `allow` rule when non-empty |
| `routes[].path` | `string` | required | Site-relative path concatenated directly onto the resolved production origin |
| `routes[].changeFrequency` | one of the sitemap format's standard change-frequency values, or `undefined` | `monthly` | Sitemap `changeFrequency` |
| `routes[].priority` | `number \| undefined` | `1` for `/`, else `0.5` | Sitemap `priority`; an explicit `0` is honored |
| `routes[].lastModified` | `Date \| undefined` | one timestamp shared by every route in the same sitemap call that omits it | Sitemap `lastmod` |
| `NEXT_PUBLIC_DEPLOYMENT_ENV` | build-time-inlined env var | unset | Folded into the deployment-tier build flag and the noindex flag once at module load; `'local'`/`'testing'`/`'staging'` produce a noindex build |

