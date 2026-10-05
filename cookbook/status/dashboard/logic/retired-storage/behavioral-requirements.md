
**Retired key list**

- **retired-key-list**: The module MUST keep a fixed, read-only list of retired key names (`RETIRED_KEYS`, declared `as const`) that contains exactly `"adh-activity-v1"`.
- **retired-key-semantics**: Each key in the retired list MUST be one that nothing in the app reads or writes, per the module's doc comment: "Each entry below is a RETIRED key: nothing in the app reads or writes it."
- **named-allow-list**: The purge MUST remove only the keys named in the retired list. It MUST NOT clear storage or remove any other key. The test "leaves keys the app still uses alone" checks that `adh-font-scale`, `adh-env-filter` and `adh-healthy-ttl` survive.

**Operation: `purgeRetiredStorage(): void`**

- **purge-signature**: `purgeRetiredStorage` MUST take no arguments and return `void`.
- **purge-removes-key**: When `window` exists and storage is usable, `purgeRetiredStorage` MUST call `window.localStorage.removeItem(key)` once for each key in the retired list, in list order.
- **purge-ssr-noop**: When `typeof window === "undefined"`, `purgeRetiredStorage` MUST return at once without touching storage and without throwing.
- **purge-never-throws**: `purgeRetiredStorage` MUST NOT throw. An exception from `removeItem`, or from reading `window.localStorage` (for example a `SecurityError` in Safari private browsing, a blocked third-party frame or a profile with `localStorage` disabled), MUST be caught for that key.
- **purge-failure-silent**: When removing a key throws, `purgeRetiredStorage` MUST leave the blob in place and move on to the next key without logging, retrying or reporting. The doc comment states the reason: "There is nothing to recover if it fails, and it must never be able to break the board's mount."
- **purge-per-key-isolation**: A failure on one key MUST NOT stop the purge from trying the rest of the retired list, because the `try`/`catch` wraps each key separately.
- **purge-idempotent**: Calling `purgeRetiredStorage` when no retired key is present MUST have no effect and MUST NOT throw. Calling it again after a successful purge MUST have the same effect as calling it once.

**Ordering, concurrency and side effects**

- **purge-synchronous**: `purgeRetiredStorage` MUST run synchronously and finish before it returns. It returns no promise and does not schedule later work.
- **purge-single-threaded**: The purge runs on the JavaScript main thread and cannot interleave with other calls. Calls that overlap in time (for example, several tabs) MUST be safe because each only removes keys, and removing a key that is already gone does nothing.
- **purge-side-effect-scope**: The only side effect of `purgeRetiredStorage` MUST be removing retired keys from `window.localStorage`. It MUST NOT touch `sessionStorage`, cookies, IndexedDB or the network, and it MUST NOT emit events or logs.
- **purge-persistence**: A key that is removed stays removed across reloads, since `localStorage` persists per origin. A key whose removal threw stays in storage until a later call succeeds. The module does not remember past runs, so it tries the purge on every call.

**Retirement lifecycle**

- **retirement-lifecycle**: A retired entry MAY be deleted from the list, and the module MAY be deleted once no retired keys remain, after a release has been out long enough that every live tab has run the purge. This comes from the module's doc comment.

