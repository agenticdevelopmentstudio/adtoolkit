
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe for CaptionedSliderView, covering row layout/priority behavior, live-versus-committed value sync, and one open accessibility question (slider/title label association) for review. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: add named requirements and test vectors for the unvalidated range and the overwritten `onChange` observer; decouple Appearance's font/color values from the theme files that own them; fix the Increase Contrast contradiction, the formatter-escaping claim, and the SwiftUI `onEditingChanged` guidance; drop RFC 2119 misuse and an editorial aside from Edge Cases and Platform Notes; correct the Compliance table and add related sibling-recipe links; note that the example formatters aren't locale-aware. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage Compliance row, judged from the source and test targets. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
