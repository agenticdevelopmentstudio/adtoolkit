
**Decision**: `WindowManager` is a thin coordinator over two sub-services (`frames`, `registry`) instead of one type that does everything.
**Rationale**: The type doc comment directs most callers to a sub-service (`frames.restoreFrame(...)`, `registry.controller(forID:)`); frame persistence and live lookup change independently.
**Approved**: pending

**Decision**: An omitted `screenManager` resolves to `ScreenManager.shared`, never a new instance.
**Rationale**: Per the initializer comment, a second `ScreenManager` on the same persistence key would clobber the real one's state and double-register the notification observer.
**Approved**: pending

**Decision**: Termination is latched with a one-way `isTerminating` flag read by `SingleWindowController.windowWillClose(_:)`.
**Rationale**: AppKit sends `windowWillClose:` to still-visible windows after `applicationWillTerminate`; persisting hidden there stopped windows left open from reopening (`WindowManagerTerminationTests`).
**Approved**: pending

**Decision**: Restore is driven by registered factories (`register(id:make:)`) rather than hosts hand-constructing controllers, and whether a window reopens is its own `WindowSpec.behavior`, never the host's registration.
**Rationale**: The host only says how to build each window; a second host-side list of "restorable" windows is one more thing to fall out of step. Only windows saved as visible are built, so registering every window costs nothing at launch. The missing-factory error log surfaces the remaining wiring gap loudly, once.
**Approved**: pending

**Decision**: The recent-documents cap is set by writing the `NSRecentDocumentsLimit` user default.
**Rationale**: `NSDocumentController.maximumRecentDocumentCount` is read-only; the default is the public knob and avoids subclassing `NSDocumentController`.
**Approved**: pending

**Decision**: When reopen is disabled the manager actively closes document windows AppKit restored.
**Rationale**: The comment calls this overriding AppKit's own state restoration; it closes through the window controller so the controller, not just the window, is torn down.
**Approved**: pending

**Decision**: The registry holds weak references and never prunes dead entries.
**Rationale**: A dropped controller "naturally disappears" from lookups; the number of window IDs is small and bounded, so dead boxes cost little.
**Approved**: pending

**Decision**: `WindowStateNamespace` is a process-wide lock-guarded static read at key-composition time, not an injected dependency.
**Rationale**: `WindowManager.shared` builds its storage on first access from anywhere, so an injected namespace would miss the storages that matter; the lock (not `@MainActor`) lets non-main-actor code compose the same keys.
**Approved**: pending

**Decision**: The namespace is an 8-hex-character SHA-256 prefix of the bundle path, empty by default.
**Rationale**: The bundle path is the identity that differs between two copies (bundle ID is shared, pid changes each launch); hashing keeps keys short and keeps directory names out of preferences; the empty default preserves every existing installation's layout.
**Approved**: pending

**Decision**: Both storage implementations use the same key formats and encodings (JSON state, native boolean visibility).
**Rationale**: Swapping `SettingsStoreWindowStateStorage` in over a UserDefaults-backed store reads existing state without migration, per its doc comment.
**Approved**: pending

**Decision**: `WindowScreenshot` resolves the deprecated `CGWindowListCreateImage` through `dlsym`.
**Rationale**: ScreenCaptureKit is async and requires Screen Recording permission even for own windows; the legacy symbol works without permission, and runtime resolution avoids the deprecation warning while degrading to `nil` if the symbol disappears.
**Approved**: pending

**Decision**: Non-document single windows are not recorded in recents yet.
**Rationale**: The source marks this intentional, pending `WindowRecentsTracker` in a follow-up slice.
**Approved**: pending

**Decision**: A recent document that fails to reopen on launch is neither logged, presented nor pruned from recents.
**Rationale**: `WindowManager.reopenRecentsOnLaunch()` passes an empty `{ _, _, _ in }` completion handler to `NSDocumentController.openDocument(withContentsOf:display:)`, discarding the error. Closing it means deciding whether failures are logged, shown to the user or removed from the recents list.
**Approved**: pending

**Decision**: Window-state codec failures are absorbed without a log or a signal to the caller.
**Rationale**: `UserDefaultsWindowStateStorage` uses `try?` for both decode and encode, and `SettingsStoreWindowStateStorage` delegates to a settings store that absorbs the same failures; neither reports anything. Closing it means deciding whether codec failures are logged or surfaced and then widening the `WindowStateStorage` protocol.
**Approved**: pending

