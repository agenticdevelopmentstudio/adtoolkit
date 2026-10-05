
- **Web (source platform)**: a fetch/promise-based HTTP call, a cancellation
  controller, and a query-string builder are the native browser primitives
  this recipe's source is written against; a syntax-highlighting library
  (loaded dynamically at first use) is the only third-party runtime
  dependency among the given sources, and its cached highlighter supports the
  `github-light`/`github-dark` themes and the `json`/`bash`/`javascript`
  languages. The server-usable entry point in source is a file with no
  client-rendering directive, so it can be imported from server-only code
  without pulling client-component bundling requirements with it; the
  client-facing entry point deliberately omits the endpoint-lookup functions
  and the generated endpoint metadata constant, and reaches the shared lookup
  functions via their package path rather than a relative path so both entry
  points observe the same module-level cache instance instead of each
  forking its own copy. The exit-guard proxy is built once via a
  memoization primitive with an empty dependency array so its object
  identity is stable across re-registrations. The viewer state's dependence
  on an optional context-based authentication provider (absent, it settles
  to signed-out defaults instead of an unsettled loading state), and the CRUD
  resource state's use of a response-body-discarding request helper and a
  JSON-parsing request helper from the auth client recipe for the actual
  network calls, are specific to this source's implementation in
  `@agentic-toolkit/api-explorer` and `@agentic-toolkit/crud`.
- **Apple (Swift, not in source)**: `URLSession` (with `URLRequest`) is the
  equivalent of the request builder/executor; `Codable` is the equivalent of
  the schema-driven example/field-description derivation (though Codable is
  compile-time-typed, so a dynamic schema-to-example projection has no direct
  one-to-one match); `Task`/`async`/`await` replace the promise-based flow; a
  stable `AnyObject` proxy under `@MainActor` would replace the exit guard
  channel's memoized proxy.
- **Android (Kotlin, not in source)**: `OkHttp` or `Retrofit` plus
  `kotlinx.serialization` (or Moshi) replace the request builder/executor and
  the schema-derived example/field logic respectively; Kotlin
  `Flow`/`StateFlow` replace the loading/fetching state pair exposed by the
  CRUD resource state; a `Mutex`-guarded sequence counter would replace the
  out-of-order-response guard.
- **WinUI 3 (Windows, not in source)**: `HttpClient` replaces the request
  builder/executor; `System.Text.Json` replaces the schema example/field
  derivation (again, statically-typed deserialization has no exact analogue
  to the dynamic example synthesis); `Windows.Storage` has no counterpart
  here since no given source persists data locally; `Task`/`async`/`await`
  replace the promise-based flow; `ObservableCollection<T>` plus
  `INotifyPropertyChanged` replace the rows/loading/fetching state that the
  CRUD resource state exposes to a render; a WinUI 3 port would need its own
  out-of-order-response guard (e.g. a monotonically increasing request-token
  field checked before applying a completed request's result) since
  `HttpClient` provides no built-in equivalent to the sequence guard.
- **Python (not in source)**: `httpx` (or `requests`) replaces the request
  builder/executor; `dataclasses` or `pydantic` models replace the
  schema-driven example/field derivation; there is no direct Python analogue
  to the state machine in the CRUD resource state since Python is not paired
  with a UI render loop in this codebase — a port would need to re-derive the
  loading/fetching distinction against whatever calling convention it adopts
  (a callback, an async generator, or similar).

