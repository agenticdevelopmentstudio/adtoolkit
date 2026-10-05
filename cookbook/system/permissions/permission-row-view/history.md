
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation, extracted from `PermissionRowView.swift`. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: added pre-refresh-action, keyboard-activation, and test-observable-surface requirements with vectors; reworded concurrent-access as caller-owned/undefined ordering; detailed the empty-keychain edge case; fixed vector 013 to use `.keychain` and extended vectors 004/019 with icon/card-color assertions; bolded Design Decisions and added one for the dark-only card overlay; marked `platform-design-language`/`contrast-ratio` partial, title-cased Compliance categories, and dropped two checks with no catalog match. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to system/permissions/. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Resolved contrast marker as current behavior plus pending decision; cited required Compliance checks |
| 1.3.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
