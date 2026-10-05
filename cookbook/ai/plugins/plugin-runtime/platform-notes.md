
- **SwiftUI (source)**: This is a plain Foundation/AppKit runtime layer, not
  a SwiftUI component, and it is the direct source for every role name used
  above: the plugins coordinator is `AIPluginsCoordinator` (a `@MainActor`
  subclass of the app's own `AppFeature` base, registering with
  `AppFeatureRegistry.shared`); the chat configuration provider interface is
  `ChatConfigProvider`; the chat-backend adapter is `AIPluginChatBackend`
  (`@unchecked Sendable`, guarded by its own `NSLock`, holding its provider
  `weak`); the provider chat session is `AIProviderChatSession`; the
  plugin-backed and single-configuration providers are
  `PluginChatConfigProvider` and `SingleConfigurationChatConfigProvider`; the
  legacy per-plugin config store is `PluginConfigStore`; the provider
  configuration, its settings, and its store are `AIProviderConfiguration`
  (`Codable`, `Sendable`, `Identifiable`, `Equatable`, `Hashable`), the
  `UserSettings` properties named in Provider Settings, and
  `AIProviderConfigStore`; default seeding and migration are
  `AIProviderDefaults` and `AIProviderMigration`; the configuration resolver
  is `AIProviderResolver`; the tool-calling chat session is `LocalChatSession`
  (`@unchecked Sendable`, its history/continuation guarded by `NSLock`, its
  busy flag guarded by a `Synchronization.Mutex<Bool>`); the MCP tool source
  is `MCPChatToolSource`; and the settings panel is `AIPanelViewController`.
  `AIPluginsCoordinator.swift` imports `AppKit` to compose menu/status-item
  contributions as an `AppFeature`; the actual chat UI (outside this
  component) binds to `AIChatViewModel`'s `@Published`/`ObservableObject`
  surface fed by `ChatBackendSession` or `LocalChatSession.events()`'s
  `AsyncStream`. State that would be `@Observable`/`ObservableObject`
  elsewhere is here plain `NSLock`- or `Synchronization.Mutex`-guarded
  mutable state on `@unchecked Sendable` classes, and persistence goes
  through `UserSetting<T>` (Combine-backed, Keychain-routed when `isSecure`).
- **Compose** (Android/Kotlin): `kotlinx.coroutines.flow.Flow`/`SharedFlow`
  replaces the `AsyncStream`/`AsyncThrowingStream` event pipelines;
  `kotlinx.coroutines.sync.Mutex` replaces `NSLock`/`Synchronization.Mutex`
  for the busy-guard and subscriber registry; the Keychain-routed secret
  fields become `EncryptedSharedPreferences` or an Android
  Keystore-backed store, and the plain fields become ordinary
  `SharedPreferences`/`DataStore`; the `.aiplugin` bundle + `dlopen` +
  `NSPrincipalClass` discovery model has no direct Android analogue — a
  static `ServiceLoader`-style registry or a signed dynamic-feature module
  would replace it, since arbitrary native code loading is far more
  restricted.
- **React/Web**: Async generators or an RxJS `Observable` replace
  `AsyncStream`; because JS is single-threaded, the `NSLock`/`Mutex` guards
  collapse to a plain boolean busy flag (no actual lock needed); the
  Keychain-routed secret store becomes a server-side vault or, client-side,
  a WebCrypto-wrapped value in `IndexedDB` (never plain `localStorage` for a
  secret); dynamic `import()` of a plugin module, driven by a fetched
  `descriptor.json`-equivalent manifest, replaces `Bundle` + `dlopen`
  discovery.
- **AppKit / UIKit**: The given sources already target AppKit; a UIKit
  (iOS) port would replace `AIPluginsCoordinator`'s `AppFeature`/menu-bar
  lifecycle hooks with `UIApplicationDelegate` equivalents, and would need
  to drop the `dlopen`-based `.aiplugin` bundle loading entirely — dynamic
  loading of unsigned code is not permitted under App Store code-signing —
  in favor of statically linked or App Extension–hosted plugins. The
  Foundation-level pieces (`NSLock`, `UserDefaults`, Keychain Services)
  need no change.
- **WinUI 3**: `System.Net.Http.HttpClient` performs the HTTP half of what
  `PluginTransport` drives (the given sources hand it an `AIRequestSpec`,
  never touch `HttpClient` directly), and `System.Diagnostics.Process` /
  `ProcessStartInfo` covers the subprocess (`.command`) transport case;
  `System.Text.Json` replaces `Foundation.JSONEncoder`/`JSONDecoder` for
  `descriptor.json` decoding and for `MCPChatToolSource`'s tool-schema and
  tool-argument JSON; `Windows.Storage.ApplicationData.Current.LocalSettings`
  replaces the plain (`isSecure: false`) `UserSetting` keys, and
  `Windows.Security.Credentials.PasswordVault` replaces the Keychain for
  secret fields; `System.Threading.SemaphoreSlim` or a plain `lock` object
  replaces `NSLock`/`Synchronization.Mutex` for `LocalChatSession`'s busy
  guard and `AIPluginChatBackend`'s subscriber registry;
  `System.Threading.Channels.Channel<T>` or `IAsyncEnumerable<T>` replaces
  `AsyncStream`/`AsyncThrowingStream` for `events()` and the plugin-transport
  event streams; `ObservableCollection<T>` + `INotifyPropertyChanged`
  replaces `@Published`/`ObservableObject` for the settings-backed
  configuration list and view models; and the Managed Extensibility
  Framework (`System.ComponentModel.Composition`) or a plain
  `Assembly.LoadFrom` call is the .NET analogue of `Bundle` + `dlopen` +
  `NSPrincipalClass` discovery — read a manifest first, load the assembly
  only on first use.

