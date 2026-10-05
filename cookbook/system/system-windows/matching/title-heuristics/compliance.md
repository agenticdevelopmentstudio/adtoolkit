
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

unit-test-coverage is partial: `HeuristicTests.swift` asserts Xcode (em and
en dash), one VS Code title, and two Warp titles, but has no test for
`BraveHeuristic` or `TerminalHeuristic`, none for the VS Code generic-title
and filename branches, and none for the "Welcome — Visual Studio Code" title
whose code result contradicts its doc comment. separation-of-concerns passes
because each app's title format lives in its own type, the separator logic is
centralized in `HeuristicTitleParser`, and app-name lookup and scoring stay in
`HeuristicRegistry` and `SystemWindowMatcher`. explicit-error-handling passes
because the only failure mode — no extractable pattern — is expressed in the
return type as `nil`, and the caller handles it explicitly with a documented
fallback. no-hardcoded-strings fails because each heuristic's user-visible
`name` is an English literal with no localization lookup, and the Brave and
VS Code parsing literals only recognize English application titles (see
Localization).

