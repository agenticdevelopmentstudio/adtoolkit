
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe for ColorPickerView, covering row layout, unguarded color-well commit behavior, and one open accessibility question (color well/title label association) for review. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: promoted the color-clamping and onChange-ownership edge cases to named MUST requirements with test vectors; renamed `requires-designated-initializer` to `rejects-coder-initialization`; fixed the WinUI grid columns and the SwiftUI/React platform notes to stop copying the color-well/title accessibility gap onto new platforms; bolded Design Decision labels, rewrote Decision 1's rationale, and dropped the meta decision about requirement count; populated `related` with the sibling row recipes; marked `keyboard-navigable` partial pending a keyboard/VoiceOver pass; removed the source-typo edge case; fixed the `AppKit / UIKit` platform-notes label. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage Compliance row, judged from the source and test targets. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
