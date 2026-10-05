
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The class is `@unchecked Sendable` with an `NSLock`, and the compute parameter is `rethrows`.
- **Compose**: Use a `Mutex`-guarded `LinkedHashMap` or a Caffeine cache with `expireAfterWrite` and `maximumSize`; the clock-backwards rule needs an explicit stored-time comparison, which Caffeine's ticker does not give by default.
- **React/Web**: A `Map<Key, {storedAt, value}>` with a `now` parameter on `get(key, compute, now = Date.now())`. JavaScript is single-threaded, so no lock is needed, but an async compute needs an in-flight promise map if single-flight behavior is wanted.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Use a `Dictionary<TKey, (DateTime StoredAt, TValue Value)>` guarded by a `lock` statement, with `GetOrCompute(key, compute, now)` running the compute outside the lock. `MemoryCache` with `AbsoluteExpirationRelativeToNow` and `SizeLimit` is the framework analog but does not expire on a backwards clock.

