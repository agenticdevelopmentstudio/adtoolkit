
- **Null/empty input**: An empty root (no `rootNode`, or `rootNode.children`
  empty) renders the placeholder row rather than zero rows (see
  `empty-root-placeholder-text`); the placeholder is never selectable and
  never opens anything. The disclosure-restore operation doing nothing
  further once there is no pending restored selection, and a document event
  with an unparseable URI being silently ignored, are covered as named
  requirements above (see **restore-disclosure-noop-without-pending** and
  **document-event-ignores-unparseable-uri**).
- **Boundary values**: The one-shot auto-expand
  (`lone-root-auto-expands-once`) only applies when there is exactly one root
  manager and `restoration.expandedPaths` is empty; a browser with two or
  more roots always starts fully collapsed unless the restoration model says
  otherwise. Restoring a selection many directory levels deep has no explicit
  maximum-depth cap; it is bounded only by how many reload cycles the real
  directory depth requires (`restore-descends-incrementally`).
- **Concurrent access**: This component, the root manager, the selection
  model, the restoration model, and the document store are all confined to
  the UI thread, and every subscription this component installs additionally
  re-dispatches onto the UI thread before running (see Platform Notes for the
  exact mechanism used on Apple platforms). The lazy children-load operation
  performs its filesystem read off the UI thread but publishes the result
  back onto the UI thread, so this component never observes a children
  update off the UI thread. Multiple browser panes can share one selection
  model and restoration model; a selection or disclosure change made by one
  pane's outline is observed and mirrored by every other pane's own
  loop-prevention guard, so cross-pane updates highlight/disclose without
  looping back into a second write (see Platform Notes for the exact
  guard-flag names used on Apple platforms).
- **Error states**: A directory whose contents cannot be read (for example,
  permission denied) is rendered identically to a genuinely empty directory —
  the "Empty" placeholder — because the tree model's one-level directory read
  operation swallows a directory-read failure into an empty array before it
  ever reaches this component; this component surfaces no distinct error
  state or affordance for that case. A context-menu action for a path that no
  longer exists on disk produces no menu items rather than an error dialog
  (see `context-menu-omitted-for-missing-path`). If the row selected before a
  reload can no longer be found by identity or by path, the component treats
  that as "the user's file is gone" and clears the selection
  (`reload-clears-selection-when-row-gone`) rather than treating it as an
  error condition.
- **Offline/disconnected state**: Not applicable. This component reads and
  watches the local filesystem only; it makes no network requests, so there
  is no connectivity-loss behavior to define here.

