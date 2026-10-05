
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: inlined a minimal LogProvider/LogColumn/LogLine/ThemedLabel contract in Overview; restated two implementation-detail requirements (`selection-fill-reflects-current-theme`, `cell-request-uses-column-reuse-identifier`) as observable behavior and moved their mechanism into Design Decisions; restated `dispatch-click-public-test-entry` as the MUST `public-dispatch-applies-same-guards`; removed source-narrative phrasing outside Design Decisions; moved the guidelines reference from `references` to `related`; reformatted Design Decisions to the bold three-line form; shortened the frontmatter summary; filled in the Compliance table; renumbered the `log-view-024b` test vector and added vectors for the reuse-identifier and empty-table-at-bottom requirements; defined the "within 2 points of the bottom" geometry precisely; and added the `empty-table-counts-as-at-bottom` requirement promoted from the States table. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to workspace/logs/. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Compliance now cites separation-of-concerns (passed) and unit-test-coverage (passed, LogViewTests); format only. |
| 1.3.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
