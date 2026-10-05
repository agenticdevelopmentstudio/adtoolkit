
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe for ThemePickerView, covering the popup/preview composition, the notification-mediated decoupling between selection and preview refresh, the private constituent views, and one open question on a disabled state. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: restated three implementation-detail requirements as observable contracts and moved their mechanics into Platform Notes; pinned three previously undated claims to source lines; replaced the suppressed Localization "Not applicable" with an open question on the unlocalized popup title; disambiguated ThemeScope identity in two requirements and test vectors 009/010, and gave test 006 a concrete expected value; dropped the incidental timing assertion from test 012; reworded three Edge Cases MUSTs to plain description; reformatted Design Decisions to the bold three-line form and removed two non-decision entries; shortened the summary; added related/depends-on domains for composed and sibling recipes; fixed a self-contradicting UIKit note and dropped WinUI aside noise; and marked three Compliance checks partial with the inherited-result explained. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Added unit-test-coverage Compliance row, judged from the source and test targets. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
