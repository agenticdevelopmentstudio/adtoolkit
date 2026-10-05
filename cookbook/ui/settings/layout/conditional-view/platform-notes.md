
- **SwiftUI**: Bind the setting's `@Published` value into `@State` (or
  observe it via a Combine publisher) and use structural conditional
  inclusion, `if isVisible(value) { child }`, rather than `.hidden()` —
  SwiftUI removes the branch not taken from the view hierarchy the same way
  a hidden `NSView` drops out of an `NSStackView`, which is what
  `evaluates-initial-visibility`/`hides-when-predicate-returns-false`
  ultimately exist to drive for a hosting `GroupView`-equivalent stack.
  Evaluate the predicate once for the initial `@State` and again in the
  publisher's `sink`/`onReceive`, mirroring
  reevaluates-visibility-on-setting-change.
- **Compose**: Collect the setting as `State` via `collectAsState()` (or
  equivalent `Flow` collection) and wrap the child composable in `if
  (isVisible(value)) { child() }`. Compose already skips recomposition for
  an unchanged `State` value, so no extra "skip redundant" guard is needed
  to mirror skips-redundant-visibility-writes; still call an
  `onVisibilityChange` callback from a `LaunchedEffect(visible)` block (or
  `snapshotFlow { visible }.distinctUntilChanged()`) when a hosting
  container needs to know the child entered or left the composition —
  `onGloballyPositioned` is a layout callback, not a composition-membership
  signal, so it cannot drive this — mirroring
  exposes-visibility-change-callback.
- **React/Web**: Subscribe to the setting's store with a hook (e.g.
  `useSyncExternalStore`) and render conditionally, `{isVisible(value) &&
  child}`. Guard the store subscription's callback so it only triggers a
  re-render when the *computed visibility*, not just the underlying value,
  changes, mirroring skips-redundant-visibility-writes; call an optional
  `onVisibilityChange` prop from a `useEffect` keyed on that computed
  boolean, mirroring notifies-visibility-change-once.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/ConditionalView.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`, generic
  over `Value: Codable & Sendable`, inside the `ComposableSettings`
  namespace, conforming to `SettingsViewProtocol` and
  `SelfHidingSettingsView`. It wraps one `child` view, pins it via
  `pinToEdges`, and drives `isHidden` from a `UserSettingObserver<Value>`
  wrapping a caller-supplied `UserSetting<Value>`. `fills-container-with-child`
  is implemented by setting `translatesAutoresizingMaskIntoConstraints =
  false` on both itself and `child` and pinning `child`'s
  top/leading/trailing/bottom anchors to the container's corresponding
  anchors with the `pinToEdges` helper; `requires-full-configuration-at-construction`
  is
  implemented by overriding both `init(frame:)` and `init(coder:)` to
  `fatalError`, leaving `observing:child:isVisible:` as the only usable
  initializer — attempting either inherited path traps with a fatal error
  rather than returning a usable instance. The class's `@MainActor`
  declaration is the source's implementation of thread-confinement:
  construction and mutation are restricted to the main actor, enforced at
  compile time by Swift's isolation checking. There is no UIKit code path
  in source; a UIKit port would replace `NSView.isHidden` with
  `UIView.isHidden` (the same removal-from-layout semantics apply) and
  would have no `NSCoder`-vs-frame initializer split to fatal-error on, the
  way requires-full-configuration-at-construction does here.
- **WinUI 3** (the reason this recipe exists): Wrap `child` in a
  `ContentControl` (or host it directly in the parent `Grid`/`StackPanel`
  cell) and bind its `Visibility` with a one-way `x:Bind` through a value
  converter over the observed setting, e.g. `Visibility="{x:Bind
  Setting.Value, Converter={StaticResource IsVisibleToVisibilityConverter},
  Mode=OneWay}"`, where the converter is the WinUI analog of the
  `isVisible` predicate. Use `Visibility.Collapsed`, not `Hidden`, so the
  hosting `StackPanel` (the WinUI analog of `GroupView`'s card
  `NSStackView`) actually closes up the row's space — `Hidden` keeps the
  layout slot reserved and would silently violate
  hides-when-predicate-returns-false's intent of the row disappearing, not
  merely going invisible. `FrameworkElement` has no built-in
  visibility-changed event, so expose a small
  `RegisterPropertyChangedCallback` on the `Visibility` dependency property
  (or a custom `VisibilityChanged` event) as the analog of
  `onVisibilityChange`, guarding it so it only fires when the resolved
  `Visibility` actually differs from the previous one, mirroring
  skips-redundant-visibility-writes, so a hosting card panel can collapse
  its own padding and divider around the row the way `GroupView` does.

