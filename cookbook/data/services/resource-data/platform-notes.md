
- **React/Web**: This is the reference implementation. `@tanstack/react-query`
  v5 (via the toolkit's own module-scope `QueryClient`, see `query/index.tsx`)
  backs the resource-list/resource-item cache; `window.localStorage` backs
  FTD and the cached workspace slug; `window.CustomEvent`/
  `window.addEventListener`/`window.dispatchEvent` back the
  `workspaces-changed` cross-module announcement; `String.prototype
  .localeCompare` (via `sortByText`) provides locale-aware ordering.
- **SwiftUI / AppKit / UIKit**: An `ObservableObject`/actor-backed
  dictionary cache keyed identically (tenant, then cache key, then id) is
  the idiomatic replacement for the react-query cache; `UserDefaults`
  (namespaced by the same `storageKeyPrefix` convention) replaces
  `localStorage` for FTD and the workspace-slug cache;
  `NotificationCenter.default.post`/`.addObserver` replaces the
  `workspaces-changed` `CustomEvent` pair; `String.localizedStandardCompare`
  replaces `sortByText`'s comparator.
- **Compose / Android**: A `MutableStateFlow`-backed map cache keyed
  identically is the idiomatic cache substitute; Android `DataStore` (or
  `SharedPreferences` for the simplest case) replaces `localStorage` for
  FTD and the workspace-slug cache; a `SharedFlow` replaces the
  `workspaces-changed` event pair; `java.text.Collator` replaces
  `sortByText`'s comparator.
- **WinUI 3**: `Microsoft.Extensions.Caching.Memory`'s `IMemoryCache` (or a
  hand-rolled `Dictionary<(string tenantId, string cacheKey, string? id),
  CacheEntry<T>>`) is the idiomatic replacement for the react-query cache —
  a native port MUST keep `tenantId` as the FIRST key segment exactly as
  `resourceListKey`/`resourceItemKey` do, not as a secondary filter applied
  after a shared read, to preserve the same hard cross-account isolation on
  a machine shared between signed-in users.
  `Windows.Storage.ApplicationData.Current.LocalSettings` replaces
  `localStorage` for the FTD (`readLastId`/`writeLastId`/`readViewMode`/
  `writeViewMode`) and cached-workspace-slug values, using the same
  `{prefix}:ftd:{basePath}:{name}` / `{prefix}:home:workspace` key shape so
  the `storageKeyPrefix` convention (see Configuration for the shipped default) still disambiguates
  multiple apps sharing one settings container. A C# `event` (or a
  `WeakEventManager` to avoid the listener-leak `onWorkspacesChanged`'s
  unsubscribe function exists to prevent) replaces the `workspaces-changed`
  `CustomEvent`/`onWorkspacesChanged` pair. `string.Compare(a, b,
  StringComparison.CurrentCulture)` replaces `sortByText`'s
  `localeCompare`-based ordering. `System.Text.Json`'s `JsonSerializer`
  replaces every inline JSON parse/serialize this component does for its
  own cached values (not the JWT/token parsing itself, which `auth-client`'s
  own Platform Notes already cover).
- **Host namespace**: The web implementation was extracted from the ADH hub and keeps its names: the storage-key prefix defaults to `'adh'` and the workspace-list-changed event is the fixed constant `'adh:workspaces-changed'`. A host other than ADH sets its own prefix through the data-configuration setter; the event name is not configurable.

