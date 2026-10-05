
| Check | Status | Category |
|---|---|---|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |

`separation-of-concerns` passes because `SiteWordmark.tsx` only composes registry lookup, the shared title split and theme tokens into markup, and ships on its own entry point so consumers do not pull in landing-page prose. `unit-test-coverage` fails because no test file exists for `SiteWordmark` anywhere under `packages/web` (the neighbouring `studioWordmark.test.tsx` covers `StudioWordmark`, a different component). These statuses otherwise rest on `SiteWordmark.tsx`: the brand and identity lines are plain text nodes with no ARIA suppression, read in document order (screen-reader-support); `text-apt-gold`/`text-apt-text`/`text-apt-text-dim` resolve to runtime theme roles whose rendered contrast is a property of the active theme, not measured or asserted by this component (contrast-ratio).

