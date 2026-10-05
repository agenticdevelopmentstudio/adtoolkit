
- **Empty platform string**: the platform-glyph operation on `""` MUST return `◆`, the platform-color operation on `""` MUST return the muted role, and the platform-label and short-platform-label operations on `""` MUST return `""`. No operation validates or rejects the empty string.
- **Empty status string**: the deploy-status-color operation on `""` MUST return the gold `canceled` role, and the deploy-status-label operation on `""` MUST return `""`.
- **Case mismatch**: A key that differs only in case, such as `Vercel` or `SUCCESS`, MUST miss every map and take the fallback path. There is no normalisation.
- **Unknown platform**: A platform the module does not know MUST still render. It gets the `◆` glyph, the muted role, and its own name upper-cased as the label. The module MUST NOT throw.
- **Unknown status**: An unrecognised status MUST render gold (the `canceled` role), and its label MUST be the raw string. This differs from the known `unknown` status, which renders muted with the label `outcome unknown`.
- **glitchtip partial registration**: `glitchtip` has a glyph and a color but no label entry and no short label. Both label operations MUST yield `GLITCHTIP` through the upper-case fallback.
- **Shared hues**: `crunchy`/`http` and `glitchtip`/`cloudflare-pages` MUST return identical roles. The glyph and label disambiguate them, and glitchtip rows (error incidents) and cloudflare rows (deploys) never appear in the same list.
- **Glyph string length**: the `glitchtip` glyph MUST be two UTF-16 code units long. A port that measures or truncates glyphs by code-unit count MUST keep the variation selector.
- **Concurrent calls**: Not applicable. The functions are pure and hold no state, so calls cannot interleave.
- **Error states, offline, timeouts, cancellation**: Not applicable. The module performs no I/O, has no dependency that can fail, and cannot be cancelled or time out.

