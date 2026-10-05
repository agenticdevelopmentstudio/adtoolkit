
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The class is `@unchecked Sendable` and uses an `NSLock`.
- **Compose**: Use a `LinkedHashMap(accessOrder = true)` with `removeEldestEntry`, or `android.util.LruCache`, behind a `synchronized` block; the peek and contains operations need a non-recording read.
- **React/Web**: A `Map` preserves insertion order, so delete-and-reinsert on read gives the same behavior in a few lines; JavaScript is single-threaded so no lock is needed.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A generic class over `Dictionary<TKey, Entry>` with a monotonic counter and a `lock` statement, or a `LinkedList` plus dictionary if capacities grow; `ConcurrentDictionary` alone is not enough because reads must update recency.

