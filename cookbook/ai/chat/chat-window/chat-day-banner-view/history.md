
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial creation from the macOS/AppKit source (ChatDayBannerView.swift) |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: fixed related/depends-on to cite this repo's AI chat bubble recipe instead of ADT's, corrected the "Saturday" day-formatting example to "Wednesday" throughout, pinned the calendar to a fixed time zone in the non-deterministic test vectors, moved AppKit-private identifiers out of requirements into the AppKit/UIKit Platform Note, replaced named cross-recipe citations with domain URLs, named concrete Compose/web date-formatting equivalents, and downgraded screen-reader-support/semantic-markup to partial pending resolution of the label's accessibility-tree exposure |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ai/chat/chat-window/. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Resolved the rule-width-priority NEEDS REVIEW marker as current behavior plus a pending Design Decision; added separation-of-concerns and unit-test-coverage compliance. |
| 1.3.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
