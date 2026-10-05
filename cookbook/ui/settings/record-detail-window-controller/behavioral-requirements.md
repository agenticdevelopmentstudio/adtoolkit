
- **sidebar-follows-records**: Setting the records MUST show one sidebar row per
  record, in the owner's order, with the record's pane as its detail.
- **owner-order-not-alphabetical**: The sidebar MUST NOT sort rows by title,
  because records are renameable and a sorted list moves a row from under the
  cursor mid-edit.
- **pane-built-once-per-record**: The window MUST build a record's pane once,
  the first time the record is seen, and reuse that pane for every later update
  of the same record, identified by the record's own id.
- **pane-updated-every-push**: On every set of records the window MUST hand each
  pane its record's current values, then run the configure callback for it.
- **dropped-records-drop-panes**: A pane whose record is no longer in the list
  MUST be discarded.
- **selection-survives-reload**: Replacing the records MUST keep the selected
  record selected when it survives.
- **deleted-selection-takes-neighbour**: When the selected record is removed
  from the list, the window MUST select the record now at its position, or the
  last row when it was the last.
- **first-selection-is-never-blank**: When rows exist and nothing was selected,
  the window MUST select the first row so the detail pane is never blank.
- **empty-list-selects-nothing**: With no records and no fixed panels, the
  selected record MUST be absent and the empty message MUST be shown beside the
  add and remove controls when one is set.
- **empty-message-hidden-with-records**: The empty message MUST be hidden
  whenever at least one record exists.
- **add-reports-out**: Activating the add control MUST call the add callback;
  the window MUST NOT create a record itself.
- **remove-reports-selected-record**: Activating the remove control MUST call
  the remove callback with the selected record, and only when removal is allowed.
- **remove-disabled-when-nothing-selected**: The remove control MUST be disabled
  when no record is selected.
- **remove-vetoable**: When a can-remove check is set and answers false for the
  selected record, the remove control MUST be disabled and a remove MUST be
  refused even if the control is bypassed.
- **veto-change-updates-at-once**: Setting the can-remove check MUST update the
  remove control immediately.
- **remove-rechecked-every-reload**: The remove control state MUST be recomputed
  on every reload and selection change, not only when selection moves.
- **selection-reported-once**: The select callback MUST be called only when the
  selected record actually changes, so a window that reloads on a timer does not
  re-announce its selection.
- **select-by-id-ignores-unknown**: Selecting a record by an id not in the list
  MUST be ignored.
- **select-syncs-immediately**: Selecting a record MUST update the selected
  record and the remove control at once, even before the window has been shown.
- **fixed-rows-after-records**: Fixed rows MUST be listed after every record,
  MUST NOT be passed to the record callbacks, and MUST NOT be removable; while one
  is selected the selected record MUST be absent.
- **refresh-keeps-navigation-and-search**: A reload MUST keep the navigation
  trail and the sidebar search text.
- **destructive-confirm-and-failure-report-replaceable**: The window MUST offer
  a replaceable destructive confirmation and a replaceable failure report, both
  presented as sheets on the window by default.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

