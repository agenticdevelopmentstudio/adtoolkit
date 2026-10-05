
### Platform keys

- **platform-key-vocabulary**: The module MUST recognise these platform keys, compared by exact, case-sensitive string equality: `vercel`, `cloudflare-pages`, `railway`, `http`, `dns`, `crunchy`, `glitchtip`. `http` and `dns` are health checks, not hosting platforms. `crunchy` is a database, and `glitchtip` stands for thrown errors.
- **platform-input-type**: Every platform operation MUST accept any text value and MUST NOT throw for any input.

### Platform-glyph operation

- **glyph-signature**: the platform-glyph operation MUST return a text value.
- **glyph-vercel**: it MUST return `▲` (U+25B2) for `vercel`.
- **glyph-cloudflare**: it MUST return `☁` (U+2601) for `cloudflare-pages`.
- **glyph-railway**: it MUST return `⬢` (U+2B22) for `railway`.
- **glyph-http**: it MUST return `◉` (U+25C9) for `http`.
- **glyph-dns**: it MUST return `⌖` (U+2316) for `dns`.
- **glyph-crunchy**: it MUST return `⛁` (U+26C1) for `crunchy`.
- **glyph-glitchtip-text-presentation**: it MUST return the two-code-point text U+26A0 U+FE0E for `glitchtip`. The bare warning sign can render full-colour and double-width beside six monochrome glyphs on some platforms; VARIATION SELECTOR-15 forces the text form.
- **glyph-fallback**: it MUST return `◆` (U+25C6) for every other string, including the empty string.

### Platform-color operation

- **color-signature**: the platform-color operation MUST return a theme color role.
- **color-vercel**: it MUST return the theme role `apt-text` for `vercel`. This is the brand near-white role.
- **color-cloudflare**: it MUST return the theme role `apt-cat-orange` for `cloudflare-pages`.
- **color-railway**: it MUST return the theme role `apt-cat-purple` for `railway`.
- **color-http**: it MUST return the theme role `apt-cat-teal` for `http`.
- **color-dns**: it MUST return the theme role `apt-cat-indigo` for `dns`.
- **color-crunchy-shares-http**: it MUST return the theme role `apt-cat-teal` for `crunchy`, the same role as `http`.
- **color-glitchtip-shares-cloudflare**: it MUST return the theme role `apt-cat-orange` for `glitchtip`, the same role as `cloudflare-pages`.
- **color-fallback**: it MUST return the muted theme role `apt-text-muted` for any platform with no own entry in the color map.
- **color-env-hue-exclusion**: a platform color role MUST NOT equal an environment hue role. The environment hue roles are `apt-cat-blue`, `apt-cat-violet` and `apt-cat-pink`. A row that shows both an env badge and a platform badge must read unambiguously.
- **color-theme-tokens-only**: every returned platform color MUST be a named theme role, never a hardcoded literal color value. The role's concrete rendering is owned by the shared theme package.

### Platform-label operation

- **label-signature**: the platform-label operation MUST return a text value.
- **label-table**: it MUST return `VERCEL` for `vercel`, `CLOUDFLARE` for `cloudflare-pages`, `RAILWAY` for `railway`, `HTTP` for `http`, `DNS` for `dns` and `CRUNCHY` for `crunchy`.
- **label-fallback-uppercase**: it MUST return the platform's own name, upper-cased, for any platform with no own entry in the label map. This includes `glitchtip`, which has no label entry and so yields `GLITCHTIP`.

### Short-platform-label operation

- **short-label-signature**: the short-platform-label operation MUST return a text value.
- **short-label-overrides**: it MUST return `CF` for `cloudflare-pages` and `CB` for `crunchy`.
- **short-label-fallback**: it MUST return the platform-label operation's result for every platform with no short override. For example, it returns `VERCEL` for `vercel`.

### Deploy-status-color operation

- **status-color-signature**: the deploy-status-color operation MUST return a theme color role for a deploy status, which is one of `success`, `failed`, `building`, `queued`, `canceled`, `unknown`, or any other text value.
- **status-color-lookup**: it MUST return the mapped role when the status has one: `success` → `apt-green`, `failed` → `apt-red`, `building`/`queued`/`canceled` → `apt-gold`, and `unknown` → `apt-text-muted`.
- **status-color-unknown-muted**: it MUST return the muted role for `unknown`, not the gold used for live progress. `unknown` is documented as "an ABSENCE of a verdict".
- **status-color-fallback**: it MUST return the `canceled` role (`apt-gold`) for any status string that is not one of the mapped statuses. An unrecognised status therefore renders gold, not muted.
- **status-color-token-not-hex**: it MUST return a theme-role reference, never a literal color value. Its doc comment describes a literal-color return, which is stale relative to the theme-role map it actually returns.

### Deploy-status-label operation

- **status-label-signature**: the deploy-status-label operation MUST return a text value.
- **status-label-success**: it MUST return `ready` for `success`.
- **status-label-failed-uppercase**: it MUST return `FAILED`, in upper case, for `failed`. It is the only upper-case status label.
- **status-label-in-flight**: it MUST return `building` for `building` and `queued` for `queued`.
- **status-label-canceled**: it MUST return `canceled` for `canceled`.
- **status-label-unknown**: it MUST return `outcome unknown` for `unknown`. `unknown` is an in-flight phase the backend expired without confirmation, and the label must say so rather than echo the raw status.
- **status-label-passthrough**: it MUST return the input string unchanged for any other status.

### Contract-wide

- **pure-functions**: every export MUST be a synchronous, side-effect-free function whose result depends only on its argument and the module's constant maps.
- **no-mutation**: the module MUST NOT expose its internal lookup maps (the platform color, label, and short-label maps). They are module-private, and no function mutates them.
- **concurrency**: the functions MAY be called from any context; they hold no state, so calls cannot interleave with themselves.

