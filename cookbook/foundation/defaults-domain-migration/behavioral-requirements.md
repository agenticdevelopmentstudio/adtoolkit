
- **copy-when-new-empty**: The migration MUST copy every key of the legacy domain into the new domain when the new domain holds nothing and the legacy domain holds at least one key, and MUST then report that settings were copied.
- **never-overwrite**: The migration MUST NOT change the new domain when it already holds any setting, and MUST report that nothing was copied.
- **nothing-to-copy**: The migration MUST report that nothing was copied, and change nothing, when the legacy domain is absent or empty.
- **same-domain-noop**: The migration MUST do nothing when the legacy and new domain names are equal.
- **legacy-left-in-place**: The migration MUST NOT delete or modify the legacy domain.
- **idempotent**: Running the migration again after a successful copy MUST do nothing and report that nothing was copied, because the new domain is now non-empty.
- **store-injectable**: The preferences store MUST be an optional parameter defaulting to the standard user preferences, so the migration is testable against an isolated store.
- **result-discardable**: The returned flag MUST be optional to use: a caller that only wants the side effect may ignore it.

