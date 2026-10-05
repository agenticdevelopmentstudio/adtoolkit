
- **React/Web** (source platform): `live-events.ts` lives under
  `packages/web/packages/status-server/src/live/`; it uses only a plain
  JavaScript `Set`, `Date.now()`, and Node's global `setTimeout`/`clearTimeout`
  — no external pub/sub library. Its two type-only imports
  (`StatusConfig`, `Storage`, `LiveSnapshot`) and its one value import
  (`buildLiveSnapshot`) all resolve within the same `status-server` package;
  the Hono SSE route that turns a delivered snapshot into
  `event: snapshot` bytes (`routes/stream.ts`) is a separate file, external
  to this recipe's source.
- **SwiftUI / AppKit / UIKit**: a Swift port of this exact broadcaster (not
  merely a client of the existing Node backend) models the subscriber set as
  an `actor`-isolated `[UUID: (LiveSnapshot) -> Void]` (a dictionary keyed by
  a generated id stands in for JS's reference-identity `Set`, since Swift
  closures are not `Equatable`/`Hashable`), publish as an `async` method on
  that actor so mutation is serialized the way the single-threaded event loop
  serializes it here, and the debounce timer as a stored `Task` that sleeps
  `150_000_000` nanoseconds via `Task.sleep(nanoseconds:)`, cancelled in the
  reset path with `Task.cancel()` — which, unlike this source's
  `clearTimeout`, also cancels a build already in flight if `buildLiveSnapshot`
  checks `Task.isCancelled` cooperatively, directly resolving the open
  question on in-flight-build-cancellation that Node's `setTimeout` cannot.
- **Compose**: the Kotlin equivalent is a `MutableSharedFlow<LiveSnapshot>`
  (replay = 1, so a late collector immediately sees the last value, mirroring
  `recentSnapshot`) with `subscribeLive`/`publishSnapshot` becoming
  `flow.collect { }` and `flow.emit(...)`; the debounce maps to Kotlin
  coroutines' `.debounce(150)` operator on an upstream trigger flow, and
  `resetLiveEvents` to resetting the `SharedFlow`'s backing state and
  cancelling the collecting `CoroutineScope`.
- **WinUI 3**: this is the reason this recipe exists. A .NET reimplementation
  of this SERVER-side broadcaster (an ASP.NET Core Minimal API backend, not a
  WinUI client) models subscribers as a
  `ConcurrentDictionary<Guid, Action<LiveSnapshot>>` — a real
  `lock`/concurrent collection is required here, unlike this source, because
  ASP.NET Core request handling is thread-pool-based, not single-threaded
  like Node's event loop, so `single-threaded-mutation` does NOT hold for a
  WinUI 3/.NET port and MUST be replaced with explicit synchronization. The
  coalesce timer maps to a single `System.Threading.Timer` (or
  `Task.Delay(150)` awaited from a guarded `Interlocked.CompareExchange` on a
  "build pending" flag, replacing the plain `if (pending) return;` check),
  the cache to a `volatile` `(LiveSnapshot Snapshot, DateTimeOffset At)?`
  field read under the same lock, and the SSE-equivalent transport to
  ASP.NET Core's `IAsyncEnumerable<T>`-based Server-Sent Events support (or a
  SignalR hub, if bidirectional push is ever needed) rather than Hono's
  `ReadableStream`. `CancellationToken`, threaded from the timer's callback
  into the build call, is the natural place to resolve
  in-flight-build-cancellation on this platform — a capability Node's
  `setTimeout`/`Promise` pairing in the actual source does not have.

