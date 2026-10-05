
- **SwiftUI / AppKit / UIKit**: Not applicable — no Swift declaration
  exists in this domain; there is no Apple-side Teams implementation to
  note concurrency behavior for.
- **React/Web**: This is the sole reference implementation. Both clients
  (`teamsApi`, `teamMembersApi`) are plain objects of `async` functions
  over `fetch` (via `authedJson`/`authedRequest`); neither exports a React
  hook, unlike `hub-domain-ecosystems`'s
  `use-workspace-default-ecosystem.ts` — every export here is
  framework-agnostic and usable from a plain script or a test.
- **Windows / WinUI 3**: No WinUI 3 implementation exists in this domain. A
  port would model `Team`/`TeamMember` as plain records (or `record`
  types), route every call through a shared `HttpClient` with a Bearer
  token attached (the equivalent of `authedJson`/`authedRequest`), use
  `System.Text.Json` for the request/response bodies (mirroring
  `compact`'s undefined-vs-null distinction by only serializing properties
  actually set, e.g. via `JsonIgnoreCondition.WhenWritingNull` combined with
  nullable value types rather than omission), and reproduce
  `teamsApi.get`'s null-on-404 contract with an explicit
  `HttpStatusCode.NotFound` check rather than a bare `catch` — closing the
  gap this recipe flags in the web source
  (team-get-swallows-any-error-as-not-found). `async`/`Task` maps directly
  from this domain's `Promise`-returning methods; no `ObservableCollection`
  or `INotifyPropertyChanged` is needed, since nothing here is observed
  state — every call returns a fresh value.
- **Android**: No Android implementation exists in this domain. A Kotlin
  port would face the identical 404-vs-any-error distinction as WinUI 3
  above (checking the HTTP response code explicitly, e.g. via Retrofit/
  OkHttp, rather than catching every `IOException` alike), and would model
  `compact`'s undefined-vs-null distinction with a `Map<String, Any?>` (or
  a sealed "patch" type) rather than a Kotlin `data class`'s all-or-nothing
  field set, since a `data class` cannot distinguish "not set" from "set to
  null" the way this domain's `Partial<TeamInput>` does.
- **Python**: No Python implementation exists in this domain. A port would
  route calls through a shared `httpx`/`requests` session carrying the
  Bearer token, model `Team`/`TeamMember` as `dataclass`es or Pydantic
  models, and reproduce `compact` with a helper that drops keys whose value
  is a sentinel "unset" (not Python's own `None`, which — as in the
  TypeScript source — must remain sendable as an explicit clear).

