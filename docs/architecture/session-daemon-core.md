# Session-Daemon Core

Status: designed, not built. This is the toolkit's side of extracting the
session-capture parts of Stenographer's `stenographerd` so a second daemon (the
Kitchen's `adkd`) can link them. Placement and rationale for the whole effort:
Stenographer's `docs/designs/2026-10-16-shared-session-daemon-core.md`; the
Kitchen's daemon: its `docs/designs/2026-10-16-adkd-daemon.md`. Everything below
is the plan; shapes are settled during implementation.

## What the toolkit gains

### A `Database/Daemon/` tier inside `AgenticToolkitDatabase`

Session feature code lands under `Database/Daemon/`, in these subdirectories:
`Core/` (the database handle, migrations, `SessionSchema`, settings KV,
`SessionDaemonRuntime`), `Ingestion/` (spool, drainer, quarantine, socket,
`EventIngestor`, `IngestionPipeline`), `Sessions/`, `Transcripts/`, `Oversight/`,
`AILog/`, `Preferences/` and `Routes/` (`SessionFeatureRoutes` and the
per-feature route files).

It is macOS-only, twice over, so iOS consumers of the framework are unaffected:

- the source path in `project.yml` carries `destinationFilters: [macOS]` (the
  precedent is Activity), and
- every file starts with `#if canImport(AgenticToolkitCore)`.

### New macOS-only dependencies

`AgenticToolkitDatabase` gains dependencies on `AgenticToolkitCore` and
`AIPluginKit`, both with `destinationFilters: [macOS]`. In `.abstractr.json`,
`apple-database.depends_on` becomes `["apple-core", "apple-pluginkit"]`.
`AgenticToolkitDatabaseTests` embeds Core, AIPluginKit and ADT (or the test
bundle crashes at load) and joins the `AgenticToolkitMacOS` scheme's tests.

### The invariant: dependencies point down only

`AIPluginKit` never imports Database. The daemon stores need provider
configuration, so the settings contract is defined below them: AIPluginKit gets
the `KeyValueSettings` protocol, `AIFeature`, the `DaemonPluginConfig` keys and
`DaemonAIChat+Settings`, and the Database tier implements the protocol on
`DaemonDatabase`. Nothing in `AgenticToolkitCore` or `AIPluginKit` may import
`AgenticToolkitDatabase`. The toolkit also never depends on DaemonKit, and
DaemonKit never depends on the toolkit; the daemons bridge the two.

### New `AgenticToolkitCore` directories

- `Core/Sessions/` : `HookEventType` (was `EventType`), `SessionStatus`,
  `ParsedEvent`, `SessionDaemonConfiguration`, `ClaudeHookConfiguration`,
  `SessionEventSink`
- `Core/Routing/` : `RouteRequest`, `RouteResponse`, `RouteTable`, with the
  paging helpers and the snake_case ISO-8601 encoder. `RouteResponse.json` must
  stay byte-identical to Stenographer's current `snakeCaseJSON`.
- `Core/ClaudeHooks/` : `ClaudeHookInstaller` (was `HookInstaller`, now taking a
  `ClaudeHookConfiguration`), `ClaudeStatusLine`, `HookEnvelopeBuilder`,
  `HookEnvCache`, `HookDropWriter`, `HookCaptureCommand`, `StatusLineCapture`
- `Core/Process/` : `ProcessLiveness`, `ProcessEnv`
- `Core/FileSystem/`, `Core/Concurrency/`, `Core/Text/`, `Core/Time/` :
  `AtomicFile`, `SerialAsyncGate`, `ShellQuote`/`ShortText`/`DigestHex`,
  `UTCDay`, all made public
- `Core/Stenographer/` (the existing DTO directory) also receives
  `IngestionErrorDTO`/`RetryProgressDTO`, `TrackingPreferenceResponse` and
  `ADKDIdentifiers.swift` (`ADKDIdentifiers`, `ADKDPaths`) beside
  `StenographerIdentifiers`

Hook installation takes the shared `~/.claude/.settings.lock` first, then the
configuration's own lock; that order is part of the installer's contract.

### `AgenticToolkitLaunch` generalised

The framework gains the launchd pieces now private to Stenographer:
`LaunchAgentSpec` and `LaunchAgentPlist.render(_:)`, `LaunchAgentAssessment` and
`LaunchAgentJob`, `DaemonBootstrap`, `DaemonTarget`, `DaemonAssessment`,
`DaemonRestartJob`, `DaemonPoll`, and `DaemonVersionGate`/`DaemonVersion`. The
health probe is a closure so Launch never imports DaemonKit.

### Feature-level additions

`macOS/Features/Stenographer/AIConfig/StenographerAIConfigPush.swift` pushes LLM
provider configuration to a daemon over HTTP (`POST /preferences/ai`), built on
the existing `SettingsSnapshotPush`. Names such as `StenographerHTTPClient` and
`StenographerDaemonService` stay as they are; renaming is a later cleanup.

## Verification

Planned: the `AgenticToolkitMacOS` scheme tests (with `-skipPackagePluginValidation
-skipMacroValidation`) at every toolkit commit, and a generic iOS build of
`AgenticToolkitDatabase` after the dependency change. None of it has been run.
