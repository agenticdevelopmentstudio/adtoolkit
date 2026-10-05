
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| defaults-domain-migration-001 | copy-when-new-empty | Legacy domain holds `{theme: dark}`; new domain is empty. | The new domain holds `{theme: dark}`; the call reports true (test: testCopiesLegacySettingsIntoAnEmptyDomain). |
| defaults-domain-migration-002 | never-overwrite | Legacy holds `{theme: dark}`; new holds `{theme: light}`. | The new domain is unchanged; the call reports false (test: testNeverOverwritesADomainThatAlreadyHoldsSettings). |
| defaults-domain-migration-003 | nothing-to-copy | Legacy domain is absent. | Nothing changes; reports false (test: testDoesNothingWithoutLegacySettings). |
| defaults-domain-migration-004 | idempotent | Run the migration twice with a populated legacy and an empty new domain. | First call reports true; second reports false and changes nothing (test: testIsIdempotent). |
| defaults-domain-migration-005 | legacy-left-in-place | After a successful copy, read the legacy domain. | It still holds its original keys. |
| defaults-domain-migration-006 | same-domain-noop | Migrate from `com.example.app` to `com.example.app`. | Reports false; nothing changes. |
| defaults-domain-migration-007 | nothing-to-copy | Legacy domain exists but holds no keys. | Reports false; the new domain stays empty. |

