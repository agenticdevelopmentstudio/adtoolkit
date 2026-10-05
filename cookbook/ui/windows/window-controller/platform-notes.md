
- **SwiftUI**: This generics-over-a-view-controller pattern has no direct
  SwiftUI analog because SwiftUI content *is* the typed value already — a
  `WindowGroup`/`Window` scene's root `View` is accessed and composed
  directly, with no untyped `contentViewController`-style intermediary to
  downcast. A SwiftUI port would drop the window controller's typed accessor
  entirely and drop the content wrapper's wrapping role along with it.
- **Compose (Desktop)**: Same reasoning as SwiftUI — a `Window`/`DialogWindow`
  composable takes its content as a `@Composable` lambda with full static
  typing already, so there is no untyped content slot to wrap or downcast.
- **React/Web**: A browser window has no view-controller layer at all;
  the closest analog to a typed accessor is a typed `ref` on a child
  component (e.g. `useRef<ContentHandle>()`), used only when a parent needs
  imperative access to a specific child's instance methods.
- **AppKit / UIKit**: `WindowController.swift` defines both types for AppKit.
  `WindowController<ViewControllerType>` is specific to this file for its
  `as?`-based typed accessor over `NSWindowController.contentViewController`
  and for adding no initializer of its own; it is `@MainActor`-isolated by
  inheritance from `SingleWindowController`'s explicit `@MainActor` (Swift's
  global-actor inheritance rule). `WindowContentViewController<ViewType>`
  is specific to this file for overriding `loadView()` to skip nib loading
  and for the coder initializer's runtime-only failure (`init?(coder:)`
  calling `fatalError("init(coder:) has not been implemented")`, see Design
  Decisions); it declares no explicit `@MainActor` of its own, but
  `NSViewController` itself is `@MainActor`-isolated in the AppKit overlay,
  so the subclass inherits that isolation the same way. UIKit has no
  `NSWindowController` equivalent, so `WindowController`'s typed accessor has
  no direct UIKit counterpart; but `WindowContentViewController`'s pattern
  maps directly, since `UIViewController` also declares `loadView()` for
  installing a view without a nib, exactly as this class overrides it here.
- **WinUI 3**: There is no `NSViewController`-equivalent generic content
  controller sitting inside a WinUI `Window` — content is set directly via
  `Window.Content` (a `UIElement`), and navigation/lifecycle parity is
  usually obtained through a `Frame.Navigate(typeof(PageType))` call instead.
  The typed-accessor half of this recipe maps to a small `TypedWindow<TPage>`
  wrapper holding a `Window` and a `Frame`, exposing
  `CurrentPage: TPage? => Frame.Content as TPage` in place of
  `viewController`. The content-wrapping half maps to setting
  `Window.Content = rootElement` directly for a plain `UIElement`, or, when
  page-navigation parity with `NSViewController`'s lifecycle is wanted,
  wrapping `rootElement` inside a `Page` subclass and setting it as
  `Frame.Content`. No dedicated WinUI visual states apply, since both
  `WindowController` and `WindowContentViewController` are plumbing classes,
  not rendered controls.

