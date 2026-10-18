# Session-Daemon Core

Status: written and committed on the `stenographer/move-features-to-kitchen`
branch, not built or tested (one build and test pass is planned for the end of
the move). This is the toolkit's side of extracting the session-capture parts of
Stenographer's `stenographerd` so a second daemon (the Kitchen's `adkd`) can
link them. Placement and rationale for the whole effort: Stenographer's
`docs/designs/2026-10-16-shared-session-daemon-core.md` (its "As built" section
lists the departures from the design); the Kitchen's daemon: its
`docs/designs/2026-10-16-adkd-daemon.md`. The sections down to "Consumers" were
written as the plan; "As built" at the end corrects them where the code differs.

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

## Consumers

macOS 26 is the minimum for every product, and `AgenticToolkitDatabase` links
`AgenticToolkitCore` on macOS, which requires it. Any consumer still building
for macOS 14 (ADHDaemon, adhubapp's ADHDPipeline) is a bug in that consumer.

## Verification

Planned: the `AgenticToolkitMacOS` scheme tests (with `-skipPackagePluginValidation
-skipMacroValidation`) and a generic iOS build of `AgenticToolkitDatabase` after
the dependency change. The early moves (Core utilities, `DaemonDatabase`,
`SessionSchema`, ingestion up to the first transcript pass) were tested as they
landed; everything after that is committed untested. The iOS build has not been
run at all.

## As built

Directories now present in the toolkit (`packages/apple/AgenticToolkit`):

- `Database/Daemon/Core/`: `DaemonDatabase` (with `attachment(_:make:)` for per-database state), `SessionSchema` (migrations 001 to 045), `AccountResolver`, `DynamicSchema`, `SessionDaemonRuntime`.
- `Database/Daemon/Ingestion/`: spool, drainer, quarantine, socket handler, `EventIngestor`, `IngestionPipeline`, `EventIngestStore`, the ingestion-error log.
- `Database/Daemon/Sessions/`: session records and models, `SessionEnricher`, `LivenessService`, `RetentionService`.
- `Database/Daemon/Transcripts/`: `TranscriptStore` (+Metrics, +Turns, +Titles, +Lines, +Cursors), JSONL scanner, importer, `JSONLImportPass`, `ImportCoordinator`, `TranscriptTailer`, `QueuedPrompt`, conversations.
- `Database/Daemon/Settings/` (the settings KV extension), `Database/Daemon/Oversight/` (store, registry-side services, `OversightService`, `Scripts/` with `ScriptAnalyzer.live`), `Database/Daemon/AILog/` (`AIInteractionStore`, provider settings), `Database/Daemon/Sessions/DaemonSessionSummarizer`, `Database/Daemon/Preferences/PreferencesService`, `Database/Daemon/Routes/` (`SessionFeatureRoutes`, `SessionFeatureServices`, per-feature route files).
- `Core/Sessions/`, `Core/Routing/`, `Core/ClaudeHooks/` (installer, `HookCaptureCommand`, `HookEnvelopeBuilder`, `HookDropWriter`, `StatusLineCapture`, `DetachedProcess`, `GitContextFingerprint`), `Core/Process/ReadOnlyGit.swift`, `Core/Stenographer/ADKDIdentifiers.swift`.
- `Launch/`: `LaunchAgentSpec`, `LaunchAgentJob`, `DaemonBootstrap`, `DaemonTarget`, `DaemonAssessment`, `DaemonVersionGate`.
- `macOS/Features/Stenographer/AIConfig/StenographerAIConfigPush.swift`.

Corrections to the plan above:

- **Dependencies.** `AgenticToolkitDatabase` depends on `AgenticToolkitCore` and `AIPluginKit` on macOS only, and every `Database/Daemon` file is wrapped in `#if canImport(AgenticToolkitCore)`. `AIPluginKit` never imports Database; the invariant holds.
- **No `KeyValueSettings` protocol.** The daemon stores read provider configuration through the existing `ProviderSettingsReader` closure type; `Database/Daemon/AILog/DaemonDatabase+AIProviderSettings.swift` supplies it from `DaemonDatabase`. `AIFeature` and `DaemonPluginConfig` are in `AIPluginKit` as planned; `DaemonAIChat+Settings` was skipped, and `DaemonSessionSummarizer` is in `Database/Daemon/Sessions/`. `AIProviderConfigSync` moved from `AIPluginKit` to `Core/Stenographer/`, leaving public typealiases in `AIPluginKit`.
- **Type shapes** follow the code, not the plan's sketches: `DaemonDatabase` keeps the old `params: [any Sendable]` and `deadline: Duration?` signatures; `SessionEventSink` has two requirements; `IngestionPipeline` takes a `Paths` value; `ClaudeHookConfiguration` has `name`, `statusLineArguments`, `statusLineTapOnly` and `legacy`; `SessionDaemonConfiguration` has no oversight default.
- **Injected seams.** Core cannot import Database or DaemonKit, so the hook and status-line capture code takes the account lookups and the daemon POST as closures. The session upsert has an in-transaction post-upsert hook and `DaemonDatabase.init` takes a `statusLineIngest` closure, so billing and Usage stay out of the toolkit.
- **Migrations** 001 to 045 are `SessionSchema`; Stenographer appends 046 to 048. Never renumber. A new shared migration is numbered from 1001 upward, a daemon's own are 046 to 1000, and `DaemonDatabase` runs every version not yet recorded, in ascending order.
- **Parked review notes** from the Core utility move: `String.shortened(to:)` returns `limit - 2` characters and traps for a limit under 3 (behaviour kept, comment now says so); `ProcessEnv`'s header no longer claims to be file-listed in two targets. Not done: Stenographer-specific wording remains in a few generic Core files, and some `...ForTesting` members are public.
- **Fix after the first draft:** `JSONLImportPass` applied the first-import window forward in time; it reaches back from now.
