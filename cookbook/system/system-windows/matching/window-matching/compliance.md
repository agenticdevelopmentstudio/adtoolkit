
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy and Data |

`separation-of-concerns` passes: parsing (`AppHeuristic`, `HeuristicTitleParser`), user rules, persistence (`CustomHeuristicStore`), lookup (`HeuristicRegistry`) and scoring/assignment (`SystemWindowMatcher`) are separate types, and applying match results is left to `SystemWindowContextManager`. `unit-test-coverage` is partial: `SystemWindowMatcherTests` covers the app gate, appOnly, the substring length guard, substring and regex scoring, the display bonus, threshold filtering, deterministic ties and `MatchResult` equality, and `HeuristicTests` covers the separators, custom-rule fingerprinting and `isBuiltIn`; nothing tests `CustomHeuristicStore`, `.appAndTitleExact` scoring, the fingerprint fallback, invalid regexes or `registerCustomRules` replacement. `explicit-error-handling` passes because store failures are thrown to the caller and invalid regexes are logged rather than swallowed. `no-hardcoded-strings` fails because `CustomMatchMode.displayName` and the default rule name are English literals shown in Settings. `data-integrity` is partial because rules are never validated: an invalid regex or empty app name is accepted and saved, and two rules for the same app leave one silently unused. `no-pii-in-logs` passes because only the user-authored regex pattern is logged, never a window title.

