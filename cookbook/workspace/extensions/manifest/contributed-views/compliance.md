
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`graceful-degradation` passes because a malformed field, an unmapped icon, an unknown container, or a duplicate view id each costs only that one field or entry — per `unreadable-key-note-per-key`, `icon-codicon-unmapped`, `unknown-container-note`, and `duplicate-view-id-first-wins` — never the extension's other views or the whole build. `idempotent-operations` passes because building views is a pure function (`build-is-pure`) over immutable inputs and a fixed table, so calling it twice with identical arguments MUST return bit-for-bit identical containers, views, and notes lists, with no accumulation between calls. `no-hardcoded-strings` fails because every note's `detail` sentence is an unlocalized English string literal (see Localization), with no localization key of any kind. `unit-test-coverage` passes: `ContributedViewsBuilderTests.swift` exercises registry-id namespacing, the tree/webview default, every icon-resolution branch (mapped, unmapped, animated, blank, file-path), the `when`-clause note, all four axis-rule target kinds, both duplicate-view-id shapes (within one target and across two), container-without-icon survival, both directions of the unreadable-key leniency, and declared-order preservation for both containers and views.

`separation-of-concerns` passes because `ContributedViews.swift` imports only Foundation and splits its work across separate types: the value records (`ContributedViewContainer`, `ContributedView`, `ContributedViewNote`), the codicon lookup table (`CodiconSymbols`), and the pure `ContributedViewsBuilder`; the builder only classifies the manifest and never renders, persists, or evaluates `when` clauses.

