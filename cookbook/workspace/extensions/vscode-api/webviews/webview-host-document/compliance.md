
| Check | Status | Category |
|-------|--------|----------|
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

`input-sanitization` **passed**: `escapedForScriptElement(_:)` escapes every
character an extension-authored `initialState` could use to break out of
the `<script>` element it is embedded in, and both break-out families —
closing the script tag early, opening an HTML comment — are covered by a
named test each (webview-host-document-009, webview-host-document-010).
`separation-of-concerns` **passed**: this file only assembles the document
and generates the bootstrap script; decoding the messages that bootstrap
sends back is a separate component's job (`WebviewMessageRelay` in
`WebviewPanelViewController.swift`), not this one's.
`unit-test-coverage` **passed**: `WebviewHostDocumentTests.swift` exercises
head insertion, the no-head fallback across three markup shapes, case
insensitivity, markup passthrough, both state-embedding paths, both
break-out families, and the two shared bridge names. `explicit-error-handling`
is **partial**: `html(wrapping:initialState:)` has no error path of its own
to swallow, but the one place an error can occur — a non-nil `initialState`
that is not valid JSON — throws inside a JavaScript IIFE with no signal
reaching this file's caller (**initial-state-json-validity**).
`idempotent-operations` **passed**: `html(wrapping:initialState:)` is a
pure function of its two arguments; repeated calls with identical arguments
return identical strings. `no-hardcoded-strings` **failed**: the
acquire-once error message is hardcoded English with no lookup table or
locale parameter anywhere in this file (see Localization) — a plain,
honestly-reported gap in the source, not a hidden one.

