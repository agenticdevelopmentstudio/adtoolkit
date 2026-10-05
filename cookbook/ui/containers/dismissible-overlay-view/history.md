
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.0 | 2026-10-04 | Mike Fullerton | Resolved the keyboard-focus-containment NEEDS REVIEW marker as current behavior (Tab focus is not trapped) with a pending design decision; added separation-of-concerns and unit-test-coverage compliance rows. Added the confines-to-ui-thread requirement and vector. Corrected unit-test-coverage to partial: the overlay's dismissal gestures are tested through its subclass. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/containers/. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; reformatted Design Decisions to bold three-line form; moved the internal cross-reference from `references` to `related` and added the HIG Motion URL; corrected Compliance to real catalog checks and categories; added a two-overlay conformance vector and an `isDismissing` Configuration row; qualified the WinUI 3 accelerator-precedence claim; tightened animation-timing conformance vectors for XCTest executability; trimmed edge-case RFC tags and fixed the zero-sized-host accuracy issue. |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial recipe — extracted from the Apple `DismissibleOverlayView` (AppKit, macOS) source. |
