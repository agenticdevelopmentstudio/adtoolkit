
- **SwiftUI**: The source itself:
  `packages/apple/AgenticToolkit/Core/Extensions/ExtensionUpdateCheck.swift`,
  part of the macOS-only `AgenticToolkitCore` framework target. It has no
  SwiftUI dependency — `ExtensionUpdateCheck` is plain `Foundation`/`OSLog`
  code. A SwiftUI settings screen listing available updates would call
  `check(_:)` from a `Task`, typically inside an `@Observable` view model
  that republishes the resulting `ExtensionUpdateReport` for the view to
  render, since `ExtensionUpdateCheck` itself has no observation mechanism
  and is a plain value type constructed fresh (or held) by that view model.
- **Compose**: Model `ExtensionUpdateCheck` as a Kotlin class holding an
  `OpenVSXClient`-equivalent and a `SemanticVersion`-equivalent host version,
  exposing `suspend fun check(installed: List<LoadedExtension>): ExtensionUpdateReport`
  and `suspend fun update(installed: LoadedExtension): ExtensionUpdate?`.
  Use `coroutineScope { installed.map { async { outcome(it) } }.awaitAll() }`
  in place of `withTaskGroup`, then `sortedBy { it.identifier }` on both
  result lists — Kotlin's `sortedBy` is a stable sort, the same property the
  Swift port relies on for a deterministic duplicate-identifier order. Model
  `ExtensionUpdateError` as a `sealed class` with `NoPublisher` and
  `VersionNotComparable` subtypes, and classify caught exceptions the same
  way `reason(for:)` does, with an `else` branch mapping to
  `RegistryUnreachable`.
- **React/Web**: Port to an async function pair,
  `async function checkForUpdates(installed: LoadedExtension[]): Promise<ExtensionUpdateReport>`
  and `async function updateFor(installed: LoadedExtension): Promise<ExtensionUpdate | null>`,
  using `Promise.allSettled` over one `outcomeFor(extension)` promise per
  installed extension (never `Promise.all`, since one rejection must not
  fail the batch), then sorting both result arrays by `identifier` with
  `Array.prototype.sort` — stable since ES2019, giving the same
  duplicate-identifier behavior as the Swift stable sort. Represent
  `ExtensionUpdateError` as a discriminated union
  (`{ kind: "no-publisher"; identifier: string } | { kind: "version-not-comparable"; installed: string; published: string }`)
  and classify a caught fetch failure by inspecting the HTTP status (404 vs.
  anything else) the same way `reason(for:)` does.
- **AppKit / UIKit**: No divergence from the SwiftUI bullet above — the
  source is framework-agnostic `Foundation`/`OSLog` code called identically
  from an AppKit-hosted caller. `AgenticToolkitCore` targets only macOS
  today; an iOS caller would first need the framework made available to an
  iOS target, but `ExtensionUpdateCheck` itself needs no AppKit/UIKit-specific
  change.
- **WinUI 3**: Port to a plain class,
  `internal sealed class ExtensionUpdateCheck`, constructed with an
  `OpenVsxClient` (wrapping `System.Net.Http.HttpClient` the way the source's
  `OpenVSXClient` wraps `URLSession`) and a `Version`-equivalent
  `hostVersion` — .NET's built-in `Version` type compares
  `major`/`minor`/`build`/`revision` the way `SemanticVersion` compares
  `major`/`minor`/`patch`, though its parser is more permissive than the
  source's `SemanticVersion.init?`, so the port should still reject any
  string with a prerelease or build-metadata suffix explicitly to preserve
  `versions-must-both-parse`. Implement `CheckAsync(IEnumerable<LoadedExtension>)`
  with `await Task.WhenAll(installed.Select(e => OutcomeForAsync(e)))`, where
  each `OutcomeForAsync` call already catches its own exceptions (mirroring
  `outcome(for:)`, never letting one candidate's `HttpRequestException` fault
  the `Task.WhenAll`), then order both result lists with
  `.OrderBy(x => x.Identifier, StringComparer.Ordinal)` — `Ordinal`, not a
  culture-aware comparer, to match the source's plain `String` `<` operator.
  Classify failures with a status-code check against `HttpStatusCode.NotFound`
  for `.notPublished` and every other failure (non-2xx, `TaskCanceledException`
  on timeout, `HttpRequestException` on no connectivity) into
  `RegistryUnreachable`, using `System.Text.Json` (`JsonSerializer`) in place
  of `JSONDecoder` for the registry's detail response and `Microsoft.Extensions.Logging`'s
  `ILogger.LogDebug` in place of `Logger.debug` for the one log line.

