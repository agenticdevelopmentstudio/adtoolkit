
- **SwiftUI / AppKit / UIKit**: Not applicable — no Swift declaration exists
  in this domain; there is no Apple-side Projects implementation to note
  concurrency behavior for.
- **React/Web**: This is the sole reference implementation. Every client is
  a plain `async` function object over `fetch` (via `authedJson`/
  `authedRequest`); `useProjectLive` is the one React-specific export (a
  `useEffect`/`useRef` hook), and every other export is framework-agnostic
  and usable from a plain script, a test, or a non-React renderer.
- **Windows / WinUI 3**: No WinUI 3 implementation exists in this domain.
  A WinUI 3 port would need to reproduce the module-scope refcounting
  `subscribeToProject` performs with a `Map`/`Set` (`live.ts`) using
  whatever this platform's equivalent of a singleton connection registry is
  (e.g. a static dictionary keyed by `projectId` guarding one
  `Windows.Web.Http`/`HttpClient`-backed SSE-equivalent connection), since
  the "one connection per board, closed only by the last watcher" contract
  (live-one-connection-per-board-refcounted) is a behavioral requirement of
  this domain, not an artifact of the browser `EventSource` API.
- **Android**: No Android implementation exists in this domain. A Kotlin
  port would face the identical refcounting requirement as Windows above,
  and would need `compareRank`'s byte-order comparator (never a locale
  string comparator) to stay compatible with the backend's `COLLATE "C"`
  column (work-item-rank-is-opaque-byte-order).
- **Python**: No Python implementation exists in this domain.

