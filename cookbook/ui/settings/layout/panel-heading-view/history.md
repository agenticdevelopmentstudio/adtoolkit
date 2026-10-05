
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added Compliance rows for separation-of-concerns and unit-test-coverage |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/layout/. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: cite spacing/typography tokens instead of literals; restate two AppKit-mechanics requirements as outcomes and move their mechanism into AppKit Platform Notes; trim duplicated theme/typography prose; move the internal cookbook reference from `references` to `related` and add `explanation-view` to `depends-on`; fix Design Decision approval-line format and remove two commentary (non-decision) entries; change `screen-reader-support` from the disallowed `needs-review` status to `partial` and rebuild the Compliance table against real catalog checks (`screen-reader-support`, `no-hardcoded-strings`); drop the unsupported WinUI "reason this recipe exists" claim and point the SwiftUI note at the theme heading token instead of `.headline`; remove RFC 2119 keywords from Edge Cases in favor of citing the named requirements they follow from; mark test vectors 001/015/016 as compile-time/trap checks; trim the Overview to component identity and usage. |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation, extracted from the Apple `PanelHeadingView` (AppKit, macOS) source. |
