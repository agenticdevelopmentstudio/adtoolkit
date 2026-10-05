
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe for ExtensionInputBoxViewController, covering layout, per-edit revalidation, the Return accept/defer/drop three-way logic, and four open accessibility/UX review points (loading indicator, field accessibility label, validation-change announcement, Differentiate Without Color) for review. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: trimmed tags/summary to convention limits, added the sibling picker recipe to `related`, renamed every requirement to subject-only kebab-case, restated private-state requirements/vectors/edge cases as observable behavior, bolded the Design Decisions form, corrected the WinUI 3 bullet's WPF-only APIs and `PasswordBox` selection gap, described SwiftUI's pending-submit replay, added the secure-storage/contrast-ratio compliance rows, downgraded the arrow-key edge case from MUST to a documented known quirk, and added test vectors for empty-string acceptance and Escape from another window. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to workspace/extensions/vscode-api/window/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added a unit-test-coverage compliance row judged from the test targets. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
