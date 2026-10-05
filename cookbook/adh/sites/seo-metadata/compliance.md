
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |

`separation-of-concerns` passes: `metadata.ts` contains zero DOM, fetch, or rendering
code — only `import type` reaches into `next`, and the one value that needs the live
request (the serving hostname) is passed IN by the caller rather than read here, per the
module's own top-of-file comment. `unit-test-coverage` is `partial`:
`registry-characterisation.test.ts` — whose own `describe` block is titled "seo helpers
(251 consumers, no other test)" — exercises `canonicalOnly`, `ogImageSize`, and only the
title/description/`openGraph`-truthy slice of `siteMetadata`; `siteRobots`,
`siteSitemap`, and the `NOINDEX_BUILD` robots-gate branch of `siteMetadata` have no test
at all. `explicit-error-handling` passes: the module has no `try`/`catch` and no thrown
or caught exception; its only optional-unwrapping (`site?.prodHost ?? …`) is a
deliberate, documented default for an unresolved `SiteId`, not a swallowed error.
`no-hardcoded-strings` is `partial`: `seo.title`/`seo.description` are caller-supplied,
not hardcoded, but `openGraph.locale` (`'en_US'`) and the `'Agentic Developer Hub'`
fallback brand are hardcoded English strings with no localization path, as detailed
under Localization above.

