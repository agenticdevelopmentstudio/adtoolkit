
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectsCoordinator.swift`,
  built on `AppKit` (indirectly, through the `ProjectOpening`/
  `ProjectWindowManager` seam and the `ComposableTabsWindowController`/
  `WindowManager` frame cleanup) and `AgenticToolkitCore` (`GitRepo`,
  `ProjectDatabase`, `ProjectReconciler`, `GitRepoScanner`, `AppFeature`,
  `AppCommand`, `MenuContribution`, `CommandRegistry`, `Loggable`). It uses
  no SwiftUI API of its own; a SwiftUI host would still construct this same
  `@MainActor` class as a plain observable feature object, feeding a
  project-list view from `repos` and `isScanning` rather than modeling
  either as a `View`/`Scene`.
- **Compose**: Model `ProjectsCoordinator` as a plain `@MainActor`-confined
  (or main-dispatcher-confined) class holding `repos:
  List<GitRepo>`/`isScanning: Boolean`/`lastScanSummary:
  ProjectScanSummary?` as `MutableState`/`StateFlow` so a project-list
  composable recomposes on change. Represent `didChangeNotification` as a
  `SharedFlow<Unit>` emission rather than an OS-level notification.
  Reproduce **scan-runs-detached-then-hops-main** with a coroutine launched
  on a background dispatcher that switches back to the main dispatcher
  before mutating state — and, to close **scan-task-not-tracked**, store
  the launched `Job` so a Compose port's lifecycle teardown can cancel it.
- **React/Web**: A browser-hosted equivalent has no local git-repository
  filesystem to scan, so this component has no direct one-to-one web port;
  a server-backed project registry would model `repos`/`isScanning` as
  component state populated from an API call standing in for the scan,
  represent `didChangeNotification` as an ordinary event-emitter event, and
  serialize the re-entrancy guard (**scan-guards-reentrancy**) as a request
  flag checked before issuing a new "scan" API call.
- **AppKit / UIKit**: The source already is AppKit-adjacent (through
  `ProjectOpening`, `ProjectChooserWindow`, and `ProjectScanProgressWindow`);
  a UIKit (iOS) port would replace the `NSMenuItem`-backed
  `MenuContribution`s with whatever the iOS host uses for its equivalent
  command surface (a command palette, an action sheet), replace
  `ProjectWindowManager`'s language-server-shutdown seam with an iOS
  equivalent lifecycle hook, and would need its own answer for
  `WindowManager.shared.frames` (multi-window state restoration), since
  iOS's per-scene state restoration model differs from AppKit's; the
  scan/reconcile/persist sequence in `finishScan` ports unchanged.
- **WinUI 3**: Port `ProjectsCoordinator` as a plain C# class implementing
  the app's `IAppFeature` equivalent (mirroring `AppFeature`'s
  `Start()`/`Stop()`/`TerminateAsync()` hooks), holding `ObservableCollection<GitRepo>
  Repos`, `bool IsScanning`, and `ProjectScanSummary? LastScanSummary`, all
  touched only from the UI thread (`DispatcherQueue`) to mirror
  `@MainActor` confinement. Register the two commands
  (`CommandID.OpenProject`/`CommandID.ScanForProjects`) on the host's
  command-registry equivalent and add two `MenuFlyoutItem`s under the File
  menu, matching **menu-contributions-two-file-items**'s slot/order/key
  layout (`Ctrl+Alt+P` for Open Project, mirroring the macOS
  `[.command, .option]` combination). Back `database` with the same
  SQLite file through `Microsoft.Data.Sqlite` (see
  `adtoolkit://cookbook/workspace/projects/project-database`'s WinUI
  bullet for the schema/migration port) and call its `Checkpoint()`
  equivalent from `Stop()`, logging any exception there explicitly to
  close **stop-checkpoint-failure-unsignaled** rather than reproducing the
  silent `try?`. Run the scan on `Task.Run` (mirroring
  `Task.detached(priority: .utility)`) and marshal the result back with
  `DispatcherQueue.TryEnqueue` (mirroring `MainActor.run`); store that
  `Task` on the class so `Stop()`/`TerminateAsync()` can `await` or cancel
  it, closing **scan-task-not-tracked** rather than reproducing the gap.
  Reproduce **finish-scan-inserts-decrement-on-failure** and
  **finish-scan-deletes-decrement-and-clear-frames** exactly, including
  their `continue`/no-`continue` asymmetry, and reproduce
  **finish-scan-updates-no-decrement-on-failure**'s gap only if intentionally
  carrying the bug forward — otherwise decrement the matching summary count
  on a caught update failure, which is the fix this recipe's marker
  recommends. Represent `WindowManager.shared.frames`'s clear calls with
  whatever this host's window-frame-persistence store exposes for clearing
  a saved bounds/visibility record by window id.

