
- **No screens attached**: The provider returns `[]` (MUST): the set id is the empty string and a set with id `""` and no screens is recorded and persisted like any other.
- **UUID-less and unnamed display**: A snapshot with neither a display UUID nor a localized name (MUST) contributes `unnamed-display`; two such displays yield `unnamed-display+unnamed-display`.
- **Indistinguishable displays**: Two displays with the same identity component (MUST) share one component each in the id and are never paired individually; only the multiset of geometry matters.
- **Frame/visible-frame pooling**: Because frame and visible-frame sizes (and origins) share one multiset (MUST), a change in which one screen's frame size equals another's former visible-frame size and vice versa cancels out and classifies as no change.
- **Spurious notification**: A notification with no geometry or membership change (MUST) produces no persist, log or observer call, but still refreshes the baseline and the current set identity.
- **Change seen first by touch**: A screen change observed by a touch before the notification (MUST) updates the current set identity and records the new set, and the following notification still delivers the change.
- **Membership change with identical frames**: Reconcile's guard (MUST) treats an identical frame list as an identical set; the source asserts membership cannot change without the frame list changing, so a swap between displays with identical frames is not reconciled until the notification arrives.
- **Dock-only change during touch**: A visible-frame-only change (MUST) does not trigger reconcile's snapshot rebuild; the snapshots are refreshed on the next notification.
- **Aging boundary**: A set exactly the maximum age old (MUST) is kept; one second older is dropped at the next persist.
- **Non-persisting aging**: Between persists (MUST) aged-out sets remain in the known-sets list and the known-set-ids collection; they are dropped only at the next persisting upsert.
- **Zero or negative maximum age**: The maximum age is not validated (MUST): with zero, every set other than the current one is dropped at each persist; with a negative value, the current set is also dropped, leaving the current-set query with nothing to return.
- **Corrupt or unwritable storage**: See the open question on storage-failure-signal: load yields `[]` and save is skipped with no signal.
- **Second instance**: A second manager instance on the same storage key (MUST NOT be created) overwrites the first's persisted list on every persist; nothing in the source detects it.
- **Observer mutating observers**: A handler that adds or removes observers during delivery (MUST) does not affect the current delivery, which iterates a copy of the handler collection.
- **Concurrent access**: Not applicable as a race: the manager is confined to a single designated thread, so all calls are serialized.
- **Offline / network**: Not applicable: the component performs no network I/O.
- **Cancellation and timeouts**: Not applicable: every operation is synchronous and bounded by the number of screens and known sets.

