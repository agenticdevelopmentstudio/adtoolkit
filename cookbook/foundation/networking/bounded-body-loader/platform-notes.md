
- **SwiftUI**: The source (`Core/Networking/BoundedBodyLoader.swift`) has no
  SwiftUI dependency at all — it is plain Foundation
  (`URLSession`/`URLSessionDataDelegate`/`NSLock`) consumed by a non-UI
  Swift type, `Core/Extensions/OpenVSXClient.swift`. A SwiftUI app ports
  this verbatim as a model-layer type with no `@Observable`/`@State`
  surface of its own.
- **AppKit / UIKit**: This is in fact the source's own platform:
  `BoundedBodyLoader` (`Core/Networking/BoundedBodyLoader.swift`) is a
  `final class`, not `public`, visible only inside `AgenticToolkitCore`,
  which builds for macOS but uses only the plain
  `URLSession`/`URLSessionDataDelegate` API available identically on
  iOS — nothing in it is AppKit-specific. Its one method,
  `body(at:limit:)`, builds its own `URLSession` from the given
  `URLSessionConfiguration` in `init(configuration:)`
  (**dedicated-session**) and hands that session a separate `Delegate`
  object conforming to `URLSessionDataDelegate` that holds only a `State`
  box, never a reference back to the loader (**delegate-object**),
  breaking the retain cycle a self-delegating loader would create (see
  Design Decisions). The declared-length check compares a response's
  `expectedContentLength` against `Int64(limit)` inside `didReceive
  response:completionHandler:`, answering `.cancel` to refuse it
  (**header-ceiling-check**); the running check appends each `didReceive
  data:` chunk to a per-transfer buffer inside `State`, keyed by the
  task's `taskIdentifier` and guarded by one `NSLock`
  (**running-ceiling-check**, **concurrent-isolation**). `BoundedBodyLoader`
  is declared `Sendable` (**concurrent-sharing-safe**). The too-large
  failure is `BoundedBodyLoader.Failure.tooLarge(URLResponse?)`, its sole
  case (**failure-shape**, **overflow-error**); the missing-response
  fallback throws `URLError(.badServerResponse)`
  (**missing-response-fallback**); cooperative cancellation is wired
  through `withTaskCancellationHandler`'s `onCancel: { task.cancel() }`
  (**cooperative-cancellation**); and `deinit` calls
  `session.finishTasksAndInvalidate()` rather than
  `invalidateAndCancel()`, letting in-flight tasks finish
  (**disposal-allows-in-flight-completion**).
- **Compose**: Start from OkHttp or Ktor's `HttpClient` with a streaming
  interceptor (or a `Ktor` `HttpResponse.bodyAsChannel()` read loop) that
  checks `Content-Length` against the ceiling before reading, then reads
  chunks from the `ByteReadChannel`/`ResponseBody` and cancels once the
  running total exceeds it; the per-transfer state box becomes a
  `ConcurrentHashMap` keyed by request/coroutine id guarded by a `Mutex` or
  `synchronized` block in place of `NSLock`, and structured-concurrency
  `Job` cancellation replaces `withTaskCancellationHandler`.
- **React/Web**: Start from `fetch`'s `response.body.getReader()`
  (`ReadableStreamDefaultReader`); check `response.headers.get('content-length')`
  against the ceiling before the first `reader.read()`, then accumulate
  chunks and call `controller.abort()` on an `AbortController` tied to that
  `fetch` once the running total exceeds the ceiling — `AbortController`
  is the direct equivalent of `URLSessionDataTask.cancel()`, and the
  single-threaded event loop replaces the `NSLock`-guarded state box
  outright, since no two chunk callbacks for the same fetch can interleave.
- **WinUI 3**: Start from `System.Net.Http.HttpClient.SendAsync` with
  `HttpCompletionOption.ResponseHeadersRead` so headers arrive before the
  body is read; check `response.Content.Headers.ContentLength` against the
  ceiling the way `accept` does, then read the body through
  `Stream.ReadAsync` in a loop, accumulating into a buffer and enforcing the
  running ceiling exactly as `append` does, honoring a `CancellationToken`
  passed through the same `Task`-based `async`/`await` model as the
  source's `withTaskCancellationHandler`. The per-transfer bookkeeping this
  file keeps in a `taskIdentifier`-keyed dictionary behind an `NSLock`
  becomes a `ConcurrentDictionary` keyed by a request id, or simply local
  state per `SendAsync` call, since .NET's `HttpClient` does not multiplex
  many transfers through one shared delegate the way `URLSessionDataDelegate`
  does; there is no `System.Text.Json` involvement at this layer, since
  decoding the returned bytes is the caller's job, exactly as it is for
  `OpenVSXClient` here.

