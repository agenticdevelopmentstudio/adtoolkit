
**Decision**: Set identity is display membership only (sorted UUIDs, name fallback), never resolution or position.
**Rationale**: A location is defined by which displays are attached; resolution and arrangement changes on the same desk must keep the same placements, and `identityComponent`'s doc comment makes a UUID-less display's resolution change a resolution change, not a set change.
**Approved**: pending

**Decision**: Geometry is compared as unordered multisets of size and origin keys instead of pairing screens.
**Rationale**: Per the `classifyChange` comment, two indistinguishable UUID-less displays would collide on an identity key and mis-pair, producing spurious classifications. The pooled frame/visible-frame multiset can in theory mask a swap (see Edge Cases); the source accepts that.
**Approved**: pending

**Decision**: The classification baseline (`lastNotifiedSnapshots`) is kept separate from the current snapshots.
**Rationale**: `touchCurrentSet()` may refresh the current snapshots before the notification arrives; diffing against those would report "nothing moved" and no window would be repositioned.
**Approved**: pending

**Decision**: `touchCurrentSet()` reconciles `currentSetID` with the live screens but never classifies or notifies.
**Rationale**: AppKit repositions windows during a reconfiguration and fires `saveFrame` before the notification; without reconciling, a placement lands under the wrong set's key. Notifying there would re-enter `saveFrame` through the reposition handlers.
**Approved**: pending

**Decision**: Touch persistence is throttled to once per 60 seconds, and prune/sort run only on persisting upserts.
**Rationale**: `touchCurrentSet()` runs on every window-drag tick; the in-memory record updates every call, while the 180-day aging scale and array order matter only for what is written.
**Approved**: pending

**Decision**: `knownSetIDs` is maintained alongside `knownSets`.
**Rationale**: `WindowFrameManager.saveFrame` reads it on every drag tick and needs an O(1) membership check without rebuilding a `Set`.
**Approved**: pending

**Decision**: `startObservingScreenChanges()` removes before adding.
**Rationale**: Selector-based `addObserver` adds a second registration instead of replacing the first, which would double-fire; removing first makes re-arming idempotent.
**Approved**: pending

**Decision**: Storage load and save failures are absorbed without a log or a signal to the caller.
**Rationale**: `ScreenSetStorage` declares `loadSets()` and `saveSets(_:)` with no error channel, `SettingsStoreScreenSetStorage` delegates to a settings store whose default value is an empty list, and `ScreenManager` neither logs nor handles a failed load or save. Closing it means deciding whether failures are logged or surfaced and then widening the storage seam.
**Approved**: pending

