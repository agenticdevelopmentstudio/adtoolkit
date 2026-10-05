
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe for SliderView, covering row layout/priority behavior, value-and-range sync on external change, and one open accessibility question (slider/title label association) for review. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: add `related` link to CaptionedSliderView; rename requirement to rejects-coder-initialization and its citations; fix the AppKit/UIKit platform note's wrong claim about UIKit's initializer split; name the row's exact arranged subviews and require a counting settingObserver test double in the affected test vectors; add test vectors for the async re-sync path and the inverted/zero-width range; drop RFC 2119 wording from two purely observational edge cases; move the overwritten-observer edge case into a Design Decision; remap the Compliance table's semantic-markup row to screen-reader-support and add the statuses' source rationale; records the unverified theme-token contrast as an open question. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Resolved the minimum-contrast-ratio NEEDS REVIEW marker against the source: restated as current behavior (no contrast check in the component) and recorded the gap as a pending Design Decision; added separation-of-concerns/unit-test-coverage Compliance rows. |
| 1.3.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
