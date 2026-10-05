
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| recents-001 | use-system-follows-default | decision function on `useSystem` with system-default `true` | `true` |
| recents-002 | use-system-follows-default | decision function on `useSystem` with system-default `false` | `false` |
| recents-003 | always-reopens | decision function on `always` with system-default `false`, then `true` | `true`, then `true` |
| recents-004 | never-reopens | decision function on `never` with system-default `false`, then `true` | `false`, then `false` |
| recents-005 | display-name-use-system, display-name-always, display-name-never | display name of `useSystem`, `always`, `never` | `"Use System Setting"`, `"Always"`, `"Never"` |
| recents-006 | policy-case-iterable, policy-cases | the complete list of policy states | 3 elements, in order: `useSystem`, `always`, `never` |
| recents-007 | policy-raw-values | raw value of each state; parsing `"always"`; parsing `"sometimes"` | `"useSystem"`, `"always"`, `"never"`; `always`; no match |
| recents-008 | policy-round-trips-as-string | encode `never`, then decode the result | Encoded value is the string `"never"`; decodes back to `never` |
| recents-009 | policy-equatable | `always == always`; `always == never` | `true`; `false` |
| recents-010 | reopen-decision-pure | set the platform's keep-windows-on-quit preference to `true`, then call the decision function on `never` with system-default `false` | `false`; the preference has no effect on the result |
| recents-011 | system-default-key | platform preference domain with keep-windows-on-quit set to `true` | system-default reads `true` |
| recents-012 | system-default-absent | keep-windows-on-quit preference removed from every searched domain | system-default reads `false` |
| recents-013 | system-default-uncached | read system-default with the preference `false`, set the preference `true`, read again | First read `false`, second read `true` |
| recents-014 | system-default-inverted-label | the platform's own "close windows when quitting" control checked (which stores the preference as `false`) | system-default reads `false`; `useSystem`'s decision with that value is `false` |
| recents-015 | system-default-read-only | snapshot the platform preferences, read system-default and every display name | Preferences unchanged |
| recents-016 | recent-count-key, recent-count-default | empty preference store; read recent-window-count | `10`; its key is `"recentWindowsCount"` |
| recents-017 | recent-count-storage-form | set recent-window-count to `7` with the default store | Stored as a native integer `7` under key `"recentWindowsCount"` |
| recents-018 | policy-setting-key, policy-setting-default | empty preference store; read reopen-on-launch preference | `useSystem`; its key is `"reopenOnLaunchPolicy"` |
| recents-019 | policy-setting-storage-form | set reopen-on-launch preference to `always` with the default store | Stored as JSON-encoded data holding the string `"always"`; reading the preference returns `always` |
| recents-020 | policy-setting-decode-fallback | store data for the JSON string `"sometimes"` under `"reopenOnLaunchPolicy"` | Reading the preference returns `useSystem`; nothing is thrown or logged |
| recents-021 | settings-not-secure | inspect the secure flag on both preferences | `false` (non-secure) for both |
| recents-022 | settings-change-notifying | subscribe to change notifications on the reopen-on-launch preference, then set it to `never` | Subscriber receives `never` |
| recents-023 | recent-count-mirror | set recent-window-count to `7`, apply it; then `3`, apply again | The platform's recent-documents limit is `7`, then `3` |
| recents-024 | recent-count-mirror-live | construct the window manager, set recent-window-count to `12`, check on the next main-run-loop turn | The platform's recent-documents limit is `12` with no explicit apply call |
| recents-025 | policy-consumed-for-documents-only | reopen-on-launch preference set to `never`; restore open projects with a project whose window was open last session and whose folder exists | The project window reopens; the policy is not consulted |
| recents-026 | settings-single-threaded-access | read recent-window-count from outside the designated execution context with no explicit hand-off | Rejected at compile time by the platform's concurrency checks |
| recents-027 | no-errors, no-network-no-files | invoke every public operation of the policy and the preferences | None throws; no file, network, or process activity beyond the preference-store reads and writes |

