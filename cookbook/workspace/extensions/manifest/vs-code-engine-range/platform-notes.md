
- **SwiftUI**: the source (`VSCodeEngineRange.swift`, alongside
  `SemanticVersion.swift`, which it calls into for component bounds
  checking) is plain Foundation string parsing and value comparison with no
  dependency on SwiftUI or any view-layer framework. A port that keeps this
  component in Swift needs nothing beyond `Foundation`.
- **Compose**: model the private `Requirement` as a Kotlin `data class`
  carrying the same three base/must-equal-flag pairs plus `isMinimum`;
  parse with plain `String` splitting rather than a regular expression, and
  do not reach for a JVM semver library — none on the JVM model VS Code's
  specific "operator only clears flags, sub-1.0.0 has slack" grammar, which
  is not npm's caret rule. No Compose or Android SDK type is involved,
  since there is no UI surface to render.
- **React/Web**: model `Requirement` as a small immutable object with the
  six numeric/boolean fields plus `isMinimum`; parse with the same
  three-way `if`/`else if` operator check and manual `.`-splitting the
  source uses, and deliberately avoid npm's `semver` package for range
  evaluation — it implements exactly the caret/tilde/hyphen-range semantics
  this type's own doc comment says VS Code never implemented, so using it
  would silently reintroduce the wrong grammar. JavaScript's `number`
  covers the `Int32`-scale bound this type enforces via
  `SemanticVersion.maximumComponent` without a separate overflow check,
  though an explicit upper-bound comparison should still be ported alongside
  it rather than relied upon implicitly.
- **AppKit / UIKit**: identical to the SwiftUI note — the component depends
  on neither AppKit nor UIKit, so a macOS host consumes the same
  `AgenticToolkitCore` type directly with no translation.
- **WinUI 3**: there is no existing .NET or Windows App SDK type that
  implements VS Code's `engines.vscode` grammar, so it needs a direct C#
  port rather than an existing library. Port `VSCodeEngineRange` and
  `SemanticVersion` as plain C# `readonly struct`s carrying the same
  three-base/must-equal-flag representation, mirroring the sibling
  `ActivationEventMatcher` recipe's own guidance for this pair of types.
  Resist NuGet's `Semver` or `NuGet.Versioning` packages for the same reason
  the React/Web note gives: both implement npm/NuGet-style semver ranges,
  the grammar this type's doc comment explicitly says VS Code is not.
  Guard each parsed component against `int.MaxValue` explicitly (mirroring
  `SemanticVersion.maximumComponent`), so a manifest with an absurd version
  component fails a `TryParse`-style construction instead of throwing an
  unhandled `OverflowException` deep inside a later comparison.
  `Task`/`async`, `HttpClient`, `System.Text.Json`, `Windows.Storage`,
  `ObservableCollection`, and `INotifyPropertyChanged` have no role here:
  every operation is a synchronous, side-effect-free struct computation
  with no I/O, no serialization, and no observable mutable state to notify
  on.
- **value-semantics**: On Apple platforms `VSCodeEngineRange` conforms to `Sendable`, `Hashable`, and `CustomStringConvertible`; its `Requirement` storage is all `let`.

