
### Reopen-on-Launch Policy

- **policy-cases**: The reopen-on-launch policy MUST have exactly three states, in this order: `useSystem`, `always`, `never`.
- **policy-raw-values**: Each state's persisted string value MUST equal its name: `"useSystem"`, `"always"`, `"never"`.
- **policy-case-iterable**: The complete, ordered list of policy states MUST contain exactly 3 elements, in the order given in policy-cases (`useSystem`, `always`, `never`).
- **policy-round-trips-as-string**: The policy MUST serialize to and deserialize from its raw string value, so a stored value round-trips only for the three raw values listed in policy-raw-values.
- **policy-safe-to-share**: The policy MUST be safe to read or pass across concurrent contexts without synchronization; it carries no mutable state.
- **policy-equatable**: Two policy values MUST be equal if and only if they are the same state.
- **use-system-follows-default**: The decision function on `useSystem` MUST return the system-default argument unchanged (`true` → `true`, `false` → `false`).
- **always-reopens**: The decision function on `always` MUST return `true` regardless of the system-default argument.
- **never-reopens**: The decision function on `never` MUST return `false` regardless of the system-default argument.
- **reopen-decision-pure**: The decision function MUST be a pure function of the receiver and its argument; it MUST NOT read any preference, including the platform's keep-windows-on-quit preference, itself. The caller supplies the platform value (see Platform Notes for which consumer does this and how).
- **display-name-use-system**: The display name for `useSystem` MUST be `"Use System Setting"`.
- **display-name-always**: The display name for `always` MUST be `"Always"`.
- **display-name-never**: The display name for `never` MUST be `"Never"`.
- **system-default-key**: The system-default accessor MUST return the boolean value of the platform's keep-windows-on-quit preference, searched from the app's own preference domain and then the platform-global domain.
- **system-default-absent**: The system-default accessor MUST return `false` when the keep-windows-on-quit preference is absent from every searched domain.
- **system-default-inverted-label**: The system-default accessor MUST report the preference's stored value as it is stored. Where the platform's own on-screen control for this preference has an inverted sense from the stored value (see Platform Notes), the accessor still reports the raw stored value, never the checkbox's sense.
- **system-default-uncached**: The system-default accessor MUST be re-evaluated on every access; it MUST NOT cache the value.
- **system-default-read-only**: The reopen-on-launch policy MUST NOT write the keep-windows-on-quit preference or any other preference; its only side effect is the read described in system-default-key.

### Persisted Settings

- **recent-count-key**: The recent-window-count preference MUST persist under the key `"recentWindowsCount"`.
- **recent-count-default**: The recent-window-count preference MUST read as `10` when no value is stored under its key.
- **recent-count-storage-form**: Because its value is an integer, the preference store MUST persist recent-window-count as a native integer, not JSON-encoded data.
- **recent-count-range**: A count within the settings UI's range is a caller precondition. The recent-window-count preference MUST accept any integer, including negative values; the only bound enforced is in the settings UI (a range of 0 to 50), so a programmatic write of a negative or very large count reaches the mirrored platform limit unchanged.
- **policy-setting-key**: The reopen-on-launch preference MUST persist under the key `"reopenOnLaunchPolicy"`.
- **policy-setting-default**: The reopen-on-launch preference MUST read as `useSystem` when no value is stored under its key.
- **policy-setting-storage-form**: Because the policy is not a natively stored primitive, the preference store MUST persist it as JSON-encoded data of its raw string value.
- **policy-setting-decode-fallback**: When the data stored under `"reopenOnLaunchPolicy"` fails to decode as a policy value, reading the preference MUST return the default `useSystem`; the preference store discards the decode failure without logging it.
- **settings-not-secure**: Both preferences MUST be declared non-secure, so they route through the store's ordinary preference path, never a secure-storage path (such as a keychain).
- **settings-single-threaded-access**: Both preferences MUST be accessed only from a single, consistent execution context (the UI thread); a read or write from any other context MUST be rejected at compile time by the platform's concurrency-checking rules.
- **settings-change-notifying**: Each preference MUST publish its current value through a change-notifying mechanism, updating whenever the backing store emits a change for the preference's key.
- **settings-lazy-binding**: Each preference MUST bind to the shared preference store when first accessed; from that point it reads the current value from, and subscribes to changes on, that store.

### Consumer Contract

- **recent-count-mirror**: Applying the recent-window-count preference to the platform MUST write its current value to the platform's own recent-documents limit.
- **recent-count-mirror-live**: After the window manager is constructed, a change to the recent-window-count preference MUST be mirrored to the platform's recent-documents limit on a later turn of the main run loop with no explicit call; the manager subscribes to the preference's value changes.
- **policy-consumed-for-documents-only**: The reopen-on-launch preference MUST govern only the reopen of recent document windows; project (workspace) windows MUST NOT consult it.
- **no-network-no-files**: The policy and the preferences MUST NOT perform network access, file I/O beyond the preference-store reads and writes described above, process launches, or notification posting.
- **no-errors**: An operation described above MUST NOT throw or return an error; every read yields a value (stored, or the default).

