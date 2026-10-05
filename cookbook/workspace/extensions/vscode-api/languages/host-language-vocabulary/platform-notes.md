
- **SwiftUI**: the source (`HostLanguageVocabulary.swift`, alongside
  `LanguageContributionPoint.swift` for the contributed half and
  `MainThreadLanguages.swift` for the `ExtensionLanguageVocabulary`
  protocol it conforms to) is a plain `@MainActor` Foundation type with no
  dependency on SwiftUI or any view-layer framework; it imports only
  `CodeEditLanguages` and `Foundation`. A port that keeps this component in
  Swift needs nothing beyond those two imports plus whatever type stands
  in for `LanguageContributionPoint`.
- **Compose**: no JVM equivalent of CodeEditLanguages' bundled tree-sitter
  language catalogue exists as a drop-in dependency; model the built-in
  half as a locally maintained, ordered list of language ids standing in
  for `CodeLanguage.allLanguages`, deduplicate it with a `LinkedHashSet`
  exactly as the Swift `seen: Set<String>` guard does, then append a
  contribution source's own ordered list the same way. Confine the
  composing function or class to Android's main thread, mirroring
  `@MainActor`, since nothing here needs to run off it.
- **React/Web**: model `languageIdentifiers` as a plain function (or a
  getter with no memoization) that rebuilds its result on every call,
  never a cached value, backed by a JS `Set` for the same seen-before
  dedup a `for` loop with `.has()`/`.add()` gives. There is no actor
  concept in a single-threaded JS runtime, so `confines-to-ui-thread`
  collapses to "call this only from the execution context that owns the
  contribution registry."
- **AppKit / UIKit**: identical to the SwiftUI note — the component
  depends on neither AppKit nor UIKit. It lives under this codebase's
  `macOS` target today, but nothing about it is macOS-specific; the same
  type would compile unchanged linked into an iOS host with a
  CodeEditLanguages-compatible catalogue and a compatible contribution
  point. `HostLanguageVocabulary` MUST be declared `@MainActor`, so every
  access to `languageIdentifiers` and to the stored `contributionPoint`
  executes on the main actor. It MUST NOT declare conformance to
  `Sendable`; as a `public final class` with no `Sendable` conformance,
  isolated only by its `@MainActor` annotation, the compiler MUST confine
  every instance to the main actor's isolation domain and reject an
  attempt to use it from another isolation domain without an `await` hop.
- **WinUI 3**: no Windows App SDK or .NET type maps to CodeEditLanguages'
  bundled tree-sitter grammar catalogue, so the built-in half needs a
  locally maintained ordered table of language ids rather than an existing
  library. Port `HostLanguageVocabulary` as a plain C# class exposing an
  `IReadOnlyList<string> LanguageIdentifiers` computed property (a getter,
  never a cached field, mirroring `computed-not-cached`) that concatenates
  that table with the contribution point's own `ContributedLanguageIdentifiers`,
  deduplicating both halves with a `HashSet<string>` the way `Set<String>`
  does here. There is no `@MainActor` in .NET, so confine access with the
  same UI-thread affinity `LanguageContributionPoint`'s own C# port
  already requires (dispatch through the WinUI 3 dispatcher queue, not a
  bare lock). `HttpClient`, `System.Text.Json`, `Windows.Storage`, `Task`/
  `async`, `ObservableCollection`, and `INotifyPropertyChanged` have no
  role: this component performs no networking, serialization, or
  persistence, is entirely synchronous, and nothing here is bound to a UI
  or mutated in place — each read produces an independent, freshly built
  list.

