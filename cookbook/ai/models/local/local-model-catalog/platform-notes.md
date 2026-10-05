
- **SwiftUI**: The source
  (`packages/apple/AgenticToolkit/AIPluginKit/LocalModelCatalog.swift`, its
  sibling `LocalModelServer.swift`, and tests
  `Tests/AIPluginKitTests/LocalModelCatalogTests.swift` /
  `LocalModelServerTests.swift`) has no SwiftUI (or any UI framework)
  dependency — it is a plain `Foundation`-only Swift `actor`, consumed today
  by `LocalInferenceGuard` from `await`-based call sites of any isolation
  domain. Its concurrency safety comes entirely from being an `actor`, not
  from any view-layer construct. Internally, `serialized-state-access` is
  implemented by declaring the type a Swift `actor`, so calls interleave
  only at `await` suspension points; the injectable fetch function is typed
  `@Sendable (URL) async throws -> Data`, defaulting to a `liveFetcher` that
  issues a `GET` with `URLRequest.timeoutInterval = 5` and throws
  `URLError(.badServerResponse)` on a non-200 `HTTPURLResponse`. The
  `concurrent-fetch-deduplication` gap follows from actor
  reentrancy: two `await`s on `fetcher(url)` before either write to `cache`
  can interleave. The `fetch-error-is-fully-swallowed` gap follows
  from `if let data = try? await fetcher(url)`, which discards whatever
  error `fetcher` throws — including `URLError(.cannotConnectToHost)` on a
  connection failure, or a `CancellationError` on task cancellation.
  `base-url-locality-is-unenforced` follows from `LocalModelCatalog` never
  calling the sibling `LocalModelServer.isLoopback(baseURL:)` before
  fetching.
- **Compose**: There is no Compose-specific consideration since this is a
  data/networking layer, not UI. A Kotlin port would use a class guarded by
  a `kotlinx.coroutines.sync.Mutex` (or a single-threaded
  `CoroutineDispatcher`) around a `MutableMap<String, Entry>` cache to
  reproduce the actor's serialization; `Instant`/`Clock` from
  `kotlinx-datetime` for `fetchedAt` and TTL comparisons; and an
  `HttpClient` (Ktor) or `OkHttp` call with an explicit 5-second timeout for
  `liveFetcher`'s equivalent. Unlike the Swift actor, a `Mutex`-based port
  makes it straightforward to also close the
  `concurrent-fetch-deduplication` gap by caching the in-flight
  `Deferred<Map<String, Long>?>` per `baseURL` instead of only the completed
  result.
- **React/Web**: A module-level `Map<string, Entry>` cache, with
  `Entry { sizes: Record<string, number> | null; fetchedAt: number;
  lastFetchFailed: boolean }`, and an `async function sizeBytes(model,
  baseURL)` mirroring `sizeBytes`/`sizes`. Use `fetch` with `AbortSignal.timeout(5000)`
  for the 5-second bound, and `Date.now()` for TTL comparisons. JavaScript's
  single-threaded event loop still allows the same
  `concurrent-fetch-deduplication` gap across concurrent `await`s on the same
  `baseURL` unless the port explicitly caches and reuses the in-flight
  `Promise` per key — a natural fix to apply during the port even though the
  Swift source does not.
- **AppKit / UIKit**: No AppKit- or UIKit-specific API appears in this file;
  it is UI-framework-agnostic and is called from AppKit-hosted code
  (`LocalInferenceGuard`'s callers) purely through `await`. Nothing in this
  type changes to run under UIKit.
- **WinUI 3**: This is the platform this recipe exists to steer. There is no
  `actor` concept in C#/.NET, so the serialization `LocalModelCatalog` gets
  for free from being an `actor` MUST be reproduced explicitly — for
  example, a `SemaphoreSlim` (count 1) guarding all reads and writes of a
  `Dictionary<string, CacheEntry>`, or, more precisely, a per-`baseURL`
  `Dictionary<string, Lazy<Task<IReadOnlyDictionary<string, long>?>>>` so
  that concurrent callers for the same `baseURL` await the same in-flight
  `Task` instead of each starting their own fetch — directly closing the
  `concurrent-fetch-deduplication` gap flagged above rather than
  reproducing it. Use `HttpClient.Timeout = TimeSpan.FromSeconds(5)` (or a
  linked `CancellationTokenSource`) for `liveFetcher`'s 5-second bound, and
  `System.Text.Json`'s `JsonSerializer.Deserialize<TagsResponse>` — with a
  `JsonSerializerOptions` that tolerates unknown/missing fields — for
  `parseSizes`, iterating entries individually (a `try`/`catch` or nullable
  fields per entry) so one malformed entry doesn't fail the whole
  deserialization, matching `LocalModelServer.parseSizes`'s per-entry
  tolerance. Model the cache entry as a `readonly record struct CacheEntry(
  IReadOnlyDictionary<string, long>? Sizes, DateTimeOffset FetchedAt, bool
  LastFetchFailed)`, and expose `Task<long?> GetSizeBytesAsync(string model,
  string baseUrl)` as the public surface, mirroring `sizeBytes`'s signature
  and null semantics (`long?` for "unknown," never a thrown exception for
  the routine "server down" case).

