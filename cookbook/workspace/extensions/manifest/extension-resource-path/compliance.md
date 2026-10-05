
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

`separation-of-concerns` passes because the file cleanly splits three
responsibilities across three types: `ExtensionResourcePathError` only names
and describes one failure, `ExtensionResourcePath` only resolves and checks
containment, and `InstalledContentLocation` only composes locations — none of
the three reads a manifest, parses JSON, or performs a file read
(`error-case`, `single-base-resolve`, `application-support-composition`).
`input-sanitization` passes because every `declared` string is
extension-author-supplied, untrusted text, and `resolve` never trusts it: it
is resolved, symlink-canonicalized, and checked against a component-wise
containment rule before any caller is handed a `URL` to read
(`candidate-construction`, `escape-refusal`, `symmetric-canonicalization`);
the source's own header comment names the exact vulnerability class this
closes. `explicit-error-handling` passes because the one failure this file
defines is never swallowed — it is a typed, `Equatable`,
`LocalizedError`-conforming case a caller must handle, and every production
caller (`ThemeContributionPoint`, `SnippetStore`, `ExtensionHost`) does
handle it, either recording it for display or re-throwing it as its own
richer error (`escape-refusal`, `error-message`). `unit-test-coverage`
passes: `ExtensionResourcePathTests.swift` exercises both `resolve`
overloads, the flagless-base case, the escape refusal and its message, and
the containment primitive directly (a prefix-sharing sibling, self-
containment, a deep descendant, a symlinked base, and a symlink-planted
escape), and its `InstalledContentLocationTests` suite exercises both
`InstalledContentLocation` factories and the injected-home override.
`no-hardcoded-strings` fails: `errorDescription` returns a fixed English
sentence with no localization lookup of any kind, so the message an
extension author sees when a path escapes is English regardless of the
host's locale (`error-message`, Localization).

