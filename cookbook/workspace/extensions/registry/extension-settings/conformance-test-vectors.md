
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| extension-settings-001 | disabled-identifiers-key | Read the setting's storage key | equals the string `"extensions.disabledIdentifiers"` |
| extension-settings-002 | disabled-identifiers-default | Read the setting's default value | is empty |
| extension-settings-003 | enabled-by-default, value-round-trip | With no prior write in this run, read the setting's current value | equals the empty set, since nothing has been stored yet and a read falls back to the default value |
| extension-settings-004 | value-round-trip | Write `{"acme.foo"}` as the value, then read the value | equals `{"acme.foo"}` |
| extension-settings-005 | value-round-trip | Write `{"acme.foo", "acme.bar"}`, then write `{"acme.bar"}`, then read the value | equals `{"acme.bar"}` — the second write replaces the stored set rather than merging into it |
| extension-settings-006 | removal-reverts-to-default | Write `{"acme.foo"}`, remove the stored value, then read the value | equals the empty set (the default value) |
| extension-settings-007 | existence-check | Before any write, check whether a value has been stored; then write `{"acme.foo"}` and check again | first check answers false; second check answers true |
| extension-settings-008 | existence-check, removal-reverts-to-default | Write `{"acme.foo"}`, remove the stored value, then check whether a value has been stored | answers false |
| extension-settings-009 | json-encoded-persistence | Write `{"acme.foo", "acme.bar"}`, then inspect the raw object the underlying storage holds under the setting's key | the stored object is an opaque encoded blob, not a native array or string; decoding that blob as a set of strings yields `{"acme.foo", "acme.bar"}` |
| extension-settings-010 | not-secure | Read whether the setting is flagged secure | answers false, confirming writes route through the non-secure storage path and never a secure, credential-store-backed one |
| extension-settings-011 | corrupt-data-falls-back-to-default | Store a payload that does not decode as a set of strings (for example an object shaped `{"not":"a set"}`) directly under the setting's key in the underlying storage, then read the value | returns the empty set (the default value), with no thrown error |
| extension-settings-012 | change-notification | Observe the setting's current value, then write `{"acme.foo"}` | the observer sees `{"acme.foo"}` synchronously, before the statement that performed the write returns |
| extension-settings-013 | no-identifier-validation | Write `{"not-a-real-extension-id", ""}` (an unregistered identifier and an empty string) | both are accepted and persisted verbatim; a subsequent read returns exactly `{"not-a-real-extension-id", ""}`, with no error and no filtering |
| extension-settings-014 | case-sensitive-storage | Write `{"Acme.Foo"}`, then check whether the value contains `"acme.foo"` | answers false — the differently-cased spelling is not treated as the same member |
| extension-settings-015 | thread-confined-access | Attempt to read the setting's value from outside its confined execution context, with no synchronization | is refused (on a platform that enforces this statically, this is a compile-time error) |
| extension-settings-016 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

