
- **Swift (source)**: This file targets macOS today, via the
  `AgenticToolkitCore` framework target (`project.yml`); nothing in it —
  plain `Codable`/`Sendable` structs and enums over Foundation's
  `JSONDecoder` and `URL` — depends on `AppKit`, `UIKit`, or any other
  platform framework, so the same source would decode identically if the
  target grew an iOS platform tomorrow.
- **React/Web/TypeScript**: A hand-rolled parser or a schema library such as
  `zod`/`io-ts` replaces `Codable`; URL-shaped fields are typed `string` and
  parsed lazily with the global `URL` constructor (or a `try`/`catch`
  wrapper around it) only inside the equivalent of `iconURL`/`sha256URL`,
  never eagerly at the top-level parse, to preserve the
  **url-shaped-fields-decoded-as-string** isolation; `installability` is a
  plain function returning a discriminated union
  (`{ kind: "installable" } | { kind: "engineIncompatible"; range } | ...`)
  rather than a class hierarchy.
- **Compose/Android (Kotlin)**: `kotlinx.serialization` with a `data class`
  per response shape replaces `Codable`; a `sealed interface` with
  `data class`/`data object` cases is the equivalent of
  `OpenVSXInstallability`, and `installability` becomes a plain `fun`
  returning that sealed type — a `when` expression over it, rather than a
  `Boolean`, is how a caller renders each refusal distinctly.
- **WinUI 3 (C#)**: `System.Text.Json` (`JsonSerializer`, `JsonDocument`)
  replaces `Codable`, with URL-shaped registry fields typed `string`
  properties, never `System.Uri`, and parsed on demand inside computed
  properties (`Uri.TryCreate`, never the throwing `Uri` constructor) to
  preserve the same per-accessor isolation. `installability`'s required
  fields — the equivalent of `namespace`, `name`, and `version` failing the
  whole decode — need the C# `required` keyword on those three properties
  (or a custom `JsonConverter<T>` that checks for their presence explicitly)
  because `System.Text.Json` otherwise leaves a missing non-nullable
  `string` property at its default rather than throwing, which would
  silently drop **search-page-array-decode-is-all-or-nothing**'s "throws for
  the whole page" behavior. A `SemanticVersion`-equivalent `readonly record
  struct` and a ported `VSCodeEngineRange` parser stand in for the two
  Swift helper types this file depends on; `OpenVSXInstallability` itself
  becomes a `record`-per-case discriminated union (an `abstract record` base
  with one `sealed record` per case, or a single `record` with an `enum Kind`
  discriminant plus optional payload fields) rather than an
  `ObservableCollection<T>` or `INotifyPropertyChanged` type, since nothing
  in this contract needs mutation notification — the verdict is a one-shot,
  immutable computation.

