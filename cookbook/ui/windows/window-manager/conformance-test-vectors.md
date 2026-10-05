
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| wm-001 | terminating-default, terminating-latch | Fresh manager; post the app-termination notification | The termination flag is false before, true after (`WindowManagerTerminationTests`) |
| wm-002 | terminating-consumer | Visibility-persisting controller shown (visibility true); termination flag true; call the window-will-close callback | Persisted visibility stays true |
| wm-003 | terminating-consumer | Same, termination flag false; call the window-will-close callback | Persisted visibility becomes false |
| wm-004 | recent-limit-write | Recent-windows-count set to 7, apply the recent-document count from settings; then set to 3 and apply again | The platform's recent-documents limit setting reads 7, then 3 (`WindowManagerRecentsTests`) |
| wm-005 | recent-limit-mirror, recent-limit-on-init | Touch the shared window manager; set recent-windows-count to 12; wait one main-queue turn | The platform's recent-documents limit setting reads 12 |
| wm-006 | register-window, restore-builds-saved-visible | Persist alpha visible, beta hidden, gamma never; register all three; run the launch-restore pass with policy "always" | Built set is {alpha} (`WindowManagerSimulatedRelaunchTests`) |
| wm-007 | register-window | Register a window id without running the launch-restore pass | Factory has not run |
| wm-008 | register-window | Register two factories under the same id; run the launch-restore pass | Only the second factory runs |
| wm-009 | restore-visibility-pass, restore-visibility-rule | Registered visibility-persisting controller with persisted visibility true; run the launch-restore pass | Window is shown |
| wm-010 | restore-visibility-rule | Same with persisted false, and again with no persisted value | Window stays closed in both cases |
| wm-011 | restore-missing-factory-log | The platform-preferences storage backend holding visibility true for "ghost"; no factory, no controller; run the launch-restore pass | One error log naming "ghost" |
| wm-012 | reopen-no-app | A process with no running app instance; run the reopen-recents step | Returns; no crash; nothing opened |
| wm-013 | reopen-policy | The reopen decision for "match the system setting"/"always"/"never" with the system default true and false | true/false; true/true; false/false |
| wm-014 | reopen-disabled-closes, reopen-disabled-keeps-others | Reopen-on-launch policy "never"; one document window and one non-document window open; run the reopen-recents step | Document window's controller closed; non-document window still open |
| wm-015 | reopen-enabled-opens-recents | Reopen-on-launch policy "always"; recents [A, B]; A already open | One open request, for B, with display requested |
| wm-016 | close-ignored | Record an interaction with kind "close" for a document controller whose spec includes "include in recents" | No recent URL noted |
| wm-017 | spec-gate | A "show" interaction for a document controller whose spec does not include "include in recents" (and one with no spec) | No recent URL noted |
| wm-018 | document-recent | A "show" interaction for a controller with default behavior and document URL U | The platform's recent-documents API is passed U once |
| wm-019 | registry-register, registry-lookup | Register controller a; look up a and b | Returns the controller for a, nothing for b |
| wm-020 | registry-empty-id | Register a controller with an empty window id | The registered-ids list is empty |
| wm-021 | registry-registered-ids, registry-has-visible | Register a controller without showing it | The registered-ids list contains it; the has-visible-window flag is false (`WindowRegistryVisibilityTests`) |
| wm-022 | registry-visible-ids, registry-has-visible | Register and show a controller | The visible-ids list contains it; the has-visible-window flag is true |
| wm-023 | registry-has-visible | Show then dismiss the only controller | The has-visible-window flag is false |
| wm-024 | registry-has-visible | One closed and one shown controller | The has-visible-window flag is true |
| wm-025 | registry-lookup, registry-no-pruning | Register, show, dismiss, release the only strong reference | Looking the controller up returns nothing; the has-visible-window flag is false |
| wm-026 | storage-visibility-tristate | Fresh key; load; save false; load | Nothing, then false |
| wm-027 | storage-remove | Save state and visibility for w; remove both; load both | Both return nothing |
| wm-028 | storage-key-format, namespace-default | Namespace empty; save visibility for "log" with default prefixes | Underlying key is `WindowVisible_log` |
| wm-029 | namespace-default, namespace-qualify | Qualify the key `WindowState_log` with no namespace set | `WindowState_log` (`WindowStateNamespaceTests`) |
| wm-030 | namespace-token, namespace-stable | Isolate to the path `/a/worktree/Stenographer.app` | Current prefix is `Instance2e03b243_`; same value on a repeat call |
| wm-031 | namespace-token | Isolate to the path `/another/worktree/Stenographer.app` | Current prefix is `Instance30aace28_`, differs from wm-030 |
| wm-032 | namespace-no-raw-path | Isolate to the path `/Users/someone/secret-project/Stenographer.app` | Current prefix contains neither "someone" nor "secret-project" |
| wm-033 | storage-namespace-late-binding, userdefaults-visible-ids | Save state and visibility true for "log" un-namespaced; isolate; load both and list visible ids; save visibility false; reset; load | Namespaced loads are nothing and "log" is not listed; after reset visibility is true and "log" is listed |
| wm-034 | namespace-reset | Isolate to any path, then reset the namespace | Current prefix is the empty string |
| wm-035 | storage-state-json | Save a state through the settings-store-backed storage backend over a platform-preferences-backed store; load through the platform-preferences storage backend | Equal state returned |
| wm-036 | settings-store-non-bool-visibility | Write the string "x" under `WindowVisible_w`; load via each implementation | The settings-store-backed backend returns false; the platform-preferences backend returns nothing |
| wm-037 | visible-ids-default | Storage that omits the visible-window-ids operation | Returns an empty list |
| wm-038 | screenshot-capture | The own-window-capture operation for window handle 0 | Nothing (`WindowScreenshotTests`) |
| wm-039 | screenshot-png-offscreen | The write-PNG operation on a never-ordered-in (off-screen) window | Returns false; no file at the URL |
| wm-040 | screenshot-png-success | The write-PNG operation on an on-screen window owned by the process, writable URL | Returns true; file holds PNG data |
| wm-041 | screenshot-png-failure | On-screen window; URL in a non-existent directory | Returns false |
| wm-042 | single-screen-manager | A window manager constructed with a screen provider and storage but no screen manager | Its frame manager uses the shared screen manager |

