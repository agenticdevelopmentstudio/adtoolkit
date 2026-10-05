
- **SwiftUI**: These six types are plain Swift/Foundation with no AppKit
  dependency, so a SwiftUI host can wrap `NotesManager` in an
  `@Observable` or `ObservableObject` adapter (it is neither itself — see
  Design Decisions) and drive a `List`/`ForEach` from `notes`, observing
  `notesDidChangeNotification` and `storageDidFailNotification` the same
  way an AppKit host does.
- **Compose**: Port `Note` as a `data class`, `NoteFolder` as a recursive
  `data class`, and `NoteStorage` as a Kotlin `interface` of four
  functions (suspend or blocking, matching the source's synchronous-and-throwing
  shape). `NotesManager` becomes a `ViewModel` holding a
  `StateFlow<List<Note>>` in place of the notification pair, with the
  debounced save mapped onto a coroutine job keyed by note id (the role
  `KeyedDebouncer` plays here) and the storage-issue-ordering guarantee
  reproduced with a single-threaded dispatcher or a `Mutex`.
- **React/Web**: `Note`/`NoteFolder` become plain TypeScript interfaces;
  `NoteStorage` an interface of four `Promise`-returning methods.
  `NotesManager` becomes a store (a hook backed by
  `useSyncExternalStore`, or a small class with subscribers in place of
  `NotificationCenter`), with the per-note debounce implemented via
  `setTimeout` keyed by note id and the write-ordering guarantee
  implemented as a per-instance promise chain, exactly mirroring
  `performStorage(_:)`'s `storageChain`.
- **AppKit / UIKit**: The six sources given here — `Note.swift`,
  `NoteFolder.swift`, `NoteStorage.swift`, `NoteTaxonomyProviding.swift`,
  `MarkdownNoteStorage.swift`, and `NotesManager.swift`, all under
  `packages/apple/AgenticToolkit/macOS/Features/NotesWindow/` — are the
  source platform: a macOS-only target consumed by
  `NotesCoordinator`/`NotesSplitViewController` (out of scope for this
  recipe) via `NotificationCenter` observation and `@MainActor` calls.
  `Note`, `NoteFolder`, and `MarkdownNoteStorage` are `Sendable`;
  `NotesManager` is itself `@MainActor`, and every storage call it issues
  runs off the main actor through `Task.detached`, serialized into its
  own `storageChain` (see `notesmanager-confined-to-primary-thread` and
  `notesmanager-storage-off-primary-thread`). `NoteFolder`'s explicit,
  non-accidental `Hashable` conformance exists because an `NSOutlineView`
  bridges a Swift value lacking that conformance to a boxed object whose
  hash falls back to that box's own identity, so two
  differently-boxed-but-equal folders from two separate `reload()`s would
  hash unequally and `isItemExpanded(_:)`/`row(forItem:)` could never
  match one across a reload (see `notefolder-value-semantics`).
  `MarkdownNoteStorage` persists through SQLite via GRDB, and neither it
  nor `NotesManager` add Keychain storage or any protection beyond what
  that store applies (see Privacy). Nothing in these six files is itself
  AppKit-specific — they import only `Foundation`, `os`,
  `AgenticToolkitCore`, `AgenticToolkitMarkdown`, and
  `AgenticToolkitDatabase` — so the same files would compile unchanged
  into a UIKit iOS target.
- **WinUI 3**: `Note`/`NoteFolder` become a `record`/`class` pair (or a
  lightweight `INotifyPropertyChanged` model if the folder tree needs to
  bind directly to a `TreeView`). `NoteStorage` becomes an interface
  returning `Task<T>` per method. `NotesManager` becomes a class backed
  by an `ObservableCollection<Note>` in place of `notes`, replacing
  `notesDidChangeNotification`/`storageDidFailNotification` with
  `INotifyCollectionChanged` and a plain C# event; a
  `SemaphoreSlim(1, 1)` awaited before each storage call reproduces the
  one-at-a-time, issue-ordered `storageChain`, and a
  `System.Threading.Timer` per note id, restarted on each edit,
  reproduces `KeyedDebouncer`'s per-key debounce-with-retry.

