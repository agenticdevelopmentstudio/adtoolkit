
- **SwiftUI / AppKit / UIKit (Apple, already implemented)**: `PersonasModule` is a `@MainActor
  final class` conforming to `HTDVDataSource` — the navigation data source contract described
  neutrally above resolves here to `rootLevel()`/`child(for:)` returning `.level`/`.detail`/
  `.empty` cases, driving `FormSpec`/`FormSheet`/`FormViewController` from `AgenticToolkitHTDV`
  (see `adtoolkit://cookbook/ui/navigation/htdv`); shared Hub support types (`HubError`,
  `HubText`, `RailPath`, `Slug`, `JSONValue`, `FormDetails`) are reused rather than reimplemented
  per feature. `PersonasDataSource` is `Sendable` and exposes `list()`, `get(id:)`, `create(_:)`,
  `update(id:_:)`, `delete(id:)`, and `listServices()`, all `async throws`; the app repo
  implements it over `HubAPI`. `Persona`/`PersonaService`/`PersonaServiceModel` are `Codable,
  Sendable, Equatable, Identifiable` structs. `Persona.cannedChat`/`.chatStatus` are typed as the
  Hub `JSONValue` (hand-written `Decodable`, `==`/`hash(into:)` that treats `.int` and `.number`
  as the same JSON number) — not the unrelated, simpler `JSONValue` under `Sync/`. Errors from the
  data source are wrapped as `HubError.wrap(error)`.
- **React / TypeScript (web, already implemented)**: the client family under
  `packages/web/packages/data/src/personas/` is the wider of the two implementations — it covers
  services, provider templates, tool/may-act/approval grants, per-user tool consent, special
  interests, interest-document corpora, and demo preview, none of which the Apple side's given
  sources implement yet.
- **Jetpack Compose / Kotlin (Android, port target)**: the rootLevel→facet-rail→form navigation
  has no existing implementation to port from directly; a Compose port would mirror
  `HTDVDataSource`'s `rootLevel()`/`child(for:)` shape with a `ViewModel` exposing `StateFlow`
  screens, `kotlinx.serialization`-annotated `Persona`/`PersonaBody` data classes matching the
  wire field names, and a `sealed class` (or the `CHAT_STATUS_KINDS`-style string literal set) for
  facet ids so an unhandled facet fails to compile rather than silently falling through.
- **WinUI 3 / .NET (Windows, port target)**: a `Persona`/`PersonaBody` record pair serialized with
  `System.Text.Json.JsonSerializer` and `[JsonPropertyName]` attributes matching the wire field
  names; the facet rail as an `ObservableCollection<PersonaFacet>` bound to a
  `Microsoft.UI.Xaml.Controls.NavigationView` (or `TreeView`) for the two-level rail; the llm
  facet's service/model pickers as `Microsoft.UI.Xaml.Controls.ComboBox` bound to the same
  `serviceOptions`/`modelOptions` derivation `llmSpec` computes; and `DispatcherQueue.TryEnqueue`
  (or a `[MainThread]`-equivalent dispatcher) to keep persona mutation on the UI thread the way
  `@MainActor` does on Apple.
- **Cross-platform (backend contract, applies to every port)**: `canDemoChat`, `parseChatStatus`
  /`resolveChatStatus`, and `demoPreviewApi` are deliberately duplicated logic that must agree
  with the backend's authoritative implementation (`backend/src/adh/src/llm/canned/config.ts`,
  `backend/src/adh/src/db/schema/persona.ts`, `adh/docs/planning/demo-chat-ink-engine.md §10`); any
  port MUST keep its copy in lockstep with the backend rather than treating this recipe's
  TypeScript as the source of truth — "when they disagree, the backend wins," per `wire.ts`'s own
  comment.

