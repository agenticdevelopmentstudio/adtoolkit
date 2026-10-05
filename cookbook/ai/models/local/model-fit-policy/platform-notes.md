
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/AIPluginKit/ModelFitPolicy.swift`, alongside
  its test target `ModelFitPolicyTests.swift` and its consumers
  `LocalInferenceGuard.swift` and the macOS `ModelChooserContent`/
  `ModelChooserViewController`. It uses only `Foundation`'s `Double`,
  `String(format:locale:)`, and `Locale` (fixed to `en_US_POSIX` for the GB
  string) — nothing here is SwiftUI-specific; any host consumes
  `ModelFitPolicy` identically. `MemoryPressureLevel` is a
  `String`-raw-valued, `Sendable`, `Equatable` `enum`; `Tier` and `Verdict`
  are `Equatable`, `Sendable` `enum`s (`Verdict`'s refusal cases carry an
  associated `String` reason); `FitInfo` is an `Equatable`, `Sendable`
  `struct`. `ModelFitPolicy` itself is a case-less `enum` — an
  uninstantiable namespace — declaring no `Sendable`, `actor`, or
  `@MainActor` isolation of its own, so every `static` member is callable
  synchronously, with no `await`, from a `@MainActor` context or from
  inside any other actor's method; the test suite verifies both call sites
  directly.
- **Compose**: Model `Tier`/`MemoryPressureLevel` as Kotlin `enum class`es
  and `Verdict` as a `sealed interface` with `Allow`, `Block(reason: String)`,
  and `Deferred(reason: String)` implementations (Kotlin has no bare
  associated-value enum case, so a sealed hierarchy is the standard
  substitute). `FitInfo` becomes a `data class`. Use
  `String.format(Locale.ROOT, "%.1f GB", bytes / 1_000_000_000.0)` in place
  of the GB-string formatter's `en_US_POSIX` locale, and
  `Math.round(pct).toInt()` for the RAM-percentage computation (Kotlin's
  `Math.round` rounds half-up for positive values, matching Swift's
  `.rounded()` for the non-negative inputs this policy receives).
- **React/Web**: Model `Tier` and `MemoryPressureLevel` as TypeScript string
  union types and `Verdict` as a discriminated union
  (`{ kind: "allow" } | { kind: "block"; reason: string } | { kind: "deferred"; reason: string }`).
  Use `(bytes / 1_000_000_000).toFixed(1) + " GB"` in place of the GB-string
  formatter (`toFixed` is locale-independent, unlike `Intl.NumberFormat`,
  matching the source's deliberate use of a fixed locale rather than the
  caller's current one), and `Math.round(pct)` for the RAM-percentage
  computation.
- **AppKit / UIKit**: Identical to the SwiftUI note — this policy is
  UI-framework-agnostic; only the host application embedding `AIPluginKit`
  differs, never this contract.
- **WinUI 3**: Model `Tier` and `MemoryPressureLevel` as C# `enum`s, and
  `Verdict` as an `abstract record` with `Allow`, `Block(string Reason)`, and
  `Deferred(string Reason)` derived `record` types (C#'s closest match to a
  Swift enum with associated values) so a `switch` expression over `Verdict`
  can be exhaustive. `FitInfo` becomes a `readonly record struct` with `Text`
  and `Tier` properties. Expose `ModelFitPolicy` as a `static class` of
  `static` methods and `const`/`static readonly` fields — no
  `INotifyPropertyChanged`, `ObservableCollection`, `HttpClient`, or
  `Windows.Storage` is needed, since this policy performs no networking,
  persistence, or observable-property binding. Use
  `bytes.ToString("F1", CultureInfo.InvariantCulture) + " GB"` for the
  GB-string analogue (`InvariantCulture` is .NET's equivalent of the
  source's fixed `en_US_POSIX` locale) and
  `Math.Round(pct, MidpointRounding.AwayFromZero)` for the RAM-percentage
  computation, since .NET's default `MidpointRounding.ToEven` would
  silently diverge from Swift's `Double.rounded()` (which rounds half away
  from zero) at exact `.5` percentage boundaries.

