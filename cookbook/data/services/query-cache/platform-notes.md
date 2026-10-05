
- **React/Web**: This is the reference implementation.
  `@tanstack/react-query` v5's `QueryClient`/`QueryClientProvider`/
  `useQueryClient` back the cache and its React binding; a module-scope
  `let` binding backs the one-per-tab singleton; `window.addEventListener
  ('storage', ...)` backs the cross-tab session watch;
  `@agentic-toolkit/auth/client`'s `onSessionChange`/`readTokenSubject`
  supply the same-tab session signal and the principal comparison value.
- **SwiftUI / AppKit / UIKit**: A `final class` or `actor`-isolated cache
  object (an `NSCache`- or `Dictionary`-backed store keyed the same way the
  react-query keys are) held as a singleton (a static property, or an
  `EnvironmentObject`/`ObservableObject` injected once at the app's root)
  replaces the module-scope `QueryClient`; `NotificationCenter.default`
  (posting and observing a custom notification name) or a Combine
  `PassthroughSubject` replaces `onSessionChange`; there is no
  same-origin-other-tab analog to port, since an Apple app is a single
  process — a second window of the same app sharing the cache singleton
  in-process already covers that case without any storage-event equivalent.
- **Compose / Android**: A Kotlin `object` (Kotlin's own module-scope
  singleton) holding a `MutableStateFlow`- or coroutine-`Deferred`-backed
  cache map replaces the `QueryClient` singleton; a `SharedFlow`/`Channel`
  emitted on sign-in/sign-out/refresh replaces `onSessionChange`; as with
  Apple, there is no cross-tab analog to port on a single-process Android
  app.
- **WinUI 3**: A cache service — `Microsoft.Extensions.Caching.Memory`'s
  `IMemoryCache`, or a hand-rolled `ConcurrentDictionary`-backed store keyed
  identically to the react-query keys — registered as a DI `Singleton` (via
  `IServiceCollection.AddSingleton`) is the idiomatic replacement for the
  module-scope `QueryClient`, constructed once at app startup rather than
  lazily on "first browser call" (a WinUI 3 app has no server/browser split
  to distinguish; every launch is the "browser" case). A C# `event` (or an
  `IObservable<Unit>` via `System.Reactive`, to avoid the listener-leak a
  `WeakEventManager` exists to prevent) raised by the same code that writes
  or clears the stored tokens replaces `onSessionChange`; the handler MUST
  apply the identical "compare the subject, only clear on an actual change"
  guard this recipe's comparison callback implements here, so a token
  refresh for the same signed-in user does not needlessly discard the
  cache. There is no `window` `'storage'`-event equivalent for a
  single-process WinUI 3 app; if the app supports multiple top-level
  windows in one process, they already share the one DI-scoped singleton
  in-process, so no cross-window signal is needed at all — a genuinely
  separate-process scenario (e.g. a companion process) would instead need
  an explicit IPC channel, which has no counterpart in this source.

