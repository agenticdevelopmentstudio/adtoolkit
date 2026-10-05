
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | Platform Compliance |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |

Notes: separation-of-concerns passes because `ProjectChooserWindow` and its
content view controller own only the modal session, the button pair, and
the choose/cancel wiring between them — the project list itself, its
filtering, and its selection model belong entirely to
`ProjectBrowserViewController`, and the registry data belongs to
`ProjectsCoordinator`; neither is duplicated here. unit-test-coverage fails
because no test file exercises `ProjectChooserWindow` or
`ProjectChooserContentViewController` at all — `packages/apple/AgenticToolkit/Tests`
has no `ProjectChooserWindowTests.swift` or equivalent, so none of this
recipe's requirements (the onFinish wiring, the modal-identity guard on
close, the button enablement synchronization) has automated coverage.
native-controls-preference passes for the reason the source's own doc
comment gives: Cancel and Open are stock `NSButton`s, deliberately, rather
than a hand-drawn pair. platform-design-language passes because the window
uses a standard titled/closable/resizable `NSWindow`, a centered starting
position, and the Return-as-default-button / Escape-as-Cancel convention
every AppKit dialog follows. fault-tolerance passes because every guard in
this file (`runModal()`'s `guard let window`, `windowWillClose(_:)`'s
`guard NSApp.modalWindow === window`, the disabled-until-selected Open
button) fails safe — into a no-op or a `nil` result — rather than crashing
or corrupting `chosen`. main-thread-freedom passes because this file
performs no computation, file I/O, or network call of its own alongside
its UI work; the only blocking call it makes, `NSApp.runModal(for:)`, is the
platform's own intentional modal wait, not work this file could move off
the main thread.

