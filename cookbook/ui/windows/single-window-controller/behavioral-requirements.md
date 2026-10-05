
- **single-thread-isolation**: The type and every one of its members MUST be
  confined to a single designated thread.
- **init-argument-storage**: Constructing the controller with a window ID and
  content MUST store both for use when the window is later built. Neither
  argument is validated for emptiness or content at construction time; an
  empty window ID is accepted and stored as-is (see **registry-registration**
  for what an empty ID means downstream).
- **no-deserialization-init**: The class MUST NOT support construction by
  deserializing an archive; that initializer MUST be unavailable (a
  compile-time error if referenced).
- **default-size**: The class MUST expose a type-level default size of
  600 × 480 (width × height) that subclasses may override to change the
  fallback window size used when no persisted frame exists.
- **forces-window-front**: The class MUST expose an overridable type-level
  flag that subclasses set to request that showing the window additionally
  bring it fully to the front (see **forces-front-ordering**) even when
  quiet presentation would otherwise keep it out of the way (see
  **quiet-presentation**).
- **window-title**: The window's title MUST be an overridable computed
  property (default empty string) that subclasses override to supply the
  window's title.
- **default-content-rect**: The default content rect MUST be an overridable
  computed property that returns a rectangle whose origin is zero and whose
  size is the type-level default size, used only when no persisted frame is
  available.
- **window-style-mask**: The window's style options MUST be an overridable
  computed property (default: titled, closable, miniaturizable, resizable)
  that subclasses override to change the window's chrome, e.g. to request a
  utility or HUD appearance.
- **min-size**: The window's minimum content size MUST be an overridable
  computed property (default 200 × 150) that subclasses override to change
  it.
- **configure-window-hook**: A configuration hook MUST be an overridable,
  no-op-by-default method called once, after the window is built and before
  it is returned from the build step, so subclasses can perform one-time
  additional window setup (toolbar items, appearance, etc.).
- **lazy-window-build**: The controller MUST NOT build its window at
  construction; it MUST build it the first time the window is loaded (i.e.,
  the first time the platform or a caller accesses it).
- **panel-selection**: Building the window MUST construct a utility-style
  window when the style options request a utility or HUD appearance, and a
  standard window otherwise.
- **window-construction**: Building the window MUST construct it with the
  default content rect as its content rect, the style options as its style,
  buffered backing, and no deferred creation.
- **title-on-build**: Building the window MUST set the built window's title
  to the overridable title property.
- **content-view-controller-on-build**: Building the window MUST set the
  built window's content to the content supplied at construction.
- **min-size-on-build**: Building the window MUST set the built window's
  minimum size to the overridable minimum-size property.
- **accessibility-identifier**: Building the window MUST assign the window
  an accessibility identifier derived by slugifying the window ID, so windows
  are addressable in UI tests. Slugification splits camelCase boundaries,
  lowercases, and joins non-alphanumeric runs with hyphens.
- **toolbar-button-mask**: Building the window MUST, when a window spec is
  registered for the window ID, mask the window's standard button visibility
  for close/miniaturize/zoom according to the spec's toolbar-buttons setting,
  hiding any button whose corresponding option is absent from that setting.
- **toolbar-button-mask-default**: Building the window MUST leave all three
  standard window buttons at their platform-default visibility when no
  window spec is registered for the window ID.
- **build-sequence**: Building the window MUST run its steps in this order,
  after constructing the window and setting its title, minimum size,
  accessibility identifier, and content: (1) assign the constructed window to
  the controller's window property; (2) apply the toolbar button mask and,
  if HUD-configured, the HUD chrome; (3) invoke the configuration hook
  exactly once; (4) ask the window frame manager to restore any persisted
  frame for the window ID and apply it to the window; (5) assign the
  controller itself as the window's delegate. Restoring the frame before
  delegate assignment (step 4 before step 5) keeps the restore from itself
  triggering move/resize bookkeeping through the delegate. Running the
  configuration hook before the frame restore (step 3 before step 4) lets
  subclass-installed chrome — a toolbar, for instance, which changes how tall
  the title bar is — finish shaping the window before geometry is restored
  onto it. The window property is assigned early (step 1), not as a final
  step: registry registration is a separate, earlier event — see
  **registry-registration**, which happens at construction, not as part of
  this sequence.
- **registry-registration**: Constructing the controller MUST register it
  with the window registry under the window ID, unconditionally, before any
  window is built — registration does not wait for the window to be built or
  shown.
- **registry-registration-empty-id**: Registration with the window registry
  MUST be a silent no-op when the window ID is empty (the registry's own
  registration guards on a non-empty ID); constructing the controller MUST
  NOT crash or otherwise special-case an empty window ID beyond that. This is
  verified in the window registry; this class supplies no additional guard
  because none is needed.
- **forces-front-ordering**: Showing the window MUST run the platform's
  standard show behavior first — which brings the window to key status and
  orders it front — and then, when the forces-front flag is set, additionally
  force the window fully to front so it is pulled above other applications'
  windows too. No explicit app-activation call is made by this method.
- **quiet-presentation**: Showing the window MUST, when the forces-front flag
  is not set, leave the window ordered by the standard show behavior alone
  and additionally sink it behind the desktop and order it back, so the
  window stays a real, laid-out, visible window — satisfying assertions on
  its visibility, its restored frame, and its screen — without appearing to
  the person at the keyboard.
- **show-window-convenience**: The class MUST expose a parameterless
  show-window convenience that forwards to the sender-taking version with no
  sender, for call sites that have no natural sender.
- **visibility-persist-on-show**: Showing the window MUST record the window
  as visible through the window frame manager when the window's spec has
  visibility persistence enabled.
- **dismiss-method**: The class MUST expose a dismiss method that closes the
  window rather than requiring callers to reach through to the underlying
  window.
- **visibility-persist-on-dismiss**: Dismissing MUST record the window as
  hidden through the window frame manager when the window's spec has
  visibility persistence enabled, mirroring the show behavior on the closing
  path.
- **is-visible**: The class MUST expose a computed visibility flag that
  reflects the underlying window's visibility, returning false when no
  window has been built yet.
- **content-fit**: The fit-to-content operation MUST resize the window's
  content area to the given size using the content-hugging frame
  calculation, which keeps one edge of the window anchored (by default
  top-left) while the opposite edges move to accommodate the new content
  size.
- **content-fit-bail**: The fit-to-content operation MUST compare the
  requested size and anchor state against the last applied fit and skip
  re-applying the frame when both are unchanged, to avoid redundant
  frame-setting work and redundant resize notifications on repeated calls
  with identical inputs.
- **fit-anchor-stability**: The fit-to-content operation MUST reuse the
  anchor point computed on the first fit for subsequent fits, rather than
  recomputing an anchor point from the window's current frame on every call,
  so the anchor edge stays stable across a sequence of content-size changes.
- **reentrant-fit-guard**: The fit-to-content operation MUST guard its own
  frame application so that a resize callback triggered by that very frame
  change does not re-enter the content-refit machinery.
- **content-size-provider**: The class MUST expose a settable
  content-size-provider callback that, when set, supplies the desired
  content size for the refit operation to apply via the fit-to-content
  operation.
- **content-refit-gate**: The refit operation MUST be a no-op when the
  content-size provider is unset, and otherwise MUST call the provider and
  pass its result to the fit-to-content operation.
- **move-refit-debounce**: After a window move, the controller MUST debounce
  refitting by waiting 200 milliseconds before performing the refit,
  canceling and restarting that wait on every subsequent move so only the
  most recently moved-to position's timer ever fires.
- **refit-drag-deferral**: The debounced refit MUST check whether a mouse
  button is currently held (the user is still dragging the window) and, if
  so, reschedule itself rather than performing the refit immediately, so a
  refit does not fight an in-progress drag.
- **move-triggers-refit**: A window-move callback MUST schedule a refit (see
  **move-refit-debounce**) only when the content-size provider is set; with
  no provider set, a move MUST NOT schedule any refit work.
- **frame-persist-on-move**: A window-move callback MUST persist the
  window's new frame through the window frame manager when the window's spec
  has frame persistence enabled.
- **frame-persist-on-resize**: A window-resize callback MUST persist the
  window's new frame through the window frame manager when the window's spec
  has frame persistence enabled, mirroring the move-triggered save.
- **resize-refit-guard**: A window-resize callback MUST skip triggering the
  refit operation when the resize was caused by the controller's own
  fit-to-content call (see **reentrant-fit-guard**), so the refit path does
  not recursively re-trigger itself.
- **visibility-persist-on-close**: A window-will-close callback MUST record
  the window as hidden through the window frame manager when the window's
  spec has visibility persistence enabled, so closing the window via its own
  close button (not just via dismiss) is captured.
- **visibility-restore**: The visibility-restore operation MUST show the
  window when the window's spec has visibility persistence enabled and the
  persisted visibility state is true; otherwise it MUST leave the window
  unshown.
- **hud-configuration**: The class MUST define a nested HUD-configuration
  value with a floating flag (default true) and a transparency value
  (default 1.0), captured by the HUD-configuration operation.
- **hud-chrome-opt-in**: The HUD-configuration operation MUST be the only
  entry point that applies HUD-specific chrome (background translucency and,
  when floating, a floating window level); a window that never calls it
  MUST render with ordinary opaque, non-floating chrome.
- **hud-transparency-floor**: The HUD-configuration operation and the
  set-transparency operation MUST clamp the given transparency value to the
  range 0.3 to 1.0 before applying it as the window's opacity, so a HUD
  window can never be set fully transparent (invisible but still clickable).
- **set-floating**: The set-floating operation MUST set the window's level
  to floating when true, and to normal when false.
- **set-transparency**: The set-transparency operation MUST set the window's
  opacity (not its background color) to the given value clamped per
  **hud-transparency-floor**, independent of the floating level set by the
  set-floating operation.
- **singleton-protocol-conformance**: A subclass that adopts the
  single-instance protocol MUST get its ensure-current, present, and is-open
  operations from the protocol extension without additional implementation,
  provided it supplies the class-level current-instance accessor and a
  shared-instance factory.
- **singleton-ensure-current**: The ensure-current operation MUST create the
  shared instance via the shared-instance factory and assign it to the
  current-instance accessor only when no current instance exists, and MUST
  leave an existing current instance untouched otherwise (i.e., only one
  shared instance is created per process, reused across calls).
- **singleton-present**: The present operation MUST call the ensure-current
  operation and then call the parameterless show-window operation on the
  resulting instance.
- **singleton-is-open**: The is-open operation MUST return false when no
  current instance exists, and otherwise MUST return the current instance's
  visibility flag.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

