
The property and command names below — `uniqueID`, `name`, `helpVisible`,
`drawerTab`, `searchQuery`, `selectedTab`, `tabEdges`, `branch`,
`paneProject`, `paneTab`, `paneSelection`, `paneMinimized`, `closePane`,
`zoomPane`, `minimizePane(to:)` — and the specifier keys `projectWindows`,
`projectTabs`, `panes` are the AppleScript dictionary
vocabulary this surface implements; they are this concept's external
interface and are used throughout as such.

- **window-enumeration-order**: the window enumeration MUST map every open
  window, in the order those windows were opened (not any incidental
  storage order), to one scriptable-project-window wrapper.
- **window-enumeration-recomputed**: the window enumeration MUST be
  recomputed fresh on every access, with no backing cache, so a window
  opened or closed between two reads MUST be reflected in the very next
  read.
- **window-lookup-short-circuits**: the window lookup MUST search the open
  windows in order and stop at the first wrapper whose `uniqueID` equals
  the argument, so a match at position *n* MUST NOT cause a wrapper to be
  constructed for any window after it.
- **window-lookup-miss-returns-nil**: the window lookup MUST return no
  result when no open window's `uniqueID` equals the argument, including
  when the argument is not a well-formed identifier string — the search is
  a plain string comparison, not an identifier parse, so it MUST NOT throw
  or crash on a malformed argument.
- **tab-enumeration-nests-by-window**: the tab enumeration MUST flatten
  every window's tabs into one list, windows in open order and, within one
  window, in that window's own tab-group order.
- **tab-branch-resolver-wiring**: the tab enumeration for one window MUST
  look up that window's project controller once, and MUST resolve each
  tab's `branch` by evaluating, for that tab's working directory, the
  project controller's branch controller's current branch for that
  directory.
- **tab-branch-nil-for-adopted-windows**: because a window that was adopted
  for scripting rather than opened by this surface has no project
  controller, every tab belonging to an adopted-only window MUST resolve
  its `branch` to no result, which is then reported as the empty string
  (see **tab-branch-empty-when-unresolved**).
- **tab-lookup-short-circuits**: the tab lookup MUST walk every window's
  tabs in enumeration order and stop at the first tab whose `uniqueID`
  equals the argument, so tabs in windows after the match MUST NOT be
  built.
- **tab-lookup-miss-returns-nil**: the tab lookup MUST return no result
  when no open tab's `uniqueID` equals the argument.
- **pane-enumeration-tags-source-window**: the pane enumeration MUST
  flatten every window's panes into one list, and for each window MUST tag
  every pane's wrapper with the exact window it was enumerated from,
  rather than leaving the wrapper to discover its own window.
- **pane-lookup-short-circuits**: the pane lookup MUST walk every window's
  panes in enumeration order and stop at the first pane whose `uniqueID`
  equals the argument.
- **pane-lookup-miss-returns-nil**: the pane lookup MUST return no result
  when no open pane's `uniqueID` equals the argument.
- **main-thread-confinement**: every operation in this surface, and every
  member of the three wrapper types, MUST run on the UI's main execution
  context; the four types MUST NOT be called from any other execution
  context.
- **window-id-is-project-id**: the scriptable window's `uniqueID` MUST
  return its underlying window's project id, falling back to the empty
  string when the underlying window no longer exists — the persisted
  `git_repo.id`, so one window's id is always its project's id.
- **window-degrades-when-controller-is-gone**: because the wrapper holds
  its underlying window only weakly, every scriptable-window property
  (`uniqueID`, `name`, `helpVisible`, `drawerTab`, `searchQuery`,
  `selectedTab`) MUST fall back to the empty string (or to `false` for
  `helpVisible`) rather than crash once the underlying window has been
  deallocated.
- **window-help-visible-round-trips**: the scriptable window's
  `helpVisible` MUST read and write the underlying window's
  help-visibility state directly, defaulting to `false` when the
  underlying window no longer exists.
- **window-drawer-tab-read-only**: the scriptable window's `drawerTab` MUST
  expose the underlying window's help-drawer tab identifier as read-only,
  defaulting to the empty string, and MUST NOT accept a new value — Help
  is documented as the only legal tab, so accepting a value would have
  exactly one legal value it could accept.
- **window-search-query-round-trips**: the scriptable window's
  `searchQuery` MUST read and write the underlying window's search query
  directly, so setting it MUST route through whatever the underlying
  window's own search-query update does (routing the search), not merely
  record a string.
- **window-selected-tab-round-trips**: the scriptable window's
  `selectedTab` MUST read and write the underlying window's selected-tab
  identifier, defaulting to the empty string when the underlying window no
  longer exists.
- **window-object-specifier-key**: the scriptable window's object
  specifier MUST be built under the `projectWindows` collection key,
  addressed by its `uniqueID` (see `adtoolkit://cookbook/system/scripting`
  for that mechanism's own contract).
- **tab-value-rebuilt-per-read**: the scriptable tab MUST be constructed
  fresh on every enumeration or lookup call, with all six fields (`id`,
  `title`, `edges`, `project`, `workingDirectory`, `branch`) fixed at
  construction and never mutated afterward — it is a value snapshot, not a
  cache that a later tab rename would have to invalidate.
- **tab-id-is-the-group-id**: the scriptable tab's `uniqueID` MUST be the
  tab group's id (the persisted `project_tabs.group_id`), never a per-edge
  member row's id, because one project-level tab drawn on several edges is
  one tab to a script, not one per edge.
- **tab-edges-may-be-empty**: the scriptable tab's `tabEdges` MUST report
  the current set of edges that tab group is drawn on, and an empty list
  MUST be a valid result when every edge the group could draw on has been
  disabled.
- **tab-branch-empty-when-unresolved**: the tab-branch resolution MUST fold
  a missing branch result to the empty string on the scriptable tab it
  builds, so a directory that resolves to no project controller, no branch
  controller for that directory, or a branch controller whose checkout is
  on a detached HEAD (no current branch, see
  `adtoolkit://cookbook/workspace/projects/branch-controller`) all
  collapse to the same observable value: an empty string, never a null
  stringified and never a thrown error.
- **tab-object-specifier-key**: the scriptable tab's object specifier MUST
  be built under the `projectTabs` collection key, addressed by its
  `uniqueID`.
- **pane-requires-its-enumerating-window**: constructing a scriptable pane
  MUST take the window it was found in as a required parameter — a pane
  behind a background tab has never been part of a rendered view
  hierarchy, so a wrapper left to discover its own window through the view
  would report an empty project and tab for most panes in a real window.
- **pane-view-controller-held-strongly-window-held-weakly**: the scriptable
  pane MUST hold its wrapped pane strongly and its enumerating window
  weakly — the opposite asymmetry from the scriptable window, which holds
  its underlying window weakly.
- **pane-project-and-tab-derived-live**: the scriptable pane's
  `paneProject` MUST return its tagged window's project display name,
  falling back to the empty string, and `paneTab` MUST return the title of
  the tab group containing that pane, falling back to the empty string,
  both computed fresh from the tagged window on every access rather than
  captured once at enumeration time.
- **pane-selection-empty-when-nothing-selected**: the scriptable pane's
  `paneSelection` MUST return the pane's selection description, treating
  "nothing selected" as the empty string rather than a missing value.
- **pane-minimized-is-edge-name-or-no**: the scriptable pane's
  `paneMinimized` MUST return the name of the edge it is minimized to, or
  "no" — one string, not a flag plus an edge, because "minimized" and
  "minimized where" are one fact that two separate properties could
  disagree about.
- **pane-unrecognized-edge-restores-rather-than-guesses**: the scriptable
  pane's `minimizePane(to:)` MUST parse the edge name it is given; when
  that parse fails, it MUST request the pane be restored rather than guess
  an edge, and when it succeeds it MUST request the pane be minimized to
  that edge.
- **pane-actions-delegate-to-host-and-may-be-declined**: `closePane()`,
  `zoomPane()` and `minimizePane(to:)` MUST each forward the request to
  the pane's host and MUST NOT implement any part of that effect
  themselves — a script closing or minimizing a pane goes through exactly
  the path the close button or the title-bar arrow takes, and that host
  MAY decline the request.
- **pane-is-in-window-reasks-live-membership**: the scriptable pane's
  `isInWindow` MUST return `false` when the tagged window no longer
  exists, and otherwise MUST return whether that one window's current pane
  list still contains this pane by identity — asking that one window's
  current pane list, not re-running the pane lookup across every open
  project, because a pane cannot have moved to a different window between
  a request and this question.
- **pane-object-specifier-key**: the scriptable pane's object specifier
  MUST be built under the `panes` collection key, addressed by its
  `uniqueID`.

