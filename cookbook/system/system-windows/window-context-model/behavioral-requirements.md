
### Shared conformances

- **value-semantics**: All five types MUST be value types; copying a value MUST NOT share mutable state with the original.
- **concurrency-safe-by-value**: All five types MUST be safe to pass across concurrent execution contexts without synchronization, since each is an immutable-or-copied value with no shared mutable state.
- **serializable-by-field-name**: All five types MUST be serializable to and from a structured format, with each stored field encoding under a key equal to its field name, and no custom key mapping, versioning or default-on-missing logic.
- **value-equality**: All five types MUST support equality comparison, such that two values are equal if and only if every stored field is equal (including the last-seen and created-at timestamps).
- **computed-not-encoded**: The derived values — the display name on match strategy, the live flag on window snapshot, and the live-window count on window context — MUST NOT appear in encoded output.
- **optional-omitted**: An optional stored field whose value is absent (the window identifier on window snapshot, the last-focused window identifier on window context) MUST be omitted from encoded output, and a missing key MUST decode as absent.
- **missing-key-throws**: Decoding any of the four record types MUST fail with a decoding error when a required field's key is absent; no field has a decode-time default.
- **frame-encoding**: Rectangle fields (the frame on window info, the saved frame on window snapshot) MUST encode as a nested array `[[x, y], [width, height]]`.
- **no-side-effects**: The operations of the five types MUST NOT perform file I/O, network access, logging, process launches or notification posting; every operation is a pure computation or an in-memory mutation of the value itself.
- **no-errors**: An operation MUST NOT throw or return an error; lookups signal "not found" with an absent value or `false`.

### Match Strategy

- **strategy-cases**: Match strategy MUST declare exactly four values, in this order: `appAndTitleExact`, `appAndTitleSubstring`, `appAndTitleRegex`, `appOnly`.
- **strategy-raw-values**: Each value MUST use its name as its string raw form (`"appAndTitleExact"`, `"appAndTitleSubstring"`, `"appAndTitleRegex"`, `"appOnly"`), and MUST encode and decode as that string.
- **strategy-value-list**: The complete list of match-strategy values MUST contain exactly 4 elements, in declaration order.
- **strategy-unknown-raw**: Decoding a string that is not one of the four raw values MUST fail with a data-corrupted decoding error; constructing a match-strategy value from such a string MUST return no value.
- **display-name-exact**: The display name for `appAndTitleExact` MUST be `"Exact"`.
- **display-name-substring**: The display name for `appAndTitleSubstring` MUST be `"Substring"`.
- **display-name-regex**: The display name for `appAndTitleRegex` MUST be `"Regex"`.
- **display-name-app-only**: The display name for `appOnly` MUST be `"App Only"`.
- **strategy-semantics-declared**: Each value's meaning is a contract implemented by the window matcher's scoring operation: `appAndTitleExact` is app plus exact title match, `appAndTitleSubstring` is app plus title containment, `appAndTitleRegex` is app plus a regular-expression test of the live title, and `appOnly` is app alone, ignoring the title. Match strategy itself MUST NOT perform any matching.

### Window Fingerprint

- **fingerprint-fields**: Window fingerprint MUST store exactly `app`, `titlePattern`, `matchStrategy` and `display`, respectively an app name, a title pattern, a match strategy and a display identifier.
- **fingerprint-immutable**: Every stored field of window fingerprint MUST be immutable; a changed fingerprint is a new value.
- **fingerprint-init-verbatim**: Constructing a window fingerprint MUST store each argument unchanged, with no trimming, case folding or validation; all four fields are required and have no defaults.
- **title-pattern-meaning**: `titlePattern` MUST hold the pattern a heuristic extracted from the title (for example `"MyProject"` from `"MyProject — Notes.md"`) or, when no heuristic applies, the full title; for the `appAndTitleRegex` strategy it MUST hold the regular-expression source, not a captured value.
- **regex-not-validated**: A `titlePattern` that is not a compilable regular expression is a value the fingerprint MUST accept; compiling and rejecting it belongs to the window matcher, which logs the compile error and scores the window 0.
- **display-tie-breaker**: `display` MUST hold the display identifier the window was on when fingerprinted; it is a tie-breaker when multiple candidate windows match (the window matcher adds a 10-point bonus when a live window's `display` equals it).

### Window Info

- **info-fields**: Window info MUST store exactly `id` (the window identifier assigned by the system), `app`, `pid` (the owning process identifier), `title`, `frame`, `display`, `isOnScreen` and `layer`, all immutable.
- **info-identity**: Window info's `id` MUST serve as its identity, so two info values for the same window share an `id` even when other fields differ.
- **info-init-verbatim**: Constructing a window info value MUST store each argument unchanged; all eight fields are required.
- **info-empty-title**: `title` MUST accept an empty string; the title may be empty for some windows.
- **with-title-copy**: The title-backfill operation MUST return a new window info value whose `title` is the argument and whose other seven fields equal the original's.
- **with-title-non-mutating**: The title-backfill operation MUST NOT modify the original value.
- **with-title-purpose**: The title-backfill operation exists to backfill titles obtained through the accessibility layer when the system's window list omits them because the screen-capture permission has not been granted; it MUST accept any string, including an empty one, without validation.

### Window Snapshot

- **snapshot-fields**: Window snapshot MUST store `id` (a unique identifier), `windowID` (an optional live window identifier), `fingerprint`, `savedFrame`, `display`, `app`, `title` and `lastSeen`.
- **snapshot-immutable-identity**: `id`, `fingerprint` and `app` MUST be immutable; `windowID`, `savedFrame`, `display`, `title` and `lastSeen` MUST be mutable.
- **snapshot-stable-id**: `id` MUST be a stable identifier that is not the live window identifier and persists across restarts.
- **snapshot-id-default**: Constructing a window snapshot MUST generate a fresh random unique identifier for `id` when the caller omits it.
- **snapshot-window-id-default**: Constructing a window snapshot MUST default `windowID` to absent when the caller omits it.
- **snapshot-last-seen-default**: Constructing a window snapshot MUST default `lastSeen` to the current date and time when the caller omits it.
- **snapshot-is-live**: The live flag MUST be `true` if and only if `windowID` is present.
- **snapshot-dormant**: A snapshot with `windowID` absent MUST represent the dormant state: the window has been closed or the app has quit.
- **snapshot-display-independent**: `display` (the restore target) and the fingerprint's own `display` (the display at fingerprint time) MUST be stored independently; changing the snapshot's `display` MUST NOT change the fingerprint's `display`.
- **snapshot-app-duplicated**: `app` and the fingerprint's own `app` MUST be stored independently; construction MUST NOT check that they are equal (the context manager passes the same live window's `app` to both).

### Window Context

- **context-fields**: Window context MUST store `id`, `name`, `color`, `windowSnapshots` (a list of window snapshots), `lastFocusedWindowID` (an optional identifier) and `createdAt`.
- **context-immutable-identity**: `id` and `createdAt` MUST be immutable; `name`, `color`, `windowSnapshots` and `lastFocusedWindowID` MUST be mutable.
- **context-init-defaults**: Constructing a window context MUST default `id` to a fresh unique identifier, `color` to `"#007AFF"`, `windowSnapshots` to an empty list, `lastFocusedWindowID` to absent and `createdAt` to the current date and time; `name` is required.
- **context-color-format**: `color` is a caller-supplied hex string that includes the leading `#` (for example `"#FF5733"`); window context MUST store it verbatim without parsing or validating it.
- **context-name-verbatim**: `name` MUST be stored verbatim; window context MUST NOT reject an empty or duplicate name.
- **add-window-append**: Adding a window snapshot MUST append it to the end of `windowSnapshots` when no existing snapshot has the same `id`.
- **add-window-replace**: Adding a window snapshot MUST replace, at the same position, the first existing snapshot whose `id` equals the new one's `id`, leaving the list's count and order unchanged.
- **add-window-no-window-id-dedupe**: Adding a window snapshot MUST NOT check `windowID`; two snapshots with different `id` values and the same `windowID` MAY coexist in one context. Uniqueness of a live window across and within contexts is enforced by the caller, the context manager's add-window operation, which reports an already-assigned error for another context and updates the existing snapshot for the same one.
- **add-window-keeps-focus**: Adding a window snapshot MUST NOT change `lastFocusedWindowID`.
- **remove-by-id**: Removing a window snapshot by `id` MUST remove the first snapshot whose `id` equals the argument and return it.
- **remove-by-id-missing**: Removing a window snapshot by `id` MUST return no value and leave the context unchanged when no snapshot has that `id`.
- **remove-by-id-clears-focus**: Removing a window snapshot by `id` MUST clear `lastFocusedWindowID` when it equals the removed snapshot's `id`, and MUST leave it unchanged otherwise.
- **remove-by-window-id**: Removing a window snapshot by `windowID` MUST remove the first snapshot (in list order) whose `windowID` equals the argument and return it; later snapshots with the same `windowID` MUST remain.
- **remove-by-window-id-missing**: Removing a window snapshot by `windowID` MUST return no value and leave the context unchanged when no snapshot has that `windowID`; a dormant snapshot (`windowID` absent) MUST never match.
- **remove-by-window-id-clears-focus**: Removing a window snapshot by `windowID` MUST clear `lastFocusedWindowID` when it equals the removed snapshot's `id`.
- **remove-discardable**: Both remove operations MUST be usable without the caller using the returned value.
- **snapshot-lookup**: Looking up a snapshot by `id` MUST return the first snapshot whose `id` equals the argument, or no value when none does, without mutating the context.
- **update-by-id**: Updating a snapshot by `id` MUST invoke the update closure exactly once with the first snapshot whose `id` matches, allow it to modify that snapshot directly, write the changes back in place, and return `true`.
- **update-by-id-missing**: Updating a snapshot by `id` MUST return `false` without invoking the update closure when no snapshot has that `id`.
- **update-by-window-id**: Updating a snapshot by `windowID` MUST invoke the update closure exactly once with the first snapshot whose `windowID` matches, write the changes back in place, and return `true`; it MUST return `false` without invoking the closure when none matches.
- **update-scope**: The update closure MUST be able to change only a snapshot's mutable fields (`windowID`, `savedFrame`, `display`, `title`, `lastSeen`); `id`, `fingerprint` and `app` are immutable, and updating a snapshot MUST NOT reorder `windowSnapshots` or touch `lastFocusedWindowID`.
- **update-closure-synchronous**: The update closure MUST run synchronously; it completes before the update operation returns.
- **live-window-count**: The live-window count MUST return the number of snapshots whose live flag is `true`.
- **focus-not-validated**: Window context MUST NOT check that `lastFocusedWindowID` names a snapshot in `windowSnapshots`; only the two remove operations clear it.

### Concurrency and persistence

- **concurrency-by-value**: The types MUST NOT carry any built-in synchronization mechanism (locks or similar); a window context is mutated by producing an updated copy held by a single owner, and preventing concurrent mutation of one stored value is the caller's and the platform's responsibility, not the type's.
- **persistence-external**: The types MUST NOT persist themselves. The context store encodes a context as pretty-printed JSON with keys in sorted order and dates in ISO-8601 form, and decodes with a matching ISO-8601 date format; without that configuration, date fields would encode as a platform-specific numeric offset instead.

