
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | internationalization |
| [plural-forms](agenticdevelopercookbook://compliance/internationalization#plural-forms) | partial | internationalization |

**Separation of concerns.** The module only formats text. Problem derivation and indicator state come from the server's board through `OverviewTab`, and the endpoint counts are computed by the caller.

**Unit test coverage.** No test file exists for `status-sublabel.ts`, and no other test in `status-web` exercises `buildSublabel`.

**Explicit error handling.** No operation can fail. Unknown status words and empty inputs have defined outputs (verbatim phrase and `""`), so nothing is silently dropped.

**No hardcoded strings.** Every phrase, and the separator, is an English literal in the source.

**Plural forms.** Five of the seven mapped phrases apply an English singular/plural switch on `n === 1`. `down`, `degraded` and unmapped words are never pluralized, and no locale plural rules are used.

