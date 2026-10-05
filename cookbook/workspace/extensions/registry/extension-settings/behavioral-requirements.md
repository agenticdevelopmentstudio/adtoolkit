
- **disabled-identifiers-key**: The disabled-extensions setting's storage key MUST equal the string `"extensions.disabledIdentifiers"`.
- **disabled-identifiers-default**: The disabled-extensions setting's default value MUST be an empty set of strings.
- **enabled-by-default**: An identifier that has never been added to the stored set MUST be treated as enabled, because the set records disabled identifiers rather than enabled ones — deliberately, so a newly added extension needs no migration.
- **thread-confined-access**: The disabled-extensions setting MUST be read and written only from a single, serialized execution context, so that no two accesses interleave.
- **value-round-trip**: Reading the setting's current value MUST return the most recently written set of identifiers for that key, and writing a new value MUST persist it so a later read returns it.
- **removal-reverts-to-default**: Removing the setting's stored value MUST cause a subsequent read of its value to return the default value (an empty set).
- **existence-check**: Checking whether a value has been explicitly stored for the setting MUST answer true only once a value has been explicitly stored under its key, and false before any write and again after removal.
- **json-encoded-persistence**: Because a set of strings is not one of the primitive types the underlying storage mechanism holds natively, a write to the setting MUST be serialized into a portable encoded form (for example JSON) and stored as an opaque blob under its key, and a read MUST decode that blob back into a set of strings.
- **not-secure**: The setting MUST be stored through the ordinary, non-secure settings storage path, never a secure, credential-store-backed one.
- **corrupt-data-falls-back-to-default**: If the blob stored under the setting's key cannot be decoded back into a set of strings, a read MUST return the default value (an empty set) rather than throwing or crashing.
- **change-notification**: A write to the setting's value MUST update any observable projection of its current value synchronously, within the same call, before the write's statement returns.
- **no-identifier-validation**: The setting MUST accept and store any string as a member of the set. It performs no check that a stored identifier names an installed or known extension; validating and reconciling identifiers against installed extensions is a caller's responsibility, not this setting's.
- **case-sensitive-storage**: The set MUST store identifier strings exactly as given, applying no case-folding of its own. Membership is exact-string equality, so a differently-cased spelling of the same identifier is a distinct member unless a caller folds it before writing.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

