
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: verified the `.fill`-placement `pinToEdges` behavior against its actual source and cited it; grounded the "row" vs "card" wording in sibling recipes; added named requirements and test vectors for title-read timing, view-model retention, and placement immutability; reworded the touch-target porting guidance to drop its RFC 2119 keyword; defined `ButtonViewModel`'s shape; tightened test vectors 015 and 018 and marked 018/019 as static checks; and made the Compose `.leading` mapping concrete. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added separation-of-concerns and unit-test-coverage Compliance rows, judged from the source and test targets. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.2.3 | 2026-10-04 | Mike Fullerton | Swift-only constructs in normative sections restated as platform-neutral behavior; the Apple mechanism is in Platform Notes. |
| 1.2.4 | 2026-10-04 | Mike Fullerton | requires-view-model-at-construction uses the one wording its sibling row specs share. |
