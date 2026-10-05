
- **SwiftUI**: A SwiftUI host would keep `CustomersDataSource`,
  `CustomersModels`, and `CustomersTopic`'s pure static helpers
  (`fieldSpec(isRequiredEmail:)`, `input(from:ecosystemID:)`) unchanged,
  since none of them depends on AppKit/UIKit or on `CustomersTopic`'s own
  `@MainActor` class, and would drive `createSpec`/`detail`'s `FormSpec`
  values through the same `FormState` bridge described in the related
  HTDV Engine recipe's SwiftUI note, presenting the "New user" form with
  `.sheet` in place of `FormSheet.present`.
- **Compose**: Model `CustomersDataSource` as a suspend-function interface
  and `Customer`/`CustomerInput` as `@Serializable` Kotlin data classes
  with every descriptive field nullable, matching the source's own "every
  descriptive field is nullable on the wire" contract; reimplement
  `input(from:ecosystemID:)`'s asymmetry exactly — trim-only for `email`,
  blank-to-`null` for the other four — and present the "New user" form as
  a `ModalBottomSheet`/`AlertDialog` in place of `FormSheet.present`.
- **React/Web**: Model `CustomersDataSource` as an async client interface
  returning the same shapes, with a TypeScript `Customer` type whose
  descriptive fields are `string | null` and a `CustomerInput` type whose
  `email` is a required `string` and the other four are optional;
  reimplement the email-pattern check with the same regex literal
  (`emailPattern`) rather than a browser's native email input validation,
  so the user-facing message stays `"Enter a valid email address."` on
  every platform. Present the create/edit forms as a modal dialog in place
  of `FormSheet.present`, and keep the same precheck-then-server-conflict
  double guard for duplicate emails.
- **AppKit / UIKit**: This is the source: `CustomersDataSource.swift`,
  `CustomersModels.swift`, and `CustomersTopic.swift` hold no AppKit/UIKit
  import of their own — `CustomersTopic` depends only on `Foundation` and
  the `AgenticToolkitHTDV` module (`HTDVItem`, `HTDVLevel`, `HTDVChild`,
  `HTDVCreateAction`, `HTDVDetail`,
  `FormSpec`/`FormSection`/`FormAction`/`FormDeleteAction`/`FormActions`),
  and presents its create sheet through the shared `FormSheet.present`
  rather than any AppKit/UIKit API of its own.
- **WinUI 3**: Model `CustomersDataSource` as a C# interface with five
  `Task`-returning methods, backed by `HttpClient` and `System.Text.Json`
  for a concrete implementation (not among the given sources). Model
  `Customer` as a C# record with `[JsonPropertyName]` attributes and
  nullable reference types for every descriptive field, and expose
  `Label`/`Sublabel` as computed read-only properties exactly mirroring
  `Customer.label`/`sublabel`'s fallback chain, including that a
  whitespace-only value is treated as missing. Model `CustomerInput` as a
  record whose `Email` is a non-nullable `string` and whose other four
  properties are nullable, serialized with
  `JsonIgnoreCondition.WhenWritingNull` to reproduce "optional fields
  encode as absent, never `null`." Use a `ContentDialog` (or a
  `TeachingTip`-hosted form) in place of `FormSheet.present` for the
  "New user" flow, and compare emails with
  `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)` in place of
  `caseInsensitiveCompare`, keeping the same
  precheck-then-server-conflict double guard.
- **Swift types (reference implementation)**: `CustomersDataSource` is a `Sendable`,
  `AnyObject`-constrained protocol with five `async throws` operations (an implementation is a class or
  actor). `Customer` is a `Codable`, `Hashable`, `Sendable`, `Identifiable` struct with `String?`
  descriptive fields and no custom `init(from:)`/`encode(to:)`; `CustomerInput` is a `Codable`,
  `Hashable`, `Sendable` struct. `Customer.label` is `HubText.nonBlank(displayName) ??
  HubText.nonBlank(email) ?? "—"`. `CustomersTopic` is `@MainActor` and `final`, conforming to
  `EcosystemTopicProvider`, with `init(dataSource:)`; its `input(from:ecosystemID:)` is `nonisolated
  static` so the `FormAction.perform` closure can call it off the main actor; email trimming uses
  `.trimmingCharacters(in: .whitespacesAndNewlines)` and the duplicate precheck uses
  `.caseInsensitiveCompare(_:) == .orderedSame`.

