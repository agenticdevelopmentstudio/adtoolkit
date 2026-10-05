
The Panel Host View:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Help presenter | help-presenter reference, optional | absent | Where this view's help button opens and closes help, and reports visibility changes back. Absent hides the help button entirely. |
| Show help button | boolean | true | Whether this view draws its own help button. Set false for a window whose toolbar supplies help instead. |
| External visibility-change callback | optional callback | absent | Fired after help is disclosed or dismissed, for chrome outside this view (e.g. a toolbar button) that needs to mirror the same state. |

Its other public operations are: set the hosted content (accepting a
present view or none), set the help content (accepting present content or
none), toggle help, and query whether help is currently visible.

