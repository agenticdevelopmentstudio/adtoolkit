
| Check | Status | Category |
|-------|--------|----------|
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [locale-aware-formatting](agenticdevelopercookbook://compliance/internationalization#locale-aware-formatting) | partial | Internationalization |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`platform-theming`/`separation-of-concerns` pass on every color in source
using the `apt-*` token vocabulary with no raw hex value or `!important`,
and on the component containing no data-fetching, caching, or
state-management code (see Design Decisions). The three accessibility
checks are `partial`: source uses relative-unit Tailwind text utilities and
semantic `<section>`/`<h4>` markup with no incorrect ARIA, but neither
Dynamic Type behavior nor token contrast ratios are verifiable from source
alone, and the missing `aria-live` wiring for the loading-to-populated
transition (see Accessibility: Announce state changes) is a real gap.
`string-externalization`/`no-hardcoded-strings` fail because all five
strings are English JSX literals with no translation call;
`locale-aware-formatting` is `partial` because `modifiedDate`/`timestamp`
arrive pre-formatted from `invitations-types.ts` (see Types) and the
component itself performs no formatting of its own.

`unit-test-coverage` fails: no test file for `notes-and-history.tsx` exists under the `adh-ui` test targets (`packages/web/packages/adh-ui/src/__tests__/` holds tests for other blocks only).

