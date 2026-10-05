
The source has no test file. The vectors below are traced to the function bodies.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| deploy-display-001 | glyph-vercel | The platform-glyph operation on `vercel` | `"▲"` |
| deploy-display-002 | glyph-glitchtip-text-presentation | The platform-glyph operation on `glitchtip` | `"⚠︎"` (length 2) |
| deploy-display-003 | glyph-fallback | The platform-glyph operation on `netlify` | `"◆"` |
| deploy-display-004 | glyph-fallback | The platform-glyph operation on `""` | `"◆"` |
| deploy-display-005 | glyph-cloudflare, glyph-railway, glyph-http, glyph-dns, glyph-crunchy | The platform-glyph operation on each of `cloudflare-pages`, `railway`, `http`, `dns`, `crunchy` | `☁`, `⬢`, `◉`, `⌖`, `⛁` respectively |
| deploy-display-006 | platform-key-vocabulary, glyph-fallback | The platform-glyph operation on `Vercel` | `"◆"` (case-sensitive) |
| deploy-display-007 | color-vercel, color-cloudflare, color-railway, color-http, color-dns | The platform-color operation on each of `vercel`, `cloudflare-pages`, `railway`, `http`, `dns` | `apt-text`, `apt-cat-orange`, `apt-cat-purple`, `apt-cat-teal`, `apt-cat-indigo` |
| deploy-display-008 | color-crunchy-shares-http | The platform-color operation on `crunchy` compared with on `http` | Equal |
| deploy-display-009 | color-glitchtip-shares-cloudflare | The platform-color operation on `glitchtip` | `apt-cat-orange` |
| deploy-display-010 | color-fallback | The platform-color operation on `netlify` | `apt-text-muted` |
| deploy-display-011 | color-env-hue-exclusion, color-theme-tokens-only | The platform-color operation on every known platform key | result is a theme role and none of `apt-cat-blue`, `apt-cat-violet`, `apt-cat-pink` |
| deploy-display-012 | label-table | The platform-label operation on `cloudflare-pages` | `"CLOUDFLARE"` |
| deploy-display-013 | label-fallback-uppercase | The platform-label operation on `glitchtip` | `"GLITCHTIP"` |
| deploy-display-014 | label-fallback-uppercase | The platform-label operation on `fly-io` | `"FLY-IO"` |
| deploy-display-015 | short-label-overrides | The short-platform-label operation on `cloudflare-pages`, then on `crunchy` | `"CF"`, `"CB"` |
| deploy-display-016 | short-label-fallback | The short-platform-label operation on `railway` | `"RAILWAY"` |
| deploy-display-017 | short-label-fallback, label-fallback-uppercase | The short-platform-label operation on `netlify` | `"NETLIFY"` |
| deploy-display-018 | status-color-lookup | The deploy-status-color operation on `success`, `failed`, `building` | `apt-green`, `apt-red`, `apt-gold` |
| deploy-display-019 | status-color-unknown-muted | The deploy-status-color operation on `unknown` | `apt-text-muted` |
| deploy-display-020 | status-color-fallback | The deploy-status-color operation on `rolling-back` | `apt-gold` (equal to `canceled`) |
| deploy-display-021 | status-label-success, status-label-failed-uppercase | The deploy-status-label operation on `success`, then on `failed` | `"ready"`, `"FAILED"` |
| deploy-display-022 | status-label-in-flight, status-label-canceled | The deploy-status-label operation on `building`, `queued`, `canceled` | `"building"`, `"queued"`, `"canceled"` |
| deploy-display-023 | status-label-unknown | The deploy-status-label operation on `unknown` | `"outcome unknown"` |
| deploy-display-024 | status-label-passthrough | The deploy-status-label operation on `PROMOTED` | `"PROMOTED"` |
| deploy-display-025 | pure-functions | Call each export twice with the same argument | identical results; no global state changed |

