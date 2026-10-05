
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe for NotesAndHistory, covering independent per-section loading/empty/populated states, source-fidelity edge cases, and two open accessibility/error-handling questions for review. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: retitled to a human-readable form; added a Types section documenting `AdminNote`/`HistoryEntry` fields and date-formatting ownership; tied the notes/history list-rendering requirements and test vectors to their exact separators; reworded the duplicate-`id` edge case as a caller precondition instead of a MUST NOT; externalized the five hardcoded strings as localization keys; made test vector 008 a concrete fetch/XHR stub; reordered Platform Notes and filled in WinUI padding, border, and token mappings; bolded Design Decision labels and added one for the fixed heading level; replaced the Compliance table's non-catalog check citations with real cookbook compliance checks and sourced statuses; and switched `created`/`modified` to bare ISO dates. |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to adh/hub/admin/. |
| 1.2.1 | 2026-10-04 | Mike Fullerton | Add separation-of-concerns and unit-test-coverage compliance. |
| 1.2.2 | 2026-10-04 | Mike Fullerton | Matches its type's shape: required fields, title heading, and only the type's own sections. |
