
| Check | Status | Category |
|---|---|---|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

`separation-of-concerns` passes: `delete-entity-section.tsx` renders the disclosure and two-phase dialog only; the destructive action is the caller-supplied `onConfirm`, and any navigation after deletion is the caller's. `unit-test-coverage` is `partial`: `deleteEntitySection.test.tsx` covers the default and reversible wording through both dialog phases, the archive versus trash glyph, the "Archiving…" busy label, and the non-Error rejection fallback, and the two busy/failure tests type the identifier only as a step toward clicking confirm, but no test asserts that the confirm button stays disabled until the typed text matches, or exercises the empty-`confirmValue` guard. `platform-theming` passes: every color in source is an `apt-*` token class with no raw hex value or `!important`. `focus-management` passes: the confirm flow rides the shared `Dialog` primitive with no override of its focus handling, and the type-to-confirm `Input` is labeled by a screen-reader-only `Label htmlFor`. `no-hardcoded-strings` fails: the copy ("Do you wish to proceed?", "Permanently", "This cannot be undone") is English JSX literal text with no translation call.

