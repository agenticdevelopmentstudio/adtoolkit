
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| NavigationPopover | `@agentic-toolkit/adh/header` | Popover surface, search box, keyboard navigation, row rendering, flyout submenus | yes | Consumes `PopoverEntry[]` with icon + inline-subitem support |
| SiteWordmark | adtoolkit://cookbook/adh/sites/site-wordmark | The header trigger that opens the menu | yes | Unchanged |
| menu-icons map | `@agentic-toolkit/adh/header` `menu-icons.ts` (ADH vocabulary — it is keyed by `SiteId`) | Single source of truth for every row's icon — keyed by SiteId, in-hub route path, or chrome key | yes | `MENU_ICONS` record + `menuIcon(key)` resolver |
| lucide-react icons | (library) | The icon glyphs | yes | Only icons already used elsewhere on the platform are reused where one exists |
| `useWorkspaces` | `@/api/workspaces` (hub) | Supplies the Workspaces flyout entries | yes (logged-in) | react-query; `{ slug, name, type }[]` |
| Recents store | `@agentic-toolkit/adh/header/recents` — import that subpath, never `./recents`; it holds module-level state and a second inlined copy would silently fork the history | Persists + reads the last 10 visited places | yes (logged-in) | localStorage, `ftd-storage` pattern |

