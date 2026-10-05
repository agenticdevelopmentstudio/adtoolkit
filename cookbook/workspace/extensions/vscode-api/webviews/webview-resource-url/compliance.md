
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

`separation-of-concerns` passes because naming a URL (`hostDocumentURL`,
`url(forFile:)`), deciding what a URL names (`target(of:)`), and deciding
whether a path is contained (delegated entirely to `ExtensionResourcePath`)
are three distinct responsibilities that this file keeps apart rather than
folding into one function (`resource-url-naming-only`, `containment-
delegation`). `input-sanitization` passes because every URL this file
decides on is, per its own header comment, from a hostile webview page, and
`target(of:)` never trusts it: scheme, panel identity, and file containment
are each checked in order before a `.file` result is ever returned
(`scheme-validation-first`, `panel-validation-second`, `candidate-
canonicalization`). `explicit-error-handling` passes because the three
failures this file defines are never swallowed — they are typed, `Equatable`,
`LocalizedError`-conforming cases a caller must catch, and the one production
caller this recipe traced (`WebviewSchemeHandler`) does catch and act on
every one of them (`error-case`, `error-message`). `unit-test-coverage`
passes: `WebviewResourceURLTests.swift` exercises the naming round trip
(including percent-encoding), the host document, every refusal path
(no roots, outside every root, a name-prefix sibling, the root itself, a
traversal, a wrong panel, a wrong scheme), and the scheme constant's shape
directly. `no-hardcoded-strings` fails: `errorDescription` returns one of
three fixed English sentences with no localization lookup of any kind, so
the message an extension author or developer sees when a resource is
refused is English regardless of the host's locale (`error-message`,
Localization).

