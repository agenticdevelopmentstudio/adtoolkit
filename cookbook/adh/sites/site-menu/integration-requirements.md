
- **shared-core-both-menus**: The marketing and workspace menus MUST render the
  identical core section structure (the Hub section and everything below it),
  differing ONLY in the auth-conditional top section.
- **row-icon-label-description**: Every row MUST render, in order, an icon, a label,
  and (when present) a description.
- **icon-single-source**: A row's icon MUST resolve from a single source of truth —
  the `menu-icons` map (`MENU_ICONS` / `menuIcon(key)`), keyed by SiteId for site
  rows, route path for in-hub route rows, and a chrome key for the non-site rows
  (Home, Recents, Workspaces, Login, Sign up) — and MUST NOT be hard-coded at a
  render site.
- **icon-reuse-existing**: Where the platform already associates an icon with a
  thing (e.g. Community→`Users`, Persona Registry→`UserCircle`, Dev Team→
  `UsersRound`, Narratives→`ScrollText`, Ecosystems→`Network`, Research→
  `FlaskConical`), that icon MUST be reused rather than a new one invented.
- **inline-subitem-kind**: The menu MUST support an inline sub-item row — a leaf row
  rendered indented under a parent row and ALWAYS visible (not a flyout).
- **hub-parent-links-and-parents**: The "Hub" row MUST be a clickable link to the
  hub apex AND the parent of its inline sub-items.
- **hub-subitems-inventory**: Hub's inline sub-items MUST be, in order, BitBag,
  Community, Persona Registry, Toolkit, Cookbook, Dev Team, MyAgenticTeams,
  Narratives, Help; plus News, Ecosystems, Personas, Organizations, Research.
- **reference-group-removed**: The former "Reference" topic group (docs/api/mcp)
  MUST NOT appear in either menu.
- **in-hub-rows-authed-only**: The in-hub destination rows (News, Ecosystems,
  Personas, Organizations, Research) MUST be hidden when the user is not
  authenticated.
- **top-section-logged-out**: When unauthenticated, the top section MUST show
  exactly two rows — Login and Sign up — above the Hub section.
- **top-section-logged-in**: When authenticated, the top section MUST show Home
  (with an inline sub-item Workspaces) and Recents, above the Hub section.
- **workspaces-flyout**: Selecting/hovering Workspaces MUST open a flyout submenu of
  the user's workspaces from `useWorkspaces`, each labelled per
  `workspaceListLabel` and navigating to that workspace's home.
- **recents-flyout**: Recents MUST open a flyout submenu of the recorded places,
  most-recent first, capped at 10.
- **recents-settle-only**: A place MUST be recorded only after the current selection
  **settles** (no further drill-down within the debounce window), so intermediate
  drill-through steps between a list and its leaf are NOT recorded.
- **recents-deep-link**: Each recent MUST link to the deep URL of the recorded view;
  a view that is not yet URL-addressable MUST record its best available URL (the
  feature route) and MUST NOT block recording.
- **recents-dedupe-cap**: Recording a place already present MUST move it to the
  front (not duplicate it); the list MUST be capped at 10, evicting the oldest.
- **recents-persist-local**: Recents MUST persist per-device in localStorage using
  the `ftd-storage` conventions — SSR-guarded (`typeof window`), try/catch
  swallowing, an `adh:` key prefix.
- **recents-empty-hidden**: When there are no recorded places, the Recents entry
  MUST be hidden (nothing to disclose).
- **current-marked**: The row matching the current location (a site, a workspace, a
  recent) MUST be marked `current`, matching existing `NavigationPopover` behavior.
- **keyboard-accessible**: The enhanced menu MUST retain `NavigationPopover`'s full
  keyboard model (open on trigger activation, arrow navigation, flyout entry/exit,
  Escape to close, focus return).

