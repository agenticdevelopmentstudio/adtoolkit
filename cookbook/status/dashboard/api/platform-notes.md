
- **SwiftUI**: model `StatusApiClient` as a small `Sendable` struct or an
  `actor` wrapping `URLSession` (`url`/`data(for:)` in place of
  `fetch`/`json`), decoding with `JSONDecoder` in place of `res.json()`, and
  throwing a typed `Error` in place of the crafted `Error` message; expose it
  through a `@Observable` environment object or an `EnvironmentKey` as the
  analogue of `StatusApiProvider`/`useStatusApi`. `eventSource`'s SSE stream
  has no Foundation counterpart — a port needs `URLSession`'s
  `bytes(for:)` async sequence with a manual `text/event-stream` line parser,
  or a small third-party SSE client.
- **Compose**: build the same shape over Ktor's `HttpClient` (or OkHttp) with
  `kotlinx.serialization` in place of `res.json()`; expose the client through
  a `CompositionLocal` as the analogue of the React context/`Provider`. As on
  Apple, there is no native `EventSource`; a port needs OkHttp's SSE support
  or a manual chunked-response reader over the same `HttpClient`.
- **React/Web**: the source. The API client is `StatusApiClient`, constructed
  via `createStatusApiClient` and consumed through
  `StatusApiProvider`/`useStatusApi` (React `Context`/`useMemo`/`useContext`);
  its `fetch`/`json`/`eventSource` operations wrap the browser's native
  `fetch` and `EventSource`, and `monitored-sites.ts`/`peers.ts` are plain
  `async`/`Promise`-returning functions with no framework dependency beyond
  the client type they're given. The concurrency assumptions in Edge Cases
  hold because this is single-threaded browser JavaScript — no two calls
  interleave on the same value — and `ignoreProjects`'s fan-out uses
  `Promise.all`. Tests are colocated (`monitored-sites.test.ts`) and run
  under Vitest.
- **AppKit / UIKit**: the same `URLSession`-based client as the SwiftUI
  bullet applies unchanged — this layer has no view-framework dependency —
  but with no environment-value system, the client is typically handed to
  view controllers through a plain injected singleton or dependency-injection
  container rather than an environment key.
- **WinUI 3**: model `StatusApiClient` as a class exposing
  `Task<T> JsonAsync<T>(string path, ...)` and `Task<HttpResponseMessage>
  FetchAsync(...)` built on a shared `HttpClient` instance, with
  `System.Text.Json` in place of `res.json()` and a thrown, typed exception
  in place of the crafted `Error` message; `Task`/`async`/`await` replace
  `Promise`/`async`/`await` directly. `GroupRow`/`SiteRow`/`EndpointRow` and
  their `View` counterparts become `record` types; the `toGroup`/`toSite`/
  `toEndpoint` mappers become static methods or constructors on those
  records. A bound UI would surface results through `ObservableCollection`/
  `INotifyPropertyChanged`, which none of these three files has a
  counterpart for since they return plain arrays, not a live-bound
  collection. `Windows.Storage` has no role here either, since none of these
  files persists anything. .NET has no built-in SSE client analogous to
  `EventSource`; a port needs `HttpClient`'s streaming response with a
  manual `text/event-stream` parser, or a NuGet SSE package.

