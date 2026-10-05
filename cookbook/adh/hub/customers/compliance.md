
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | failed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | passed | Access Patterns |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |

Notes: unit-test-coverage passes because `CustomersTopicTests.swift`
carries meaningful, behavior-specific assertions for every requirement
described above — 9 test methods, including the decode/label-fallback,
newline-trim, duplicate-rejection, and delete-confirmation paths — though
the detail-form `HubError.conflict` fallback (`detail-save-conflict-fallback`)
is exercised only by inspection of the source's `catch` block, not by a
dedicated test, per Conformance Test Vector 020. separation-of-concerns
passes because all three given sources import only `Foundation` (plus
`AgenticToolkitHTDV` for the HTDV/Forms types) and hold no AppKit/UIKit
dependency of their own. explicit-error-handling passes because every
`throws` boundary in these three sources is caught and converted into an
explicit `HubError` — via a specific re-mapping (`notFound`, `conflict`)
or `HubError.wrap` — with no path that drops a failure silently, per
Edge Cases' Error states. error-recovery fails because none of the three
given sources retries a failed operation or backs off — a failed
`list`/`get`/`create`/`update`/`delete` call is reported once and left to
whatever caller invoked `child`/a save action to decide what happens
next. data-integrity passes because both the create and detail save
actions validate before writing — an email-format check, a
case-insensitive duplicate-email precheck on create, and a
required-email check — before ever calling `create`/`update`.
error-response-handling passes because `CustomersTopic` explicitly
branches on the two `HubError` cases it can act on (`notFound`,
`conflict`) and uniformly wraps every other case for the caller to
display via `HubError.message` (out of these given sources), rather than
leaving any case unhandled. no-hardcoded-strings fails because every
user-facing string these sources produce — labels, field labels,
validation messages, and delete confirmation text — is a hardcoded
English literal with no localization key, per Localization above.
input-sanitization is partial: `email` receives real format validation
(the shared `emailPattern` regex, enforced both in the field spec and
implicitly by the duplicate-email comparison), but the other four fields
(`displayName`, `externalId`, `slug`, `avatarUrl`) receive no validation
or character-set restriction at all beyond the blank-to-`nil` collapse in
`other-four-fields-use-nonBlank` — `avatarUrl` in particular is never
checked to be a well-formed URL despite its name and placeholder.

