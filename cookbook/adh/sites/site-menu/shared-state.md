
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| Auth (authenticated?) | `AdhHeader` `user` → `SiteSwitcher` `authenticated` | Which top section + whether in-hub rows show | one-way | prop |
| Active route / selection | `usePathname` + workspace chrome `mergedLevels` | `current` marking; Recents recorder input | read | context + hook |
| Workspaces | `useWorkspaces()` (hub) | Workspaces flyout entries | read | react-query |
| Recents list | Recents store (localStorage) | Recents flyout entries | read/write | module store; recorder writes, menu reads |
| Recorded place | Recents recorder (settle-debounced observer of `mergedLevels`) | Recents store | write | effect + timer |

