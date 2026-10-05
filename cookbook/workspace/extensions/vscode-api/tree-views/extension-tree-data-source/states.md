
Not applicable — this is the pull-based seam a contributed tree pane calls into a registered `TreeDataProvider`, not a visual component. Its one lifecycle-shaped behavior — a conforming instance being superseded via `onProviderReplaced` and then invalidated — is captured under Behavioral Requirements (**provider-replacement-ordering**, **replacement-instance-arrives-unwired**), not as a visual-state table.

