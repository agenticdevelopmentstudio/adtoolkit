
- **SwiftUI**: A SwiftUI host would keep `BucketsDataSource`,
  `BucketsModels`, and `BucketsTopic`'s pure static helpers
  (`tableName(from:)`, `tableCount(_:)`) unchanged, since none of them
  depends on AppKit/UIKit or on `BucketsTopic`'s own `@MainActor` class,
  and would drive `createSpec`/`createTableSpec`/`settingsDetail`/`tableDetail`'s
  `FormSpec` values through the same `FormState` bridge described in the
  related HTDV Engine recipe's SwiftUI note, presenting the "New bucket"/
  "New table" forms with `.sheet` in place of `FormSheet.present`.
- **Compose**: Model `BucketsDataSource` as a suspend-function interface
  and `Bucket`/`BucketTable`/their create/update payloads as `@Serializable`
  Kotlin data classes with the same default-tolerant decoding (`kind`
  defaulting to `"custom"` via a custom deserializer or a default
  constructor parameter); reimplement `tableName(from:)` with
  `String.lowercase()` plus a manual scan keeping only ASCII letters and
  digits and collapsing runs of everything else to `"_"`, matching the
  no-leading/trailing-underscore behavior exactly; present the create
  forms as a `ModalBottomSheet`/`AlertDialog` in place of `FormSheet.present`.
- **React/Web**: Model `BucketsDataSource` as an async client interface
  returning the same shapes, with `Bucket` decoding applying the same
  `kind ?? "custom"` and optional-field defaults at the point a response
  is parsed; reimplement `tableName(from:)` as a small function that
  lowercases the input, iterates its code points keeping ASCII
  `a`-`z`/`0`-`9`, and collapses runs of other code points (including
  non-ASCII ones) into a single underscore with no leading or trailing
  underscore, exactly mirroring the Swift scan rather than using a
  locale-aware `String.replace`. Present the create/edit forms as a modal
  dialog in place of `FormSheet.present`, and keep the same
  precheck-then-server-conflict double guard for duplicate names.
- **AppKit / UIKit**: This is the source: `BucketsDataSource.swift`,
  `BucketsModels.swift`, and `BucketsTopic.swift` hold no AppKit/UIKit
  import of their own — `BucketsTopic` depends only on `Foundation` and the
  `AgenticToolkitHTDV` module (`HTDVItem`, `HTDVLevel`, `HTDVChild`,
  `HTDVCreateAction`, `FormSpec`/`FormSection`/`FormAction`/`FormDeleteAction`/
  `FormActions`), and presents its create sheets through the shared
  `FormSheet.present` rather than any AppKit/UIKit API of its own.
- **WinUI 3**: Model `BucketsDataSource` as a C# interface with nine
  `Task`-returning methods, backed by `HttpClient` and `System.Text.Json`
  for a concrete implementation (not among the given sources). Model
  `Bucket`/`BucketTable`/their create/update payloads as C# records with
  `[JsonPropertyName]` attributes; give `Bucket` a custom `JsonConverter`
  (or a `[JsonConstructor]` with nullable parameters) so a missing `kind`
  defaults to `"custom"` and a missing `metadata`/`createdAt`/`updatedAt`
  defaults to `null`, and expose `Description`/`IsBuiltIn` as computed
  read-only properties exactly mirroring `Bucket.description`/`isBuiltIn`.
  Reimplement `tableName(from:)` with `char.IsAsciiLetterOrDigit` and a
  `StringBuilder`, appending `'_'` only when a pending-separator flag is
  set and the builder is non-empty — reproducing the no-leading/trailing-
  underscore behavior exactly, including that a non-ASCII character (an
  accented letter, a CJK character) is a separator, not a candidate for
  transliteration. Use a `ContentDialog` (or a `TeachingTip`-hosted form)
  in place of `FormSheet.present` for the "New bucket"/"New table" flows,
  and compare names with `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)`
  in place of `caseInsensitiveCompare`, keeping the same
  precheck-then-server-conflict double guard for both buckets and tables.
- **Swift types (reference implementation)**: `BucketsDataSource` is a `Sendable`,
  `AnyObject`-constrained protocol with nine `async throws` operations (an implementation is a class
  or actor, typically an actor or `@unchecked Sendable` class wrapping a network client).
  `BucketMetadata`, `Bucket`, `BucketCreate`, `BucketUpdate`, `BucketTable`, `BucketTableCreate`, and
  `BucketTableUpdate` are `Codable`, `Hashable`, `Sendable` structs (`Bucket` and `BucketTable` also
  `Identifiable`); `Bucket.init(from:)` uses `decodeIfPresent` for the four tolerated keys and
  `Bucket.description` is `metadata?.description ?? ""`. `BucketsTopic` is `@MainActor` and `final`,
  conforming to `EcosystemTopicProvider`, so its single stored `dataSource` is never mutated from
  another isolation domain; `tableName(from:)` is `nonisolated static` so the create-table
  `FormAction.perform` closure can call it off the main actor.

