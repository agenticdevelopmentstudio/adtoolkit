
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| selected entity id | Route (URL) | Topic list + detail panel | Down | URL param `{basePath}/{id}/{topic}` |
| last-selected id | localStorage `{{app_prefix}}:ftd:{basePath}:lastId` | Bare-path resolver | Both | Written on focus; cleared on delete of that id |
| view mode (`cards`/`list`) | localStorage `{{app_prefix}}:ftd:{basePath}:viewMode` | All view toggle | Both | Read on init (default `cards`); written on change |
| filter query | All view local state | Client-side entity filter | Down | Component state |
| entity list | Module-level cache (stale-while-revalidate) | Topic list, All view | Down | SWR-style cache |
| Danger Zone disclosure open | Entity pane local state | Disclosure styling + delete control | Down | Component state |

