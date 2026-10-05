
| ID | Requirement | Given | When | Then |
|---|---|---|---|---|
| single-window-controller-001 | single-thread-isolation | any instance | a method is invoked while already confined to the single designated thread | the assertion succeeds; no isolation violation occurs |
| single-window-controller-002 | init-argument-storage | a window ID and content | the controller is constructed | both are stored for later use when the window is built, with no validation of the window ID's emptiness |
| single-window-controller-003 | no-deserialization-init | any | archive-based construction is invoked | a fatal/unavailable-API error occurs, not a working instance |
| single-window-controller-004 | default-size | a subclass overriding the default size | no persisted frame exists | building the window uses the overridden size |
| single-window-controller-005 | forces-window-front, forces-front-ordering | a subclass with the forces-front flag set | the window is shown | the standard show behavior runs first, then the window is additionally forced fully to front, pulling it above other applications' windows |
| single-window-controller-006 | window-title | a subclass overriding the title property | the window is built | the built window's title equals the overridden value |
| single-window-controller-007 | default-content-rect | a subclass overriding the default content rect, no persisted frame | the window is built | the window is created with the overridden rect |
| single-window-controller-008 | window-style-mask | a subclass overriding the style options to request a HUD appearance | the window is built | a utility-style window is constructed instead of a standard window |
| single-window-controller-009 | min-size | a subclass overriding the minimum size | the window is built | the built window's minimum size equals the overridden value |
| single-window-controller-010 | configure-window-hook | a subclass overriding the configuration hook | the window is built | the override is invoked exactly once with the fully assembled window |
| single-window-controller-011 | lazy-window-build | a freshly constructed controller | construction completes but the window is not accessed | no window has been constructed |
| single-window-controller-012 | panel-selection | the style options request a utility appearance | the window is built | the constructed object is a utility-style window |
| single-window-controller-013 | window-construction | default configuration | the window is built | the window's content rect, style options, backing, and defer flag match the documented values |
| single-window-controller-014 | title-on-build | the title property overridden to `"Example"` | the window is built | the window's title equals `"Example"` |
| single-window-controller-015 | content-view-controller-on-build | content supplied at construction | the window is built | the window's content is that instance |
| single-window-controller-016 | min-size-on-build | the minimum-size property overridden | the window is built | the window's minimum size equals the overridden value |
| single-window-controller-017 | accessibility-identifier | window ID equals `"mySettings"` | the window is built | the window's accessibility identifier equals the slug of `"mySettings"` |
| single-window-controller-018 | toolbar-button-mask | a window spec registered for the window ID with the toolbar-buttons setting limited to close | the window is built | only the close button is visible; miniaturize and zoom are hidden |
| single-window-controller-019 | toolbar-button-mask-default | no window spec registered for the window ID | the window is built | all three standard buttons keep the platform's default visibility |
| single-window-controller-020 | build-sequence | a persisted frame for the window ID | the window is built | the frame is restored and applied before the delegate is set (so the restore does not itself trigger move/resize bookkeeping), and the configuration hook has already run by this point |
| single-window-controller-021 | build-sequence | any | the window is built | the window property is assigned right after the content is set — before the toolbar button mask, HUD chrome, the configuration hook, frame restore, and delegate assignment all run — and the configuration hook is invoked exactly once, after the toolbar/HUD chrome steps and before the frame restore |
| single-window-controller-022 | registry-registration | any window ID | the controller is constructed | the window registry's lookup for that window ID returns this instance, even before the window is ever built |
| single-window-controller-023 | registry-registration-empty-id | window ID is empty | the controller is constructed | no crash occurs; the registry has no entry for the empty ID |
| single-window-controller-024 | quiet-presentation | the forces-front flag is not set | the window is shown | the window is sunk behind the desktop and ordered back rather than being pulled to the front; it remains visible and keeps its restored frame |
| single-window-controller-025 | show-window-convenience | any | the parameterless show-window operation is called | it behaves identically to showing with no sender |
| single-window-controller-026 | visibility-persist-on-show | the window's spec has visibility persistence enabled | the window is shown | the window frame manager records the window visible |
| single-window-controller-027 | dismiss-method | a visible window | dismiss is called | the window closes |
| single-window-controller-028 | visibility-persist-on-dismiss | the window's spec has visibility persistence enabled | dismiss is called | the window frame manager records the window hidden |
| single-window-controller-029 | is-visible | no window built yet | the visibility flag is read | it returns false |
| single-window-controller-030 | content-fit | a built window | the fit-to-content operation is called with a new size | the window's frame changes to accommodate the content size, anchored per the current anchor |
| single-window-controller-031 | content-fit-bail | a prior fit already applied for a given size/anchor pair | the fit-to-content operation is called again with the same size | the frame is not re-applied |
| single-window-controller-032 | fit-anchor-stability | two consecutive fits with different sizes, the window unmoved between them | the second fit runs | the second fit anchors to the same edge the first fit chose, rather than recomputing the anchor from the window's current frame |
| single-window-controller-033 | reentrant-fit-guard | the fit-to-content operation is applying a computed frame | that frame change triggers a resize callback | the resize does not trigger a nested call back into the content-refit machinery |
| single-window-controller-034 | content-size-provider | the content-size provider set to a callback returning a fixed size | the refit operation is called | the fit-to-content operation is invoked with that size and the window's frame changes to match |
| single-window-controller-035 | content-refit-gate | no content-size provider set | the refit operation is called | no frame change occurs |
| single-window-controller-036 | move-refit-debounce | a provider set, then two moves in quick succession | the second move's callback fires | only one refit occurs, timed 200ms after the second move (the first move's pending wait is canceled and restarted, not stacked) |
| single-window-controller-037 | refit-drag-deferral | a scheduled refit fires while a mouse button is held | the refit runs | the refit reschedules itself instead of applying immediately |
| single-window-controller-038 | move-triggers-refit | the content-size provider set | a window-move callback fires | a refit is scheduled; with no provider set, the same move schedules no refit |
| single-window-controller-039 | frame-persist-on-move | the window's spec has frame persistence enabled | a window-move callback fires | the window frame manager is called with the new frame |
| single-window-controller-040 | frame-persist-on-resize | the window's spec has frame persistence enabled | a window-resize callback fires | the window frame manager is called with the new frame |
| single-window-controller-041 | resize-refit-guard | a resize caused by the controller's own fit-to-content call | a window-resize callback fires | the refit operation is not triggered |
| single-window-controller-042 | visibility-persist-on-close | the window's spec has visibility persistence enabled | the user clicks the window's close button | the window frame manager records the window hidden |
| single-window-controller-043 | visibility-restore | the window's spec has visibility persistence enabled and persisted visibility is true | the visibility-restore operation is called | the window is shown |
| single-window-controller-044 | hud-configuration | any | a HUD configuration value is constructed | it captures a floating flag (default true) and a transparency value (default 1.0) |
| single-window-controller-045 | hud-chrome-opt-in | the HUD-configuration operation never called | the window is inspected | chrome is ordinary opaque, non-floating |
| single-window-controller-046 | hud-transparency-floor | a caller-supplied transparency below 0.3 | the HUD-configuration operation or the set-transparency operation is called | the applied opacity is clamped to 0.3, not the raw value |
| single-window-controller-047 | set-floating | any | the set-floating operation is called with true | the window's level becomes floating |
| single-window-controller-048 | set-floating | any | the set-floating operation is called with false | the window's level becomes normal |
| single-window-controller-049 | set-transparency | any | the set-transparency operation is called | the window's opacity is set to the given value, clamped to 0.3-1.0, independent of the level set by the set-floating operation |
| single-window-controller-050 | singleton-protocol-conformance | a subclass adopting the single-instance protocol supplying the current-instance accessor and shared-instance factory | the protocol extension operations are called | ensure-current, present, and is-open all work without further overrides |
| single-window-controller-051 | singleton-ensure-current | no current instance exists | ensure-current is called twice | the shared-instance factory runs once; the second call reuses the first instance |
| single-window-controller-052 | singleton-present | no current instance exists | present is called | a shared instance is created and shown |
| single-window-controller-053 | singleton-is-open | no current instance exists | is-open is called | it returns false |
| single-window-controller-054 | confines-to-ui-thread | The component exists | Use it from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

