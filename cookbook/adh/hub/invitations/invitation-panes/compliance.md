
| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy & Data |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | failed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on this file's own sections: Accessibility documents that
`passes-required-aria-label` is this file's one direct, forced contribution
while every other interactive/semantic element is delegated (partial); Privacy
and Logging show the file collects, stores, transmits, and logs nothing of its
own (passed); Localization shows every user-facing string is hardcoded with no
i18n key or lookup (failed); Overview shows data-fetching, persistence, and the
notes/history UI are all pushed to the caller, leaving this file pure
presentation (passed); and Edge Cases/Design Decisions show the `onSend`
rejection reason is discarded via `() => undefined` with no log or rethrow
(failed, see `reports-send-rejection-reason`).

`unit-test-coverage` is `partial`: no test file for `invitation-panes.tsx` exists under the `adh-ui` test targets (`packages/web/packages/adh-ui/src/__tests__/` holds tests for other blocks only); the only coverage is indirect, through `packages/web/packages/features/ecosystems/src/EcosystemInvitationPanes.test.tsx`, which renders the three panes via their ecosystem wrappers and pins the header placement above the scrollable grid, so the `onSend` rejection handling and the `aria-label` values are untested.

