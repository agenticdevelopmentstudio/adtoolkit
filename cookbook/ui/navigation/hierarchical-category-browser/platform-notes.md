
- **React / Web (TypeScript):** `packages/web/packages/features/categories/src/useCategoryLevels.tsx`, exported from `@agentic-toolkit/categories`. `"use client"`.
- Built on `buildCategoryTree`/`resolveCategoryChain`/`categoryKey`/`chainAfterRename`/`chainAfterMove`/`chainAfterDelete` (which returns `null` for an unfiling that leaves the category filed elsewhere) (`packages/web/packages/ui/src/blocks/category-tree.ts`) and `CategoryGearMenu`/`CategoryPickerDialog`/`CategoryRenameDialog`/`CategoryDeleteDialog` (`packages/web/packages/ui/src/blocks/*`), all re-exported from `@agenticdevelopertoolkit/ui/blocks`.
- The three route-following functions, `chainAfterRename`, `chainAfterMove` and
  `chainAfterDelete`, sit in
  `packages/web/packages/ui/src/blocks/category-tree.ts`
  beside the forest and slug functions whose contracts they follow — pure functions over a
  forest and a slug chain, with no notion of a notebook, a list query, or a network.
  `packages/web/packages/features/categories/src/category-scope.ts` re-exports them, so the
  import site every consumer already names still works, and anything that links only
  `@agenticdevelopertoolkit/ui` (the showcase demo among them) calls the SAME function the hub does
  rather than mirroring it.
- `CategoryScope` and the `-all`/`-none` synthetic-row slugs live in
  `packages/web/packages/features/categories/src/category-scope.ts`, imported by both hosts —
  there is exactly one copy (`note-model.ts`'s former local copy was deleted when notebook
  adopted the shared hook).
- Consumers: `packages/web/packages/features/notebook/src/NotebookPane.tsx` (rail + note list, `itemNoun="notes"`) and `packages/web/packages/features/research/src/ResearchPane.tsx` (rail + document list, `itemNoun="documents"`), each supplying its own `rows` fetch, `idPrefix`, and `workspaceSlug`.
- Demo: `local/ui-showcase/app/page.tsx` (Topic id `hierarchical-category-browser`) + the showcase source registry. The demo assembles the same `packages/web/packages/ui/src/blocks` primitives this hook composes — `buildCategoryTree`, `chainAfterRename`, `chainAfterMove`, `CategoryGearMenu`, `CategoryPickerDialog`, `CategoryRenameDialog`, `CategoryDeleteDialog` — against an in-memory `CategoryTreeNode[]` fixture, since `useCategoryLevels` itself reaches a real `taxonomyApi`/`markdownApi` the showcase has no backend for.
- Responsive: verify via the ui-showcase demo at 375 / 768 / 1440 — the rail levels inherit
  [Hierarchical Topic Detail](agenticdevelopertoolkit://recipes/hierarchical-topic-detail)'s
  own disclosure/narrow-mode behavior; this recipe adds no layout of its own to verify beyond
  the gear menu and its dialogs at each width.
- **SwiftUI**: Not applicable — web-only (platforms: typescript, web).
- **Compose**: Not applicable — web-only (platforms: typescript, web).
- **AppKit / UIKit**: Not applicable — web-only (platforms: typescript, web).
- **WinUI 3**: A `NavigationView` or a row of `ListView` columns, one per walked depth, hosts the levels; the synthetic All and Uncategorized rows lead the root `ListView`, each level header carries a `DropDownButton` with a `MenuFlyout` for the gear actions, and the picker, rename and delete dialogs are `ContentDialog`s over a `TreeView`. The source implementation is web-only; this is translation guidance, not shipped code.

