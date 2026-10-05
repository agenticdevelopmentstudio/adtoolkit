
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| Raw category rows | the host's list fetch (`notesApi.categories`/research's equivalent) | `useCategoryLevels` | host → hook | `rows: CategoryTreeNode[] \| null` option |
| Resolved chain | `resolveCategoryChain(tree, chainSlugs)` inside the hook | the host's navigation, breadcrumbs, and the item-list scope | hook → host | `chain: CategoryNode[]` result field |
| List scope | the resolved chain, via `scopeFor` | the host's item-list fetch | hook → host | `scope: CategoryScope` result field (`all` / `uncategorized` / `named`) — an EXACT-match name, not a descendant-inclusive filter |
| Rail levels | the walk over `tree` + `chain` | the enclosing `HierarchicalDetailView`/`HierarchicalTopicDetail` | hook → HTDV | `levels: TopicLevel[]` result field, appended before the host's own (e.g. note/document) levels |
| Gear target | the level closure at render time (`selectedNode`, `levelParent`) | the four dialogs | hook (internal) | `pending: { action, target }` state, captured fresh each render so a stale target can never survive a rename (HTDV's `levelsKey` ignores `ReactNode` props) |
| Write result | `taxonomyApi`/`markdownApi` (`@agentic-toolkit/data/markdown`) | the host's list refetch | hook → host | `onChanged: () => void \| Promise<void>` option, called after every successful write |

