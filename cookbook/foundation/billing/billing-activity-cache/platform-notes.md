
- **SwiftUI**: Not used; the cache has no view layer.
- **Compose**: A `LinkedHashMap` with `removeEldestEntry` behind a `Mutex`, with a `LongArray` of seconds per entry.
- **React/Web**: A `Map` used as an LRU (delete and re-insert on read); single-threaded, so no lock.
- **AppKit / UIKit**: A `final class` marked `Sendable`, delegating to `LRUCache<String, Entry>` with a private `Entry { cursor: Int64; seconds: [Int] }`.
- **WinUI 3**: A `ConcurrentDictionary` plus a lock-guarded recency list, or `MemoryCache` with a size limit; use `SortedSet<int>` or the same merge over `List<int>`.

