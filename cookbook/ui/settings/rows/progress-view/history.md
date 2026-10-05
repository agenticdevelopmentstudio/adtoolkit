
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial recipe — extracted from the Apple `ProgressView` (AppKit, macOS) source. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: corrected the SwiftUI and Compose Platform Notes for scale and default style mismatches; restated two implementation-detail requirements as observable behavior and moved their AppKit mechanics into Platform Notes; added references for platform API claims and related links to sibling row recipes; reformatted Design Decisions' Approved line; fixed the concurrent-access wording; annotated the mixed-scale and compile-time-only test vectors; removed an editorial aside from the WinUI 3 bullet; corrected the Compliance status and category casing and pruned non-catalog compliance checks. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added separation-of-concerns and unit-test-coverage Compliance rows, judged from the source and test targets. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
