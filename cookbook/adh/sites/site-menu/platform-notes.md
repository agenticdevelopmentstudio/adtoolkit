
- Files: menu config `packages/web/packages/adh/src/header/MarketingSiteMenu.tsx` +
  `WorkspaceSiteMenu.tsx` (both compose the shared `hubCoreGroups.ts`); types +
  rendering `SiteMenu.tsx` (auth top section + compose) + `NavigationPopover.tsx`
  (icon slot + inline sub-item indent); icon SSoT
  `packages/web/packages/adh/src/header/menu-icons.ts`; Recents store + hook
  `packages/web/packages/adh/src/header/recents.ts`; Workspaces context
  `packages/web/packages/adh/src/header/workspaces-menu.tsx` (hub filler +
  `hub-workspaces-menu-provider.tsx`); recorder
  `websites/main/hub/src/components/workspace/recents-recorder.tsx` (in the adh repo).
- The recorder observes `WorkspaceChromeProvider.mergedLevels`
  (`frontend/src/sites/hub/src/components/workspace/workspace-chrome.tsx`) — the one
  place holding the full current selection path (with labels) for both nav models.
- Demo: `frontend/src/local/ui-showcase/app/page.tsx` — a `site-menu` topic rendering
  both auth states with seeded workspaces + recents.
- Responsive: verify via Playwright at 375 / 768 / 1440; keyboard + pointer.
- Tailwind sources: no new package boundary; icons are lucide (already a dependency
  of `@agentic-toolkit/adh` and externalized by it, so the host supplies the one copy).
- **WinUI 3**: Build the menu from a `Flyout`/`MenuFlyout` anchored to the wordmark button, with a `NavigationViewItem`-style row template of icon (`FontIcon`/`SymbolIcon` from a single `MenuIcons` dictionary keyed by site id, route, or chrome key), label and description `TextBlock`s. Inline sub-items map to a nested `ItemsRepeater` with a left margin; the Workspaces and Recents flyouts map to `MenuFlyoutSubItem`. Port Recents as a class holding a capped `List<Place>` persisted through `ApplicationData.Current.LocalSettings`, with a `DispatcherTimer` as the settle debounce; keyboard navigation comes from `MenuFlyout`'s built-in arrow, Escape and focus-return behavior.

