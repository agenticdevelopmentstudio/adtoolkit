
| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.1 | 2026-10-04 | Mike Fullerton | Matches its type's shape: required fields, title heading, and only the type's own sections. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Added the read-only mode and required canWrite requirements, vectors T23-T26 and configuration rows to match the code; resolved the minimum-contrast-ratio NEEDS REVIEW marker as current behavior with a pending decision; added the Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics and Privacy sections; filled Reference Implementations; added separation-of-concerns and unit-test-coverage compliance rows. |
| 1.2.3 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.2.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-23 | Mike Fullerton | Lint pass: relinked Compliance to real catalog checks (Accessibility + Internationalization) and dropped two checks with no catalog equivalent; reformatted Design Decisions to the Decision/Rationale/Approved form; gave Platform Notes all five platform bullets (generic guidance for SwiftUI/Compose/AppKit-UIKit/WinUI 3) and corrected the source file path and metadata-generator path; added body-precedence, composite-row-key, retain-rows-on-error, and label-row-actions-header requirements with test vectors, plus vectors for the empty-state row count and the 80-character truncation boundary; clarified that the column cap can drop excess primary-key columns, not just scalars; dropped the unsupported "live" claim about the row count; and stated that delete confirmation is the caller's responsibility in `onDelete`; records the unverified theme-token contrast as an open question. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Renamed every requirement to subject-only kebab-case, dropping the old prefix everywhere it is cited. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the metadata-driven CrudTable from @adh-shared/crud. |
