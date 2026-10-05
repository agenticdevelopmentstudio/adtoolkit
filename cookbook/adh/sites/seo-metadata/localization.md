
This module hardcodes two user-facing strings rather than sourcing them from any
localization system:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — no i18n key) | `en_US` | `openGraph.locale`, set unconditionally regardless of any per-site or per-caller locale |
| (none — no i18n key) | `Agentic Developer Hub` | `applicationName`/`openGraph.siteName` fallback used whenever the site identifier resolves to no definition |

`seo.title` and `seo.description` themselves are not hardcoded — they are supplied by
the caller per call — but the module has no locale parameter and applies the same
`en_US` Open Graph locale no matter what language the caller's copy is written in.

