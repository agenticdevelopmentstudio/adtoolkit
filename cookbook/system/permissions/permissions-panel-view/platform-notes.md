
- **SwiftUI**: A SwiftUI counterpart would be a `PermissionsPanel: View`
  holding `permissions: [Permission]` and a checker, laying out a
  `VStack(alignment: .leading, spacing: 8)` of one `PermissionRow` per
  permission (mirroring the `NSStackView` here). `viewDidMoveToWindow`'s
  refresh-on-appear maps to `.task { await refreshAll() }` on the stack;
  the app-activation refresh maps to observing `scenePhase` (or an
  `NSApplication.didBecomeActiveNotification` publisher on macOS) and
  re-running the same refresh; the cancel-and-replace pattern named in
  **latest-refresh-wins** maps to reassigning a `Task` handle stored in
  state, cancelling the previous one before starting a new one.
- **Compose**: Android's permission model has no per-item equivalent to
  Accessibility, Automation, or Keychain grants, so a literal port does not
  apply — treat this as guidance for whichever permissions do map. Lay out
  a `Column(verticalArrangement = Arrangement.spacedBy(8.dp))` of one
  permission-row composable per entry; drive the request flow through
  `rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission())`
  in place of the shared presenter's grant flow; refresh on the composable
  entering composition (`LaunchedEffect(Unit)`) and again on resume via a
  `DisposableEffect` observing `Lifecycle.Event.ON_RESUME` — the Compose
  analog of the window-attach and app-activation triggers here — cancelling
  and relaunching the refresh coroutine the same way the source's
  cancel-and-replace pattern (**latest-refresh-wins**) does.
- **React/Web**: The permissions this component lists (Accessibility,
  Automation, Screen Capture, Keychain) have no web equivalent; only
  Notifications, Location, and Microphone map to the web Permissions API
  (`navigator.permissions.query`, `Notification.requestPermission`,
  `getUserMedia`). Render a flex column of permission rows with 8px gaps;
  refresh once on mount (`useEffect(() => { refreshAll() }, [])`, mirroring
  the window-attach trigger) and again on a `visibilitychange` listener
  when the document becomes visible (mirroring app activation); the
  cancel-and-replace refresh pattern maps to an `AbortController` (or a
  ref holding the latest request id) that a new refresh call replaces
  before its own run starts.
- **AppKit / UIKit**: This is the source platform (AppKit, macOS):
  `PermissionsPanelView.swift` (the container, layout, and refresh
  orchestration), `PermissionRowView.swift` (the per-permission card),
  `PermissionPresenter.swift` (the grant-flow dispatch this component's
  rows call into), and `PermissionChecking.swift`/
  `SystemPermissionChecker.swift` (the injected status/request provider).
  Internally, `PermissionsPanelView.swift`'s private `buildLayout()`
  constructs the row hierarchy once from `init`; its private
  `scheduleRefresh()` implements the cancel-and-replace pattern by
  cancelling and reassigning the private `refreshTask` field; and its
  private `isObserving` flag guards `startObservingActivation()` against
  registering the activation observer more than once. Because
  `AgenticDeveloperToolkit` also exports a type named `Permission`, a
  caller whose target imports both modules must spell this component's
  permission type `AgenticToolkitPermissions.Permission` to resolve the
  ambiguity. `PermissionsPanelView.init(coder:)` is marked
  `@available(*, unavailable)` at compile time and calls `fatalError` if
  invoked at runtime, since this component is never instantiated from a
  storyboard or nib; conformance for that guarantee is a build that fails
  to compile a call to it, or a runtime `fatalError` if that unavailability
  is bypassed (for example through Objective-C bridging). UIKit has no
  drop-in counterpart: iOS's permission set and its consent flows (App
  Tracking Transparency, `CLLocationManager`, etc.) differ enough from
  macOS's TCC permissions that this component's structure (one card per
  `Permission` case, refresh on appear/foreground) is the part worth
  porting to a `UICollectionView`/`UIStackView` layout, not a
  line-for-line translation of the permission set itself.
- **WinUI 3**: Model the vertical stack as a `StackPanel` with
  `Orientation="Vertical"` and `Spacing="8"` (or an `ItemsRepeater` bound
  to an `ObservableCollection` of row view models), hosting one custom
  `PermissionRow` `UserControl` per permission — WinUI's `StackPanel`
  stretches children cross-axis by default when the child's
  `HorizontalAlignment` is left at `Stretch`, so the explicit per-row
  width constraint this AppKit file needs (`row-width-pinned-to-stack`)
  has no direct WinUI analog and can usually be dropped rather than
  translated. Map the window-attach refresh to the panel's `Loaded` event
  and the app-activation refresh to the hosting `Window`'s `Activated`
  event (the WinUI analog of `NSApplication.didBecomeActiveNotification`);
  implement `latest-refresh-wins` with a `CancellationTokenSource` field
  that a `RefreshAsync()` method cancels and replaces before starting its
  new pass, mirroring the source's own cancel-and-replace pattern. A
  completed grant action awaits its own flow, then calls
  `RefreshAsync()` without awaiting it — matching **action-refresh** — and
  each row's own "open settings" affordance uses
  `Windows.System.Launcher.LaunchUriAsync` with an `ms-settings:` URI, the
  Windows analog of this component's `x-apple.systempreferences:` pane
  URLs (constructed in `Permission.swift`, a different component's
  concern).
- **confines-to-ui-thread**: On Apple platforms the type is `@MainActor`-isolated, so the compiler enforces the rule.

