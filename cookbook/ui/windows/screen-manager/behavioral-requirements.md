
### Data shapes

- **screen-change-cases**: A screen change MUST be a value type, safe to compare for equality and pass across concurrency boundaries, with exactly three cases: a resolution change, an arrangement change, and a screen-set change carrying a previous set identity and a current set identity.
- **screen-snapshot-fields**: A screen snapshot MUST be a value type, encodable and comparable for equality, holding a fingerprint (the display's identity information), a frame and a visible frame (global, bottom-left-origin desktop coordinates), and a backing scale factor.
- **screen-snapshot-derived**: A screen snapshot MUST expose a display UUID, a localized name and a main-display flag read straight from its fingerprint, so screen identity rules live only in that fingerprint.
- **snapshot-from-screen-info**: Constructing a snapshot from a live screen description MUST copy that screen's fingerprint, frame, visible frame and backing scale factor unchanged.
- **identity-component-uuid**: A snapshot's identity component MUST be its display UUID when one is present.
- **identity-component-name-fallback**: A snapshot without a display UUID MUST use its localized name as its identity component, and the literal `unnamed-display` when the name is also absent.
- **identity-resolution-independent**: A snapshot's identity component MUST NOT include resolution, geometry or main-display status, so a resolution change on a UUID-less display keeps the same set id.
- **screen-set-fields**: A screen set MUST be a value type, encodable and comparable for equality, with an immutable id, a mutable list of screen snapshots (provider order), a first-seen timestamp and a last-seen timestamp.
- **set-identity-derivation**: Computing a set's identity MUST join every member snapshot's identity component, sorted ascending, with `+`.
- **set-identity-order-independent**: Computing a set's identity MUST return the same string for the same snapshots in any enumeration order.
- **set-identity-empty**: Computing a set's identity MUST return the empty string for an empty snapshot list.

### Isolation and ownership

- **single-thread-isolation**: The manager and its storage seam MUST be confined to a single designated thread; every public operation and every observer handler runs there.
- **observer-handler-isolation**: Observer handlers MUST be invoked on that same single designated thread.
- **shared-instance**: The manager MUST provide a process-wide shared instance built with the default initialization arguments.
- **single-owner-precondition**: Callers MUST NOT create a second manager instance on the same storage key in production; a second instance would clobber the real one's state and double-register the change-notification observer. The manager itself does not detect or prevent a second instance.

### Initialization

- **init-snapshots**: Constructing the manager MUST capture the live screen list once and use that list as both the current snapshots and the classification baseline.
- **init-current-set-id**: Constructing the manager MUST set the current set identity to the computed identity of the initial snapshots.
- **init-load-and-prune**: Constructing the manager MUST load the stored sets and drop every set whose last-seen timestamp is more than the maximum age before the current time.
- **init-upsert-persist**: Constructing the manager MUST insert or refresh the current set (see set-upsert rules) and persist the list exactly as a persisting upsert does.
- **init-starts-observing**: Constructing the manager MUST register to observe screen-parameter changes before returning.

### Queries

- **known-sets-order**: After every persisting upsert, the known-sets list MUST be sorted by last-seen, most recent first.
- **known-set-ids-mirror**: The known-set-ids collection MUST contain exactly the ids in the known-sets list, readable in constant time without rebuilding a set on each read.
- **current-set-lookup**: The current-set query MUST return the known-sets entry whose id equals the current set identity, or nothing when there is none.
- **read-only-state**: The known-sets list, the known-set-ids collection and the current set identity MUST be publicly readable and writable only by the manager itself.

### Observers

- **add-observer-token**: Adding an observer MUST store the handler under a freshly generated token and return that token; the caller MAY discard the result.
- **remove-observer**: Removing an observer MUST stop delivery to the handler registered under the token; removing an unknown token MUST be a no-op.
- **observer-delivery-after-update**: Observers MUST be called only after the current set identity and the persisted set list have been updated for the change being delivered.
- **observer-delivery-order**: Observers MUST each be called once per delivered change; the order among observers is unspecified.

### Change processing

- **notification-rearm-idempotent**: Starting to observe screen changes MUST remove any existing registration for this instance before adding one, so calling it repeatedly leaves exactly one registration.
- **notification-drives-processing**: Each screen-parameter-change notification MUST trigger processing of the screen change.
- **process-diff-baseline**: Processing a screen change MUST classify the live snapshots against the snapshots of the last processed notification, not against snapshots refreshed by a touch (see Touch and reconcile).
- **process-updates-state-always**: Processing a screen change MUST update the current snapshots, the current set identity and the classification baseline to the live screens even when classification finds no change.
- **process-spurious-silent**: When classification finds no change, processing MUST NOT upsert, persist, log or notify.
- **process-real-change**: When classification finds a change, processing MUST perform a persisting upsert of the current set, log one info line, then call every observer with that change.

### Classification

- **classify-set-change-first**: Classifying a change MUST return a screen-set change carrying the old and new identities whenever the computed set identity differs between the two lists, regardless of geometry.
- **classify-resolution**: With equal identities, classification MUST return a resolution change when the multiset of sizes differs, where the multiset pools every snapshot's frame size and visible-frame size keyed as `"<width>x<height>"`.
- **classify-arrangement**: With equal identities and equal size multisets, classification MUST return an arrangement change when the multiset of origins differs, where the multiset pools every frame origin and visible-frame origin keyed as `"<x>,<y>"`.
- **classify-no-change**: Classification MUST return no change when identities, size multisets and origin multisets are all equal.
- **classify-no-pairing**: Classification MUST compare geometry as unordered multisets and MUST NOT pair individual screens between the two lists, so indistinguishable displays cannot be mis-paired.
- **classify-visible-frame-counts**: A change to only a screen's visible-frame size (for example a system-reserved area growing) MUST classify as a resolution change.

### Touch and reconcile

- **touch-reconcile-first**: Touching the current set MUST first reconcile the current set identity with the live screens, then upsert the current set.
- **reconcile-cheap-guard**: Reconciling MUST return without rebuilding snapshots when the live screen count equals the current snapshot count and every live frame equals the current snapshot's frame in order; the visible frame is excluded from this comparison.
- **reconcile-refresh**: When the frame lists differ, reconciling MUST rebuild the current snapshots from the live screens and recompute the current set identity.
- **reconcile-no-notify**: Reconciling MUST NOT classify, notify observers, or move the classification baseline, so a later processing pass still classifies against the pre-reconcile baseline.
- **touch-in-memory-every-call**: Every touch MUST update the current set's screens and last-seen timestamp in memory.
- **touch-persist-throttle**: Touching MUST persist only when no touch has persisted yet or at least 60 seconds have passed since the last persisting touch; the first touch after construction always persists.
- **touch-throttle-independent**: The touch throttle MUST track only persists made by touching; persists made during construction and during change processing MUST NOT reset it.

### Set upsert, aging and persistence

- **upsert-existing**: Upserting a set already in the known-sets list MUST replace its screens with the current snapshots and set its last-seen timestamp to the current time, leaving its id and first-seen timestamp unchanged.
- **upsert-new**: Upserting a set not in the known-sets list MUST append a new set with first-seen and last-seen both equal to the current time and add its id to the known-set-ids collection.
- **upsert-prune-on-persist**: A persisting upsert MUST drop every set whose age (current time minus last-seen) exceeds the maximum age (a set exactly the maximum age old is kept), rebuild the known-set-ids collection if any set was dropped, sort by last-seen descending, then persist the whole list.
- **upsert-no-prune-without-persist**: A non-persisting upsert MUST NOT prune, sort or rebuild the known-set-ids collection.
- **returning-set-keeps-first-seen**: Returning to a previously seen set MUST keep its original first-seen timestamp and bump only its last-seen timestamp.
- **storage-settings-blob**: The settings-backed storage MUST store the whole set list as one encoded value under a single key (default `ScreenSets`) in the settings store's non-secure provider, with an empty list as the default when nothing is stored.
- **storage-failure-signal**: The storage seam does not report load or save failures: the protocol has no error channel, and with the default settings-backed provider an undecodable stored blob loads as an empty list and an unencodable list is silently not written. A corrupt blob is therefore replaced, without any log, at the next persist, erasing every known set and the per-set placements keyed to it.

### Side effects

- **log-on-change**: Each delivered change MUST log exactly one info-level line of the form `ScreenManager: <change> → set '<currentSetID>'`, with both values marked public.
- **no-other-side-effects**: The manager MUST have no side effects beyond the change-notification registration, storage calls, the change log line and observer calls: no network, no files of its own, no timers.
- **no-cancellation-or-timeout**: Every operation MUST run synchronously to completion on that single designated thread; there is no cancellation, timeout or retry.

