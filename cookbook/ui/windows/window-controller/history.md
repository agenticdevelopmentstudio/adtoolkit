
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial extraction from the Apple `WindowController.swift` source (`WindowController<ViewControllerType>` and `WindowContentViewController<ViewType>`). |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: reformat Design Decisions to bold three-line form; fix the Compliance table's Category column and drop inapplicable checks (no-raw-hex, differentiate-without-color, localizable-strings, idempotent-operations); rename the AppKit Platform Notes bullet to AppKit / UIKit and add the UIKit equivalent; remove Accessibility Options template residue; state `NSViewController`'s inherited `@MainActor` isolation outright instead of hedging; add a Conformance Test Vectors Action column and rework vectors 004 and 008 into a compile-time check and a death-test check; rename the States column to Behavior; and rewrite file-coupled "Not applicable" justifications to describe the component's behavior. |
| 1.1.1 | 2026-09-23 | Mike Fullerton | Compliance: removed rows for checks absent from the cookbook catalog |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/windows/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added separation-of-concerns (passed) and unit-test-coverage (failed) compliance rows. |
