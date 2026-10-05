
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial ingredient recipe for MCPChipsBarView, covering the bar/picker view pair, the view model's sort/label/toggle logic, the one-time active-ids snapshot and stale-id quirks, and one open localization question (unlocalized computed label strings) for review. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: reworded two requirements and the `cancellables`-touching one to state observable behavior instead of private identifiers, moving those identifiers into Platform Notes; added an open-question note for the ungrouped rack/chevron icons; added an edge case for the non-idempotent row-toggle setter; corrected the keyboard-navigable compliance status and the ThemeTypography citation; reformatted Design Decisions to the bold three-line form and noted two MUSTs as accepted-pending-approval behavior; tightened three underspecified test vectors; dropped a redundant tag; converted Compliance categories to display names and removed the invented `main-actor-confined` and `differentiate-without-color` checks via the compliance-catalog fixer. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ai/chat/chat-window/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage compliance row. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
