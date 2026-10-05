
- **SwiftUI/AppKit/UIKit**: This is the reference implementation.
  `Foundation.Process` (via `SubprocessChannel`) launches the server;
  `JSONRPC`/`LanguageServerProtocol`/`LanguageClient` frame and type the
  protocol; Swift `actor`s (`LanguageServerSession`, `DocumentSyncPipeline`)
  and `@MainActor` `ObservableObject`s (`DiagnosticStore`,
  `LanguageServerRegistry`, `LanguageServerDocumentSync`) provide isolation;
  `AsyncStream` carries `publishedDiagnostics`/`stateChanges`; the Keychain
  (via `isSecure: true` settings) stores secrets. Failure descriptions
  conform to `LocalizedError`; logging goes through the `Loggable`
  protocol's default subsystem (`Bundle.main.bundleIdentifier`) and a
  per-type category. The command's absolute-path precondition is stated in
  `LanguageServerConfiguration.command`'s doc comment because a sandboxed
  app's `PATH` differs from a terminal's; the component does not enforce it
  before spawning the process.
- **Compose/Android**: `ProcessBuilder`/`Runtime.exec` replaces
  `Foundation.Process`; a hand-rolled or third-party JSON-RPC/LSP client
  library replaces `JSONRPC`/`LanguageServerProtocol`; Kotlin coroutines with
  a `Mutex`-guarded class replace an `actor`; `StateFlow`/`SharedFlow`
  replace `AsyncStream`; the Android Keystore (via `EncryptedSharedPreferences`
  or Jetpack Security) replaces the Keychain for secrets.
- **React/Web**: There is no direct browser analog for spawning a local
  subprocess; a web-hosted port would need a companion native/host process
  (e.g. a desktop shell's IPC bridge) to launch the language server, with
  `postMessage`/WebSocket framing standing in for the JSON-RPC channel;
  secrets would need to live in the host's secure storage, never in web
  `localStorage`.
- **WinUI 3**: `System.Diagnostics.Process` replaces `Foundation.Process`
  for spawning the server; `System.IO.Pipes` or the process's redirected
  standard streams carry the JSON-RPC frames, with `System.Text.Json`
  replacing `Foundation.JSONDecoder`/`JSONEncoder` for every LSP message.
  `Task`/`async`-`await` with a `SemaphoreSlim`-guarded class is the
  idiomatic equivalent of an `actor` for `LanguageServerSession` and
  `DocumentSyncPipeline`; an `ObservableCollection`/`INotifyPropertyChanged`-backed
  class, or a C# `event`, replaces the `@Published` properties on
  `LanguageServerRegistry`/`DiagnosticStore`; a `System.Threading.Channels.Channel<T>`
  replaces `AsyncStream` for `publishedDiagnostics`/`stateChanges`.
  `Windows.Security.Credentials.PasswordVault` replaces the Keychain for
  routing per-server secret environment values.

